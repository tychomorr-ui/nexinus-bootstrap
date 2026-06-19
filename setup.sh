#!/usr/bin/env bash
set -e

echo "=== 1/3 Enabling SSH password login ==="
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config 2>/dev/null || true
mkdir -p /etc/ssh/sshd_config.d
printf 'PasswordAuthentication yes\nPermitRootLogin yes\n' > /etc/ssh/sshd_config.d/99-xinus.conf
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
echo "SSH password login: ENABLED"

echo "=== 2/3 Installing Monarch health endpoint ==="
mkdir -p /opt/monarch-health
cat > /opt/monarch-health/server.py <<'PY'
import http.server, socketserver, json, datetime
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.rstrip('/') in ('/health','/health/') or self.path=='/health':
            body=json.dumps({"ok":True,"node":"xinus-monarch","provider":"hetzner","serverId":"131714540","region":"singapore","role":"XinUS MonarchOS node","ts":datetime.datetime.utcnow().isoformat()+"Z"}).encode()
            self.send_response(200)
            self.send_header("Content-Type","application/json")
            self.send_header("Access-Control-Allow-Origin","*")
            self.send_header("Cache-Control","no-store")
            self.end_headers(); self.wfile.write(body)
        else:
            self.send_response(404); self.end_headers()
    def log_message(self,*a): pass
socketserver.TCPServer.allow_reuse_address=True
with socketserver.TCPServer(("",80),H) as s: s.serve_forever()
PY
cat > /etc/systemd/system/monarch-health.service <<'UNIT'
[Unit]
Description=XINUS Monarch health endpoint
After=network.target
[Service]
ExecStart=/usr/bin/python3 /opt/monarch-health/server.py
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now monarch-health
sleep 1

echo "=== 3/3 Verifying ==="
echo "MONARCH HEALTH UP:"
curl -fsS http://127.0.0.1/health && echo ""
echo ""
echo "DONE. SSH password login is on, /health is serving on port 80."
