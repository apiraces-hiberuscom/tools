# 02-enumeration

Enumeración detallada de servicios, puertos, recursos, usuarios y datos accesibles en los hosts descubiertos.

## Qué buscar
- Versiones exactas de servicios (Apache, OpenSSH, IIS...)
- Usuarios, shares SMB, bases de datos
- Directorios web, tecnologías, CMS
- Configuraciones débiles, banners informativos

## Herramientas

| Script | Plataforma | Qué hace |
|--------|------------|----------|
| [nmap-scan](linux/nmap-scan.sh) | Linux | Escaneo de puertos, versiones, OS, timing |
| [nmap-nse](linux/nmap-nse.sh) | Linux | Scripts NSE por categoría: vuln, discovery, auth |
| [nmap-http-enum](linux/nmap-http-enum.sh) | Linux | Enumeración web: http-enum, hostmap-bfk, waf-detect |
| [banner-grab](linux/banner-grab.sh) | Linux | Captura de banners con netcat y telnet |
| [netview](windows/netview.ps1) | Windows | Puertos TCP LISTENING con PID y proceso |

## Cheatsheets

| Cheatsheet | Contenido |
|------------|-----------|
| [red-linux](linux/cheatsheet-red-linux.md) | Red en Linux: nmap, SMB, sniffing, tunneling, pivoting |
| [red-windows](windows/cheatsheet-red-windows.md) | Red en Windows: netstat, netsh, SMB, firewall, pivoting |

## Comandos rápidos

```bash
# Escaneo completo de un host
nmap -sV -sC -O -p- 10.10.10.5

# Enumeración web
nmap -sV --script http-enum 10.10.10.5
gobuster dir -u http://10.10.10.5 -w /usr/share/wordlists/dirb/common.txt

# SMB
enum4linux -a 10.10.10.5
smbclient -L //10.10.10.5 -N

# Banner grabbing
echo "" | nc -w 3 10.10.10.5 22
curl -sI http://10.10.10.5/
```

## Tips
- Siempre hacer `-sV` para versiones: un Apache 2.4.49 tiene CVE conocido
- `nmap --script vuln` para vulnerabilidades rápidas
- Revisar UDP también: `nmap -sU --top-ports 50`
- SMB signing débil = susceptible a relay
