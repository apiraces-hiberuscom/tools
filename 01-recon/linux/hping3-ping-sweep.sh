#!/usr/bin/env bash
# Nombre: hping3-ping-sweep
# Descripción: Barrido de hosts con hping3: detección de hosts vivos por ICMP/SYN/ACK y de filtrado por firewall.
# Tags: hping3, firewall, recon, icmp, tcp
# Uso: ./hping3-ping-sweep.sh 203.0.113.10  [203.0.113.11 ...]

HOSTS="${@:-203.0.113.10}"
echo "Objetivos: $HOSTS"

for host in $HOSTS; do
    echo -e "\n=== $host ==="

    echo "-- ICMP (responde = vivo) --"
    sudo hping3 -1 -c 2 "$host" 2>/dev/null && echo "   responde a ping"

    echo "-- SYN a puerto 80 (responde SYN/ACK = abierto) --"
    sudo hping3 -S -p 80 -c 2 "$host" 2>/dev/null

    echo "-- SYN a puerto 443 --"
    sudo hping3 -S -p 443 -c 2 "$host" 2>/dev/null

    echo "-- ACK a 443 (RST = no filtrado / silencio = filtrado por firewall) --"
    sudo hping3 -A -p 443 -c 3 "$host" 2>/dev/null
done