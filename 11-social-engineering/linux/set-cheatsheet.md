# Nombre: set-cheatsheet
# Descripción: Guía rápida del Social Engineering Toolkit (SET): instalación, phishing con clonado de sitios, captura de credenciales y correo masivo.
# Tags: set, social-engineering, phishing, credential-harvester, mass-mailer
# Uso: referencia rapida; busca con Ctrl+F la seccion que necesites

## Instalación
- Kali/Parrot: `apt install set` (o `sudo apt install set`)
- Desde fuente: `git clone https://github.com/trustedsec/social-engineer-toolkit` y ejecutar `./setup.py install`
- Arranque: `sudo setoolkit` (requiere root)
- Config: `/usr/share/set/config/set_config` (versiones nuevas: `~/.set/config`)

## Menú principal
- `1` Social-Engineering Attacks
- `2` Fast-Track Penetration Testing
- `3` Third Party Modules
- `4` Update the Social-Engineer Toolkit
- `5` Exit

## Vectores de ataque (menú 1)
- `1` Spear-Phishing Attack Vectors → correo con payload adjunto
- `2` Website Attack Vectors → clonado de sitios, browser exploits
- `3` Infectious Media Generator → USB infectado (auto-run)
- `4` Create a Payload and Listener → reverse shell + listener
- `5` Mass Mailer Attack → envío masivo de correos
- `8` QRCode Generator Attack Vector → QR malicioso (requiere instalación)
- `9` Powershell Attack Vectors → delivery de payload vía PowerShell
- `10` SMS Spoofing Attack Vector → SMS suplantado (pide proveedor)

## Flujo típico de phishing (clonado de sitio)
1. `sudo setoolkit`
2. `1` → Social-Engineering Attacks
3. `2` → Website Attack Vectors
4. `3` → Credential Harvester Attack Method
5. `2` → Site Cloner
6. Pide la IP del servidor (la del atacante: `ip a` o `tun0` de VPN)
7. Pide la URL a clonar: `http://www.ejemplo.com` (usa http, no https)
8. Publica el clon en `http://<IP>/`; Apache debe estar activo:
   - `sudo service apache2 start` o `sudo systemctl start apache2`
9. La víctima se loguea → credenciales en pantalla y guardadas en `/root/.set/logs/`

## Spear-Phishing (correo con payload)
1. Menú 1 → `1` Spear-Phishing Attack Vectors
2. `1` Perform a Mass Email Attack → con plantilla social
3. Elige formato del payload (PDF, RTF, Excel...) y payload (windows/meterpreter/reverse_tcp, etc.)
4. Define `LHOST` y `LPORT`; SET lanza un listener de Metasploit automáticamente
5. Método de envío: `1` Email Attack Single Email Address o `2` Mass Mailer
6. Rellena remitente/plantilla; SET puede usar Gmail, SMTP propio o Sendmail

## Mass Mailer
1. Menú 1 → `5` Mass Mailer Attack
2. `1` E-Mail Attack Single Email Address / `2` E-Mail Attack Mass Mailer / `3` Harvester Attack (recopila correos desde una web)
3. Elige método: `1` SMTP, `2` Sendmail o `3` Gmail (desde la configuración)

## Notas
- Las credenciales capturadas quedan en pantalla y en los logs de SET (`/root/.set/logs/`)
- El clon de un sitio con https dará error de certificado: el usuario debe ignorar la advertencia
- Para sitios con POST y MFA, considera Evilginx (reverse proxy) en vez del clonador clásico
- Usa solo en ambientes con autorización expresa; el clonado de dominios reales puede violar leyes locales
