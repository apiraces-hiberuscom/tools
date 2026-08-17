# Pentesting Tools

Repositorio personal de herramientas y utilidades para **pentesting ético**. Todo está organizado por fase de ataque y plataforma, con un índice **auto-generado** para encontrar cualquier script en segundos.

![Estado](https://img.shields.io/badge/estado-activo-brightgreen)
![Plataformas](https://img.shields.io/badge/plataformas-Windows%20%7C%20Linux%20%7C%20Web-blue)
![Lenguajes](https://img.shields.io/badge/scripts-PowerShell%20%7C%20Bash%20%7C%20Python-orange)
![Uso](https://img.shields.io/badge/uso-s%C3%B3lo%20ambientes%20autorizados-yellow)

> **Aviso**: Todas las herramientas aquí contenidas son solo para uso educativo y en sistemas que tengas autorización expresa para auditar. El uso indebido es responsabilidad del usuario.

---

## Estructura

```
tools/
├── 00-assets/              # Wordlists, diccionarios, cheatsheets
├── 01-recon/               # Footprinting, OSINT, descubrimiento
├── 02-enumeration/         # Enumeración de servicios y recursos
│   └── windows/            #   Scripts PowerShell/cmd
├── 03-exploitation/        # Payloads, reverse shells, exploits
├── 04-post-exploitation/   # Movimiento lateral, pivoting, exfiltración
├── 05-privesc/             # Elevación de privilegios
├── 06-persistence/         # Persistencia y C2
├── 07-password-attacks/    # Fuerza bruta y cracking de hashes
├── 08-web/                 # Explotación de aplicaciones web
├── 09-wireless/            # Auditoría de redes WiFi
├── 10-misc/                # Sin clasificar
├── scripts/                # Utilidades del propio repo (no se indexan)
└── templates/              # Plantillas de cabecera para nuevos scripts
```

Leer el `README.md` de cada fase te dice exactamente qué va dentro de cada carpeta.

---

## Índice de herramientas

La siguiente tabla se regenera automáticamente. Nunca la edites a mano:

<!-- INICIO-INDICE -->
| Herramienta | Descripción |
| --- | --- |
| [netview](02-enumeration/windows/netview.ps1) | Muestra los puertos TCP en estado LISTENING con su PID, proceso y servicio asociado. |
<!-- FIN-INDICE -->

---

## Cómo añadir una herramienta

1. **Copia la plantilla** correspondiente desde `templates/` a la carpeta de fase adecuada (y subcarpeta de plataforma si existe).
2. **Rellena la cabecera de metadatos** (es lo que usa el índice):
   ```powershell
   # Nombre: netview
   # Descripción: Muestra los puertos TCP en LISTENING con su proceso y servicio.
   # Tags: windows, network, netstat
   # Uso: powershell -ExecutionPolicy Bypass -File .\netview.ps1
   ```
3. **Regenera el índice**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\update-index.ps1
   ```
4. (Opcional) Si el nombre no es auto-explicativo, pon más contexto como comentario debajo de la cabecera o dentro del propio script.

### ¿Dónde va cada cosa? (regla rápida)
- ¿Descubres algo sobre el objetivo? → `01-recon`
- ¿Analizas qué expone cada servicio? → `02-enumeration`
- ¿Intento lograr acceso/ejecución? → `03-exploitation`
- ¿Ya estoy dentro y quiero más del host/red? → `04-post-exploitation`
- ¿Necesito más privilegios? → `05-privesc`
- ¿Quiero mantener el acceso? → `06-persistence`
- ¿Ataque a credenciales? → `07-password-attacks`
- ¿Web? → `08-web` · ¿WiFi? → `09-wireless`
- ¿No encaja en nada? → `10-misc` (y muévelo cuando madure)

---

## Convenciones

- Nombres de archivo en **minúsculas con guiones** (`netview.ps1`, `port-scanner.sh`).
- Todo script empieza con la cabecera `# Nombre / # Descripción / # Tags / # Uso`.
- Vuelve a ejecutar `scripts/update-index.ps1` **después de añadir, renombrar o borrar** cualquier herramienta.
- No subir wordlists o binarios gigantes a git; enlazar la fuente en `00-assets`.

