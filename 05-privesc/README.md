# 05-privesc

Elevación de privilegios de usuario limitado a root/administrator.

## Qué buscar
- SUID/SGID en binarios manipulables
- Sudo sin contraseña o con comandos peligrosos
- Servicios con rutas no entrecomilladas (Windows)
- Cron jobs ejecutables por el usuario actual
- Binarios en PATH escribible
- Kernel vulnerable

## Herramientas

| Script | Plataforma | Qué hace |
|--------|------------|----------|
| [privesc-check-linux](linux/privesc-check.sh) | Linux | Enumeración de vectores: SUID, sudo, capabilities, cron, PATH |
| [privesc-check-windows](windows/privesc-check.ps1) | Windows | Tokens, parches, servicios no entrecomillados, autoruns |

## Comandos rápidos

```bash
# Linux
sudo -l  # qué puedo hacer como root
find / -perm -4000 -type f 2>/dev/null  # SUID
cat /etc/crontab  # cron
getcap -r / 2>/dev/null  # capabilities
ls -la /etc/passwd  #世界 writable?

# Windows
whoami /all  # tokens y privilegios
systeminfo | findstr /i "Hotfix"  # parches
sc qc <servicio>  # servicio sospechoso
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

## Tips
- LinPEAS / WinPEAS para enumeración automática completa
- Buscar `GTFOBins` para explotar SUID/sudo/capabilities
- `linux-exploit-suggester.sh` para vulnerabilidades de kernel
- Servicios Windows con ruta no entrecomillada =escalada fácil
