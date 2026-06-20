#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== 0/4 Fix DNS resolver (defensive) ==="
grep -q "nameserver" /etc/resolv.conf 2>/dev/null && head -1 /etc/resolv.conf | grep -q "127.0.0" && {
  rm -f /etc/resolv.conf; echo "nameserver 1.1.1.1" > /etc/resolv.conf;
} || true

echo "=== 1/4 Enable SSH password login (so you can leave the web console) ==="
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true
mkdir -p /etc/ssh/sshd_config.d
printf 'PasswordAuthentication yes\nPermitRootLogin yes\n' > /etc/ssh/sshd_config.d/99-xinus.conf
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

echo "=== 2/4 Install Caddy (auto-TLS reverse proxy) ==="
apt-get update -y
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install -y caddy

echo "=== 3/4 Write Caddyfile for nexinus.net (auto Let's Encrypt) ==="
cat > /etc/caddy/Caddyfile <<'CADDY'
nexinus.net, www.nexinus.net {
    handle /health {
        header Content-Type "application/json"
        header Access-Control-Allow-Origin "*"
        header Cache-Control "no-store"
        respond `{"ok":true,"node":"tesseract-a","provider":"hetzner","serverId":"129345837","region":"falkenstein","role":"light mirror","ts":"live"}` 200
    }
    handle {
        respond "Tesseract-A · Nexinus RI Systems · sovereign node online" 200
    }
}
CADDY

echo "=== 4/4 Start Caddy + verify ==="
systemctl enable caddy 2>/dev/null || true
systemctl restart caddy
sleep 3
echo "TESSERACT-A LOCAL HEALTH:"
curl -fsS http://127.0.0.1/health || echo "(local check failed — see: systemctl status caddy)"
echo ""
echo "DONE. Caddy will fetch a Let's Encrypt cert for nexinus.net within ~30s."
echo "From your laptop:  curl https://nexinus.net/health"
