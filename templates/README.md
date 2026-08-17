# templates

Plantillas de cabecera para que cualquier script nuevo entre en el índice automáticamente.

- `ps1-tool.ps1` → plantilla PowerShell
- `sh-tool.sh` → plantilla Bash

## Formato de cabecera (obligatorio)
```powershell
# Nombre: <identificador corto>
# Descripción: <qué hace, una línea>
# Tags: <comas, separados por espacio o coma>
# Uso: <comando de ejemplo>
```

Copia la plantilla a su carpeta de fase y rellena los campos. Luego ejecuta `..\scripts\update-index.ps1` desde la raíz para regenerar el índice.