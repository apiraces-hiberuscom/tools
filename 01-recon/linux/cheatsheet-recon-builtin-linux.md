# Nombre: cheatsheet-recon-builtin-linux
# Descripción: Recon de red en un Linux recién comprometido usando SOLO comandos nativos (sin nmap, nc, tcpdump...): máxima info con lo que ya viene instalado.
# Tags: linux, recon, post-exploitation, builtin, network, enumeration
# Uso: copia/pega cada comando en la shell; prioriza lo marcado con (*)

# Recon de red — Linux (solo comandos nativos)

> Regla: si el binario no existe, prueba el equivalente moderno (`ip`/`ss`) o el legado (`ifconfig`/`netstat`). Todo lo de abajo viene en una instalación base.

## 1. Identificación del host (*)
- `hostname` · `hostname -f` · `hostname -I` → nombre y todas las IPs
- `cat /etc/hostname` · `cat /etc/hosts` → alias locales / nombres internos (revela dominios y hosts del entorno)
- `cat /etc/host.conf` · `cat /etc/nsswitch.conf` → orden de resolución (hosts, dns, mdns, ldap...)
- `uname -a` → kernel (afecta a exploits de red/privilegios)
- `cat /etc/os-release` · `cat /etc/issue` → distro y versión
- `env` → variables (PATH, USER, HOME); `env | grep -i proxy` → proxy configurado en sesión
- `set` · `export -p`

## 2. Interfaces y direcciones (*)
- `ip addr` · `ip -br a` → todas las interfaces con IP/MAC
- `ip link` · `ip -s link` → estado y contadores de tráfico (ve si hay forwarding/tráfico raro)
- `cat /proc/net/dev` → contadores por interfaz (tráfico entrante/saliente)
- `cat /proc/net/fib_trie | grep -A1 /32 | grep -E "^ +\|" ` → IPs asociadas a la máquina
- `ifconfig` (legado) · `ifconfig -a`
- `cat /etc/network/interfaces` · `ls /etc/netplan/` y `cat /etc/netplan/*.yaml` · `systemd-networkd` → config estática/DHCP
- `ethtool eth0` → velocidad/MTU (poco util pero confirma NIC)

## 3. Vecinos y ARP (*)
- `ip neigh` · `arp -a` · `cat /proc/net/arp` → hosts que han hablado con esta máquina (mapa de la LAN)
- `cat /proc/net/wireless` → redes WiFi a las que está conectada

## 4. Rutas y gateway (*)
- `ip route` · `ip route show` · `route -n` → tabla de rutas (subredes internas que conoce = posibles pivots)
- `ip route get 8.8.8.8` → por dónde sale a internet
- `cat /proc/net/route`
- `netstat -rn`
- `ip route show table all` → rutas en otras tablas (policy routing)

## 5. DNS (*)
- `cat /etc/resolv.conf` → servidores DNS (si hay uno interno = red corporativa)
- `getent hosts dominio` · `getent ahosts host` → resolver usando nsswitch (built-in)
- `getent hosts $(hostname)` → nombre completo de esta máquina
- `nslookup dominio` · `nslookup -type=ANY dominio` (si está instalado, suele estarlo)
- `host dominio` (si existe, bind-utils) · `host -t MX dominio`
- `ping -c 1 nombre` → resuelve y confirma hostname
- `cat /etc/hosts` → revisa de nuevo: los hosts locales suelen tener los nombres internos

## 6. Puertos y sockets en escucha (*)
- `ss -tulpn` → puertos TCP/UDP escuchando + proceso + usuario (root)
- `ss -lntu` · `ss -ltn` (solo TCP) · `ss -lun` (solo UDP)
- `netstat -tulpn` (legado) · `netstat -lntu`
- `ss -s` → resumen de sockets (cuántas conexiones, tipos)
- `cat /proc/net/tcp` → sockets TCP crudos (columna 4 estado: 0A=LISTEN, 01=ESTABLISHED)
- `cat /proc/net/tcp6` · `cat /proc/net/udp` · `cat /proc/net/unix`
- `systemctl list-sockets --all` → sockets que gestiona systemd (vía Sockets activados)
- `service --status-all` (Debian/Ubuntu) → servicios (activos = posibles puertos)

## 7. Conexiones activas (*)
- `ss -tnp` → conexiones TCP establecidas + proceso (¿dónde está hablando esta máquina?)
- `ss -tunp` → incluye UDP
- `netstat -tnp` · `netstat -an | grep ESTABLISHED`
- `cat /proc/net/tcp | grep 01` → estados ESTABLISHED crudos
- `ss -tan` (sin resolver, con estados) · `ss -t state established '( sport = :22 or dport = :22 )'` → tráfico concreto
- Buscar puertos de interés: `ss -tunp | grep -E ':80|:443|:22|:3306|:5432|:6379|:8080'`

## 8. Servicios de red configurados (*)
- `cat /etc/ssh/sshd_config` (si existe) → puerto SSH, PermitRootLogin, AllowUsers, banners
- `ls -la /etc/ssh/` → claves de host y `authorized_keys` de otros usuarios (SSH estático de confianza)
- `cat /etc/exports` → comparte NFS (con rangos/redes)
- `mount` · `df -h` · `cat /etc/fstab` → unidades montadas: NFS (`mount -t nfs`), CIFS (`//servidor/share`), iSCSI
- `cat /etc/samba/smb.conf` (si existe) → servidor SMB local
- `cat /etc/xinetd.conf` · `ls /etc/xinetd.d/` · `grep -r service /etc/inetd.conf` → servicios de red legados (finger, daytime...)
- `cat /etc/ldap.conf` · `cat /etc/sssd/sssd.conf` · `cat /etc/krb5.conf` · `cat /etc/yp.conf` → integración con AD/LDAP/NIS/Kerberos (revela dominios y DC)
- `ls /etc/openvpn/ /etc/wireguard/ 2>/dev/null` → VPNs configuradas (posibles redes remotas)
- `cat /etc/hosts.allow` · `cat /etc/hosts.deny` → restricciones TCP wrappers (revela IPs/redes conocidas)
- `ss -x` → sockets unix (aplicaciones IPC, no confundir con red)

