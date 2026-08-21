#!/usr/bin/env bash
# Nombre: nmap-http-enum
# Descripción: Enumeración web con nmap: http-enum, hostmap-bfk (subdominios), http-waf-detect (WAF) y http-trace.
# Tags: nmap, http, web, http-enum, hostmap, waf, trace, subdomain, enumeration
# Uso: editar TARGET y descomentar el escaneo deseado

TARGET="192.168.1.100"
DOMAIN="example.com"

echo "=== 1. http-enum basico (directorios y archivos comunes) ==="
# nmap -sV --script http-enum "$TARGET"

echo "=== 2. http-enum con hosts virtuales (vhosts) ==="
# nmap -sV --script http-enum --script-args http-enum.basepath=/ "$TARGET"
# nmap -sV --script http-enum -p 80,443 --script-args http-enumvhdomain=$DOMAIN "$TARGET"

echo "=== 3. http-enum sobre multiples puertos web ==="
# nmap -sV -p 80,443,8080,8443 --script http-enum "$TARGET"

echo "=== 4. http-enum + http-headers + http-title (contexto completo) ==="
# nmap -sV -p 80,443 --script http-enum,http-headers,http-title "$TARGET"

echo "=== 5. http-enum con brute de directorios ==="
# nmap -sV -p 80 --script http-enum --script-args http-enum.maxdepth=5 "$TARGET"

echo "=== 6. Escaneo web completo (todos los scripts http-*) ==="
# nmap -sV -p 80,443 --script "http-*" -oA http-full "$TARGET"

echo "=== 7. Deteccion de tecnologias + enum ==="
# nmap -sV -p 80,443 --script http-enum,http-tech,http-generator "$TARGET"

echo "=== 8. Con salida XML para integrar en reportes ==="
# nmap -sV -p 80,443 --script http-enum -oX http-enum.xml "$TARGET"

echo "=== 9. Descubrimiento de subdominios (hostmap-bfk) ==="
# nmap --script hostmap-bfk -script-args hostmap-bfk.prefix=hostmap- "$DOMAIN"

echo "=== 10. Deteccion de WAF (Web Application Firewall) ==="
# nmap -p80 --script http-waf-detect "$DOMAIN"

echo "=== 11. HTTP Trace (prueba de trazabilidad/proxy) ==="
# nmap --script http-trace -d "$DOMAIN"
