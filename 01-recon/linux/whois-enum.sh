#!/usr/bin/env bash
# Nombre: whois-enum
# Descripción: Reunión de información pasiva de un dominio: whois, registros DNS y resolución de hosts comunes.
# Tags: OSINT, dns, whois, recon, subdomain
# Uso: ./whois-enum.sh example.com

DOM="$1"
if [ -z "$DOM" ]; then
    echo "Uso: $0 <dominio>"
    exit 1
fi

echo "=== WHOIS (primeras lineas) ==="
whois "$DOM" | head -40

echo -e "\n=== REGISTROS DNS ==="
echo "-- NS --";  dig NS  "$DOM" +short
echo "-- MX --";  dig MX  "$DOM" +short
echo "-- A --";   dig A   "$DOM" +short
echo "-- TXT --"; dig TXT "$DOM" +short

echo -e "\n=== HOSTS COMUNES ==="
for h in www mail smtp pop imap ftp vpn dns ns1 ns2 mx webmail portal cpanel; do
    ip=$(dig +short A "$h.$DOM" | head -1)
    [ -n "$ip" ] && printf "%-20s -> %s\n" "$h.$DOM" "$ip"
done