## 9. Logs de red / actividad externa (*)
- `tail -100 /var/log/auth.log` (Debian) · `tail -100 /var/log/secure` (RHEL) → logins SSH con IP origen (¿quién se conecta a esta máquina?)
- `grep "Accepted\|Failed" /var/log/auth.log*` → intentos de conexión y con éxito
- `journalctl -u sshd --no-pager | tail -50` → igual vía systemd
- `last -i` · `last` · `lastlog` → últimos logins con IP · `w -i` · `who` → quién está conectado ahora y desde dónde
- `journalctl --no-pager -n 200` → logs recientes de todo (busca tráfico, DHCP, fail2ban, fallos de DNS)
- `find /var/log -type f -newermt '-7 days' 2>/dev/null | head` → logs recientes
- `grep -rI "sshd" /var/log 2>/dev/null | grep -i "accepted\|failed"` → resumen global

## 10. Historial, archivos y credenciales de red
- `cat ~/.bash_history` · `grep -E "ssh|scp|ftp|curl|wget|nc |ncat|telnet|smb|mount|nfs|rsync" ~/.bash_history` → con qué máquinas ha interactuado el usuario
- `cat ~/.ssh/known_hosts` → hosts a los que esta máquina se ha conectado por SSH (golden recon)
- `ls -la ~/.ssh/ ~/.config/ 2>/dev/null` · `cat ~/.ssh/id_rsa*` (si es alcanzable)
- `find / -name "*.pcap" -o -name "*.cap" 2>/dev/null` → capturas de tráfico guardadas
- `find / -name ".netrc" -o -name ".my.cnf" -o -name "*.ovpn" 2>/dev/null` → credenciales de red en claro
- `crontab -l` · `cat /etc/crontab` · `ls /etc/cron.*/` → tareas programadas: ¿rsync/backups a servidores remotos con credenciales?

## 11. Firewall nativo (*)
- `iptables -L -n -v` · `iptables -S` · `iptables -t nat -L -n -v` (root) → reglas y NAT (¿está redirigiendo tráfico? = pivot/MITM)
- `iptables-save` → volcado completo
- `nft list ruleset` (nftables) · `ufw status verbose` · `ufw status numbered`
- `cat /etc/iptables/rules.v4` · `ls /etc/ufw/`
- `ss -tnp | grep -E ':80|:443|:8080' | awk '{print $6}'` → proceso tras un puerto web

## 12. Proxy / variables de entorno
- `env | grep -i -E "proxy|http|https|ftp"` → proxy del sistema
- `cat /etc/environment` · `grep -r proxy /etc/profile.d/ /etc/bash.bashrc 2>/dev/null`
- `cat ~/.curlrc` · `cat ~/.wgetrc` → credenciales/URLs en configs de descarga
- `npm config list` · `pip config list` (si existen) → registries/proxies de desarrolladores

## 13. Recon de red activo sin herramientas (solo ping) (*)
- Ping sweep (lanza en paralelo): `for i in $(seq 1 254); do (ping -c1 -W1 10.10.10.$i >/dev/null 2>&1 && echo "10.10.10.$i UP") & done; wait`
- Con fichero de salida: `for i in $(seq 1 254); do ping -c1 -W1 10.10.10.$i >/dev/null 2>&1 && echo "10.10.10.$i" >> alive.txt & done; wait; cat alive.txt`
- Comprobar un puerto TCP con bash (sin nc): `timeout 2 bash -c 'echo > /dev/tcp/10.10.10.5/445' && echo "445 open"` → o en loop para barrer puertos: `for p in 21 22 80 135 139 443 445 3389 8080; do timeout 1 bash -c "echo > /dev/tcp/10.10.10.5/$p" 2>/dev/null && echo "$p open"; done`
- UDP con bash no se puede de forma fiable; mejor revisar `ss -lun` local y /proc/net/udp
- Si hay salida a internet, probar si el tráfico DNS/saliente funciona: `ping -c1 8.8.8.8` · `getent hosts google.com`

## 14. Wireless (si aplica)
- `iwconfig` · `iw dev` · `cat /proc/net/wireless` → red WiFi conectada (SSID/BSSID)
- `nmcli dev status` · `nmcli con show` (si existe NetworkManager) → perfiles y redes guardadas
- `wpa_cli status` (si existe)

## 15. Misc rápido
- `id` · `whoami` · `sudo -l` → qué puedo ejecutar como root (afecta a si puedo leer logs/firewall)
- `ps auxf | grep -iE "ssh|vpn|agent|socat|nc|curl|wget|scp|rsync"` → procesos de red activos del host
- `ls -la /proc/net/` → ver qué archivos existen (tcp, udp, arp, route, dev, wireless, unix, netlink...)
- `cat /proc/net/tcp | awk '{print $2, $3, $4}' | head` → parseo rápido de sockets (hex: IP y puerto)
- `date` · `uptime` → contexto temporal del entorno
- `cat /etc/mtab` → igual que mount pero crudo

## Notas
- Todo lo anterior es información que deja rastro mínimo: no instala nada ni modifica el sistema.
- Prioriza: /proc/net/* + `ss` + logs + known_hosts + fstab/mount + firewall. Eso suele responder "¿qué es esta máquina y con qué se comunica?".
- Guarda lo que veas: `script recon.txt` o redirige a fichero para no perderlo al perder la shell.