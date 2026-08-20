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
├── 11-social-engineering/  # Phishing, ingeniería social (SET, gophish...)
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
| [cheatsheet-recon-builtin-linux](00-assets/cheatsheet-recon-builtin-linux.md) | Recon de red en un Linux recién comprometido usando SOLO comandos nativos (sin nmap, nc, tcpdump...): máxima info con lo que ya viene instalado. |
| [cheatsheet-recon-builtin-windows](00-assets/cheatsheet-recon-builtin-windows.md) | Recon de red en un Windows recién comprometido usando SOLO comandos nativos (cmd + PowerShell, sin netcat ni nmap): máxima info con lo que ya viene instalado. |
| [cheatsheet-red-linux](00-assets/cheatsheet-red-linux.md) | Cheatsheet de red para Linux orientada a ciberseguridad: recon, enumeración de servicios, sniffing, MITM, firewalls, tunneling y pivoting. |
| [cheatsheet-red-windows](00-assets/cheatsheet-red-windows.md) | Cheatsheet de red para Windows (cmd + PowerShell) orientada a ciberseguridad: recon, enumeración, firewall, pivoting y post-explotación. |
| [hping3-ping-sweep](01-recon/linux/hping3-ping-sweep.sh) | Barrido de hosts con hping3: detección de hosts vivos por ICMP/SYN/ACK y de filtrado por firewall. |
| [whois-enum](01-recon/linux/whois-enum.sh) | Reunión de información pasiva de un dominio: whois, registros DNS y resolución de hosts comunes. |
| [nmap-nse](02-enumeration/linux/nmap-nse.sh) | Escaneos con scripts NSE de nmap por categoría: seguridad/default, vulnerabilidades, descubrimiento y scripts sueltos. |
| [nmap-scan](02-enumeration/linux/nmap-scan.sh) | Cheatsheet de nmap: descubrimiento de hosts, escaneo de puertos, versiones, OS, timing y salida a archivos. |
| [netview](02-enumeration/windows/netview.ps1) | Muestra los puertos TCP en estado LISTENING con su PID, proceso y servicio asociado. |
| [metasploit-cheatsheet](03-exploitation/linux/metasploit-cheatsheet.md) | Comandos esenciales de msfconsole y msfvenom: búsqueda, exploits, sesiones y auxiliares del día a día. |
| [msfvenom-reverse-shells](03-exploitation/linux/msfvenom-reverse-shells.sh) | Generación de payloads de reverse shell con msfvenom para Windows, Linux y web, con el listener de msfconsole. |
| [post-exploitation-linux](04-post-exploitation/linux/post-exploitation.sh) | Comandos útiles tras comprometer un host Linux: identidad, sistema, usuarios, red, procesos, cron, SUID y credenciales típicas. |
| [post-exploitation-windows](04-post-exploitation/windows/post-exploitation.ps1) | Comandos útiles tras comprometer un host Windows: identidad, sistema, usuarios, red, credenciales almacenadas y tareas. |
| [privesc-check-linux](05-privesc/linux/privesc-check.sh) | Enumeración rápida de vectores de escalada de privilegios en Linux: SUID/SGID, sudo, capabilities, cron, PATH escribible y credenciales. |
| [privesc-check-windows](05-privesc/windows/privesc-check.ps1) | Enumeración de vectores de escalada de privilegios en Windows: tokens, parches, servicios con ruta no entrecomillada/reescribible y autoruns. |
| [hydra-cheatsheet](07-password-attacks/linux/hydra-cheatsheet.sh) | Lista de ataques de fuerza bruta con hydra sobre SSH, RDP, SMB, FTP y HTTP, más notas de hashcat para modo offline. |
| [set-cheatsheet](11-social-engineering/linux/set-cheatsheet.md) | Guía rápida del Social Engineering Toolkit (SET): instalación, phishing con clonado de sitios, captura de credenciales y correo masivo. |
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
- ¿Phishing o ingeniería social? → `11-social-engineering` · ¿No encaja en nada? → `10-misc` (y muévelo cuando madure)

---

## Convenciones

- Nombres de archivo en **minúsculas con guiones** (`netview.ps1`, `port-scanner.sh`).
- Todo script empieza con la cabecera `# Nombre / # Descripción / # Tags / # Uso`.
- Vuelve a ejecutar `scripts/update-index.ps1` **después de añadir, renombrar o borrar** cualquier herramienta.
- No subir wordlists o binarios gigantes a git; enlazar la fuente en `00-assets`.





