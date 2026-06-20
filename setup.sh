#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive
NODE="xinus-monarch"
DOMAIN="monarch.xinus.one"

echo "=== 0/6 Fix DNS resolver (defensive) ==="
if head -1 /etc/resolv.conf 2>/dev/null | grep -q '127.0.0'; then
  rm -f /etc/resolv.conf; echo 'nameserver 1.1.1.1' > /etc/resolv.conf
fi

echo "=== 1/6 Enable SSH password login ==="
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true
mkdir -p /etc/ssh/sshd_config.d
printf 'PasswordAuthentication yes\nPermitRootLogin yes\n' > /etc/ssh/sshd_config.d/99-xinus.conf
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

echo "=== 2/6 Generate Ed25519 keypair ON THIS NODE (idempotent; private key never leaves) ==="
mkdir -p /etc/nexinus && chmod 700 /etc/nexinus
if [ ! -f /etc/nexinus/node.key ]; then
  openssl genpkey -algorithm ed25519 -out /etc/nexinus/node.key
  chmod 600 /etc/nexinus/node.key
fi
openssl pkey -in /etc/nexinus/node.key -pubout -out /etc/nexinus/node.pub
[ -f /etc/nexinus/counter ] || echo 0 > /etc/nexinus/counter

echo "=== 3/6 Install signed-heartbeat writer (counter + measured_at INSIDE signed bytes) ==="
cat > /usr/local/bin/nexinus-sign.sh <<'SIGN'
#!/usr/bin/env bash
set -e
KEY=/etc/nexinus/node.key
CTRF=/etc/nexinus/counter
OUT=/var/www/health/health.json
mkdir -p /var/www/health
ctr=$(cat "$CTRF" 2>/dev/null || echo 0); ctr=$((ctr+1)); echo "$ctr" > "$CTRF"
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
payload="{\"node\":\"xinus-monarch\",\"status\":\"up\",\"counter\":$ctr,\"measured_at\":\"$now\"}"
printf '%s' "$payload" > /tmp/hb.payload
openssl pkeyutl -sign -inkey "$KEY" -rawin -in /tmp/hb.payload -out /tmp/hb.sig
sig=$(base64 -w0 /tmp/hb.sig)
pj=$(printf '%s' "$payload" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')
printf '{"payload":%s,"sig":"%s","alg":"ed25519"}' "$pj" "$sig" > "$OUT"
SIGN
chmod +x /usr/local/bin/nexinus-sign.sh

cat > /etc/systemd/system/nexinus-sign.service <<'UNIT'
[Unit]
Description=Nexinus signed heartbeat writer
[Service]
Type=oneshot
ExecStart=/usr/local/bin/nexinus-sign.sh
UNIT
cat > /etc/systemd/system/nexinus-sign.timer <<'UNIT'
[Unit]
Description=Refresh signed heartbeat every 15s
[Timer]
OnBootSec=5
OnUnitActiveSec=15
AccuracySec=1s
[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now nexinus-sign.timer
/usr/local/bin/nexinus-sign.sh

echo "=== 4/6 Install Caddy (auto-TLS) ==="
apt-get update -y
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install -y caddy

echo "=== 5/6 Caddyfile: serve the SIGNED heartbeat at /health ==="
cat > /etc/caddy/Caddyfile <<CADDY
${DOMAIN} {
    handle /health {
        header Content-Type "application/json"
        header Access-Control-Allow-Origin "*"
        header Cache-Control "no-store"
        root * /var/www/health
        rewrite * /health.json
        file_server
    }
    handle {
        respond "Xinus-Monarch online" 200
    }
}
CADDY
systemctl enable caddy 2>/dev/null || true
systemctl restart caddy
sleep 3

echo "=== 6/6 DONE ==="
echo "Local signed heartbeat:"
curl -fsS http://127.0.0.1/health || echo "(check: systemctl status caddy nexinus-sign.timer)"
echo ""
echo "--- PUBLIC KEY (commit to pubkeys/${NODE}.pub; hand over SSH/WireGuard per 1G) ---"
cat /etc/nexinus/node.pub
echo "------------------------------------------------------------------------------"
echo "From your laptop:  curl https://${DOMAIN}/health"
