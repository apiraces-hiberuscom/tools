# 01-recon

Fase de reconocimiento: footprinting, OSINT, descubrimiento de objetivos y superficie de ataque.

## Qué buscar
- Dominios, subdominios, IPs y rangos del objetivo
- Servicios expuestos a internet (puertos abiertos, banners)
- Información pasiva: registros DNS, whois, certificados SSL, historial
- Empleados, emails, credenciales filtradas

## Herramientas

| Script | Plataforma | Qué hace |
|--------|------------|----------|
| [whois-enum](linux/whois-enum.sh) | Linux | OSINT pasivo: whois, registros DNS, resolución de hosts |
| [hping3-ping-sweep](linux/hping3-ping-sweep.sh) | Linux | Barrido de hosts con hping3: ICMP/SYN/ACK |

## Cheatsheets

| Cheatsheet | Contenido |
|------------|-----------|
| [recon-builtin-linux](linux/cheatsheet-recon-builtin-linux.md) | Recon con comandos nativos Linux (sin nmap/nc) |
| [recon-builtin-windows](windows/cheatsheet-recon-builtin-windows.md) | Recon con comandos nativos Windows (cmd + PowerShell) |

## Comandos rápidos

```bash
# OSINT de dominio
whois example.com
dig example.com ANY
dig example.com AXFR  # zona de transferencia

# Barrido de hosts
nmap -sn 10.10.10.0/24
hping3 --scan 1-1000 10.10.10.5
arp-scan --localnet

# Resolución DNS masiva
for s in $(cat subdomains.txt); do dig +short $s.example.com; done | grep -v "^$"
```

## Tips
- Empieza por recon pasivo (whois, DNS, certificados) antes de tocar el objetivo directamente
- `amass enum -d example.com` para subdominios pasivos
- Revisar certificados SSL en crt.sh para descubrir subdominios
- `theHarvester -d example.com -b all` para emails y hosts
