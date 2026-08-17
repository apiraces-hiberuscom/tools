#!/usr/bin/env bash
# Nombre: privesc-check-linux
# Descripción: Enumeración rápida de vectores de escalada de privilegios en Linux: SUID/SGID, sudo, capabilities, cron, PATH escribible y credenciales.
# Tags: linux, privesc, suid, sudo, capability, enumeration
# Uso: ./privesc-check.sh

echo "=== 1. ARCHIVOS SUID / SGID ==="
find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null

echo -e "\n=== 2. SUDO PERMITIDO ==="
sudo -l 2>/dev/null

echo -e "\n=== 3. BINARIOS CON CAPABILITIES ==="
getcap -r / 2>/dev/null

echo -e "\n=== 4. CRON Y RUTAS EJECUTADAS POR ROOT ==="
cat /etc/crontab 2>/dev/null
ls -la /etc/cron.d/ 2>/dev/null | head -20
grep -Ril "root" /etc/cron* 2>/dev/null

echo -e "\n=== 5. DIRECTORIOS ESCRIBIBLES (posible secuestro de PATH) ==="
find / -type d -writable 2>/dev/null | grep -v -E '^/(proc|sys|dev|run)' | head -20

echo -e "\n=== 6. BITS FACILES DE CREDENCIALES ==="
# grep -Ril "password" /var/www /var/backups 2>/dev/null
# cat /etc/shadow 2>/dev/null
# ls -la ~/.ssh/ 2>/dev/null
# mysql -u root -e 'select user,password from mysql.user' 2>/dev/null