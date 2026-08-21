#!/usr/bin/env bash
# Nombre: banner-grab
# Descripción: Captura de banners con netcat y telnet: peticiones tipicas para identificar servicios y versiones en puertos abiertos.
# Tags: banner, netcat, nc, telnet, service-detection, enumeration
# Uso: editar TARGET y ejecutar. Descomentar el servicio deseado.

TARGET="192.168.1.100"

echo "=== NETCAT (nc) ==="

echo "--- HTTP ---"
echo "GET / HTTP/1.0\r\nHost: $TARGET\r\n\r\n" | nc -w 3 "$TARGET" 80
echo "HEAD / HTTP/1.0\r\nHost: $TARGET\r\n\r\n" | nc -w 3 "$TARGET" 80

echo "--- HTTPS (sin TLS, solo para ver banner raw) ---"
echo "" | nc -w 3 "$TARGET" 443

echo "--- SSH ---"
echo "" | nc -w 3 "$TARGET" 22

echo "--- FTP ---"
echo "USER anonymous\r\nPASS anonymous@\r\nQUIT\r\n" | nc -w 3 "$TARGET" 21

echo "--- SMTP ---"
echo "EHLO test.local\r\nQUIT\r\n" | nc -w 3 "$TARGET" 25

echo "--- POP3 ---"
echo "USER test\r\nPASS test\r\nQUIT\r\n" | nc -w 3 "$TARGET" 110

echo "--- IMAP ---"
echo "a001 CAPABILITY\r\n" | nc -w 3 "$TARGET" 143

echo "--- MySQL ---"
echo "" | nc -w 3 "$TARGET" 3306

echo "--- RDP ---"
echo "" | nc -w 3 "$TARGET" 3389

echo "--- SMB/NetBIOS ---"
echo "" | nc -w 3 "$TARGET" 445

echo "--- DNS ---"
echo -n "www.google.com" | nc -w 3 -u "$TARGET" 53 | xxd

echo "--- SIP (VoIP) ---"
echo "OPTIONS sip:$TARGET SIP/2.0\r\nVia: SIP/2.0/UDP 192.168.1.1:5060\r\nFrom: <sip:test@192.168.1.1>\r\nTo: <sip:$TARGET>\r\nCall-ID: 1234@192.168.1.1\r\nCSeq: 1 OPTIONS\r\n\r\n" | nc -w 3 "$TARGET" 5060

echo "--- Redis ---"
echo "PING\r\n" | nc -w 3 "$TARGET" 6379

echo "--- Memcached ---"
echo "version\r\n" | nc -w 3 "$TARGET" 11211

echo "--- MongoDB ---"
echo "" | nc -w 3 "$TARGET" 27017

echo "--- Elasticsearch ---"
echo "GET / HTTP/1.1\r\nHost: $TARGET:9200\r\n\r\n" | nc -w 3 "$TARGET" 9200

echo ""
echo "=== TELNET ==="

echo "--- HTTP ---"
telnet -e "" "$TARGET" 80 << 'EOF'
GET / HTTP/1.0

HEAD / HTTP/1.0

EOF

echo "--- FTP ---"
telnet -e "" "$TARGET" 21 << 'EOF'
USER anonymous
PASS anonymous@
QUIT
EOF

echo "--- SMTP ---"
telnet -e "" "$TARGET" 25 << 'EOF'
EHLO test.local
QUIT
EOF

echo "--- POP3 ---"
telnet -e "" "$TARGET" 110 << 'EOF'
USER test
PASS test
QUIT
EOF

echo "--- IMAP ---"
telnet -e "" "$TARGET" 143 << 'EOF'
a001 CAPABILITY
EOF

echo "--- SSH (solo muestra banner, login fallara) ---"
telnet -e "" "$TARGET" 22

echo "--- MySQL ---"
telnet -e "" "$TARGET" 3306

echo "--- Redis ---"
telnet -e "" "$TARGET" 6379 << 'EOF'
PING
INFO server
QUIT
EOF

echo "--- Memcached ---"
telnet -e "" "$TARGET" 11211 << 'EOF'
version
stats
quit
EOF

echo ""
echo "=== BANNER GRABBING PASIVO (bash puro) ==="
echo "--- Timeout corto para capturar banner sin interaccion ---"
(echo "" > /dev/tcp/"$TARGET"/22) 2>/dev/null && cat < /dev/tcp/"$TARGET"/22 &
sleep 2
kill %1 2>/dev/null
