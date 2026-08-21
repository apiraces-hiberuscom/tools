# 08-web

Explotación y análisis de aplicaciones web: inyecciones, XSS, SSRF, autenticación, APIs...

## Qué buscar
- Vulnerabilidades de inyección (SQLi, LFI/RFI, SSTI)
- XSS almacenado/reflejado/DOM
- SSRF hacia servicios internos
- Archivos sensibles (.git, .env, backups)
- Tecnologías y versiones (WordPress, Joomla, Apache)

## Herramientas

| Script | Plataforma | Qué hace |
|--------|------------|----------|
| [cheatsheet-web](cheatsheet-web.md) | Linux/Windows | SQLi, XSS, LFI, RFI, SSRF, fingerprinting, bypass |

## Comandos rápidos

```bash
# Enumeración de directorios
gobuster dir -u http://10.10.10.5 -w /usr/share/wordlists/dirb/common.txt
ffuf -u http://10.10.10.5/FUZZ -w wordlist.txt

# SQLi
sqlmap -u "http://10.10.10.5/page?id=1" --dbs --batch

# Escáner de vulns
nikto -h http://10.10.10.5
nuclei -u http://10.10.10.5 -t cves/
```

## Tips
- Siempre empezar por fingerprinting antes de explotar
- Revisar JavaScript del sitio (APIs ocultas, endpoints)
- Probar tanto GET como POST, y parámetros en cookies/headers
- Usar Burp Suite para interceptar y modificar peticiones
