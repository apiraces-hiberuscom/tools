#!/usr/bin/env bash
# Nombre: nmap-scan
# Descripción: Cheatsheet de nmap: descubrimiento de hosts, escaneo de puertos, versiones, OS, timing y salida a archivos.
# Tags: nmap, scan, ports, tcp, udp, osint
# Uso: editar TARGET/TARGETS y descomentar el escaneo deseado

TARGET="192.168.1.100"
TARGETS="192.168.1.0/24"

echo "=== 1. Descubrimiento de hosts vivos (no escanea puertos) ==="
# nmap -sn "$TARGETS"                 # ping sweep ARP/ICMP
# nmap -PS445 "$TARGETS"              # discovery en redes Windows (Syn 445)
# nmap -Pn --top-ports 100 "$TARGET"  # saltar discovery, asumir vivo

echo "=== 2. Escaneo rapido de puertos ==="
# nmap "$TARGET"                      # top 1000 por defecto
# nmap -T4 -F "$TARGET"               # fast: top 100

echo "=== 3. Escaneo completo (65.535 puertos) ==="
# nmap -p- -T4 "$TARGET"

echo "=== 4. Rango de puertos especifico ==="
# nmap -p22,80,443,3306 "$TARGET"
# nmap -p1-1000 "$TARGET"

echo "=== 5. UDP (es lento: limitar el rango) ==="
# nmap -sU --top-ports 50 --version-light -T4 "$TARGET"

echo "=== 6. Deteccion de versiones (sV) y scripts por defecto (sC) ==="
# nmap -sV -sC "$TARGET"
# nmap -O --osscan-guess "$TARGET"    # fingerprint de OS

echo "=== 7. Timing y rendimiento ==="
# nmap -T4 "$TARGET"                  # T0 (paranoico) ... T5 (insano)
# nmap --min-rate 1000 -p- "$TARGET"  # fuerzas ratio de paquetes

echo "=== 8. Salida a archivos ==="
# nmap -oA scanbase "$TARGET"         # genera .nmap .gnmap .xml
# nmap -sn "$TARGETS" -oG - | awk '/Up$/{print $2}'   # solo IPs vivas