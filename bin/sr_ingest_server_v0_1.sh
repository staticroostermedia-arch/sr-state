#!/usr/bin/env bash
set -euo pipefail
PORT="${1:-8891}"
python3 - <<'PY'
import http.server, json, os, datetime

PORT = int(os.environ.get("PORT","8891"))
ROOT = os.path.expanduser("~/static-rooster")
RECP = os.path.join(ROOT, "receipts")
os.makedirs(RECP, exist_ok=True)

def ts():
    return datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

def write_receipt(kind, payload):
    path = os.path.join(RECP, f"{kind}_{ts()}_v0_1.json")
    with open(path, "w") as f:
        json.dump(payload, f, indent=2)

class H(http.server.BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "content-type")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self._cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"ok":true}')
        else:
            self.send_error(404, "not found")

    def do_POST(self):
        if self.path == "/build":
            n = int(self.headers.get("content-length","0") or 0)
            body = self.rfile.read(n) if n > 0 else b""
            txt = body.decode("utf-8", "ignore").strip()
            try:
                data = json.loads(txt if txt.startswith("{") else "{}")
            except Exception:
                data = {}
            payload = data if data else {"raw": txt}
            write_receipt("ingest_message", payload)
            self.send_response(200)
            self._cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"ok":true}')
        else:
            self.send_error(404, "not found")

    def log_message(self, fmt, *args):  # keep logs quiet
        pass

http.server.ThreadingHTTPServer(("", PORT), H).serve_forever()
PY
