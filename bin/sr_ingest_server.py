#!/usr/bin/env python3
import os, json, time, sys
from pathlib import Path
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

PORT = int(os.environ.get("SR_INGEST_PORT", os.environ.get("PORT", "8891")))
HOME = Path.home()
ROOT = HOME / "static-rooster"
INBOX = ROOT / "receipts" / "inbox"
INBOX.mkdir(parents=True, exist_ok=True)

def cors(h):
    h.send_header("Access-Control-Allow-Origin", "*")
    h.send_header("Access-Control-Allow-Headers", "*")
    h.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")

class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        # quieter logs to stdout
        sys.stdout.write(("%s\n" % (fmt % args)))

    def send_json(self, obj, code=200):
        self.send_response(code)
        cors(self)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(obj).encode())

    def do_OPTIONS(self):
        self.send_response(204)
        cors(self)
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path.rstrip("/") or "/"
        if path == "/health":
            return self.send_json({"ok": True, "port": PORT})
        if path == "/":
            html = f"""<!doctype html>
<meta charset=utf-8>
<title>Reply Ingest</title>
<style>
  body{{font-family:ui-sans-serif,system-ui,Segoe UI,Roboto,Arial; background:#0b1220; color:#d7e2ff}}
  .wrap{{max-width:720px;margin:3rem auto;}}
  .row{{display:grid;grid-template-columns:160px 1fr;gap:8px;align-items:center}}
  .pill{{display:inline-block;padding:6px 10px;border-radius:999px;border:1px solid #2b4880;background:#0e1a35}}
  a{{color:#7dc1ff}}
</style>
<div class=wrap>
  <h1>Reply Ingest</h1>
  <div class=row><div class=pill>port</div><div class=pill><b>{PORT}</b></div></div>
  <div class=row><div class=pill>state</div><div class=pill>ok</div></div>
  <div class=row><div class=pill>time</div><div class=pill><b>{time.strftime('%Y-%m-%d %H:%M:%S')}</b></div></div>
  <p>Health JSON: <a href="/health">/health</a></p>
  <p>POST targets accepted: <code>/build</code>, <code>/submit</code>, <code>/apply</code></p>
</div>"""
            self.send_response(200)
            cors(self)
            self.send_header("Content-Type","text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(html.encode())
            return
        self.send_response(404); cors(self); self.end_headers()

    def do_POST(self):
        path = urlparse(self.path).path.rstrip("/")
        if path in ("/build","/submit","/apply"):
            size = int(self.headers.get("Content-Length","0") or 0)
            data = self.rfile.read(size) if size>0 else b""
            ts = int(time.time())
            up = INBOX / f"upload_{ts}.bin"
            with open(up, "wb") as f: f.write(data)

            # minimal receipt stub so timelines/watchers move
            receipt = {
                "ok": True,
                "ts": ts,
                "size": len(data),
                "upload": str(up.name),
                "generated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            }
            rec_path = ROOT / "receipts" / f"sr_done_receipt_{ts}_v0_1.json"
            rec_path.write_text(json.dumps(receipt, indent=2))
            return self.send_json({"ok": True, "stored": up.name, "receipt": rec_path.name})
        self.send_response(404); cors(self); self.end_headers()

if __name__ == "__main__":
    addr = ("127.0.0.1", PORT)
    httpd = ThreadingHTTPServer(addr, H)
    print(f"ingest on http://{addr[0]}:{addr[1]}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
