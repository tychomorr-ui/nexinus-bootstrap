#!/usr/bin/env bash
set -e
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
echo "MONARCH HEALTH UP:"
curl -fsS http://127.0.0.1/health && echo ""
