#!/usr/bin/env bash
# Nombre: nmap-nse
# Descripción: Escaneos con scripts NSE de nmap por categoría: seguridad/default, vulnerabilidades, descubrimiento y scripts sueltos.
# Tags: nmap, nse, scripts, vulnerability, version
# Uso: editar TARGET y descomentar el escaneo deseado

TARGET="192.168.1.100"

echo "=== Categorias NSE utiles ==="
echo "   safe  intrusive  vuln  exploit  auth  brute  discovery  version  default"
echo "   Listado local: ls /usr/share/nmap/scripts/"

echo "=== 1. Scripts por defecto + safe (recomendado al inicio) ==="
# nmap -sV -sC "$TARGET"

echo "=== 2. Escaneo de vulnerabilidades conocidas ==="
# nmap -sV --script=vuln "$TARGET"

echo "=== 3. Web / SMB / SSH (bundles tipicos) ==="
# nmap -sV --script="http-*,ssl-*" "$TARGET"
# nmap -p445 --script="smb-*" "$TARGET"
# nmap -p22 --script="ssh-*" "$TARGET"

echo "=== 4. Descubrimiento adicional (banner, hostname...) ==="
# nmap -sV --script=discovery "$TARGET"

echo "=== 5. Scripts sueltos de ejemplo ==="
# nmap -p445 --script smb-vuln-ms17-010 "$TARGET"   # EternalBlue
# nmap -p22  --script ssh2-enum-algos "$TARGET"     # algoritmos SSH
# nmap -p80  --script http-headers,http-title "$TARGET"
# nmap -p8009 --script ajp-headers "$TARGET"

echo "=== 6. Brute (OJO: puede bloquear cuentas) ==="
# nmap -p22 --script ssh-brute --script-args userdb=users.txt,passdb=pass.txt "$TARGET"