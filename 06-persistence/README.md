# 06-persistence

Métodos para mantener acceso a los objetivos tras reinicios o desconexiones: persistencia y comunicaciones C2.

## Qué buscar
- Métodos que sobrevivan reinicios (cron, systemd, servicios, RunKey)
- Formas de ejecución al login del usuario
- Servicios con nombres legítimos para evitar detección
- Comunicaciones C2 (listeners, reverse shells)

## Herramientas

| Script | Plataforma | Qué hace |
|--------|------------|----------|
| [cheatsheet-persistence](cheatsheet-persistence.md) | Linux/Windows | Todas las técnicas: cron, systemd, RunKey, WMI, servicios |

## Comandos rápidos

```bash
# Linux - Cron
crontab -e  # agregar reverse shell cada 5 min

# Linux - Systemd
systemctl enable backdoor.service

# Windows - RunKey
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /d "C:\backdoor.exe"

# Windows - Tarea programada
schtasks /create /tn "Update" /tr "C:\backdoor.exe" /sc minute /mo 5
```

## Tips
- Usar nombres legítimos (WindowsUpdate, SecurityHealth)
- Probar persistencia inmediatamente después de configurarla
- Evitar métodos ruidosos en entornos de producción
- Priorizar sobrevivir reinicios sobre stealth
