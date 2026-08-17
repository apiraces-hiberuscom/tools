# 02-enumeration

Enumeración detallada de servicios, puertos, recursos, usuarios y datos accesibles en los hosts descubiertos.

## Qué va aquí
- Escaneo/análisis de puertos y servicios
- Enumeración de shares (SMB), LDAP, correo, bases de datos, servicios web
- Enumeración de usuarios y recursos del sistema (como `netview`, que mapea puertos en listening a proceso/servicio)

## Subcarpetas por plataforma
- `windows/` → scripts PowerShell/cmd
- `linux/` → scripts bash/python
- `web/` → enumeración de aplicaciones web (robots.txt, directorios, CMS...)

## Indexación
Cada script debe empezar con la cabecera de metadatos (`# Nombre`, `# Descripción`, `# Tags`, `# Uso`) para que aparezca correctamente en el índice raíz. Tras añadir uno, ejecuta `..\scripts\update-index.ps1`.