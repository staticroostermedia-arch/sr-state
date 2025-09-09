from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os, time

PORT = int(os.getenv("SR_INGEST_PORT","8891"))

HTML = f"""<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Reply Ingest · Static Rooster</title>
<style>
  :root {{ color-scheme: dark; }}
  body {{ margin:0; background:#0f1a2b; color:#d7e2ff; font:16px/1.45 ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto; }}
  .wrap {{ max-width:960px; margin:8vh auto; padding:24px; }}
  .card {{ background:#0b1322; border:1px solid #1e2a44; border-radius:16px; padding:20px; box-shadow:0 10px 30px rgba(0,0,0,.25); }}
  h1 {{ margin:0 0 6px; font-size:24px; letter-spacing:.3px; }}
  .muted {{ color:#8aa2c4; font-size:14px; }}
  .row {{ display:flex; gap:16px; margin-top:14px; }}
  .kv {{ display:grid; grid-template-columns:160px 1fr; gap:8px 16px; margin-top:10px; }}
  .pill {{ display:inline-flex; align-items:center; gap:8px; padding:6px 10px; border-radius:999px; background:#0d233d; border:1px solid #22406a; }}
  a.btn {{ text-decoration:none; color:#d7e2ff; border:1px solid #2b4880; padding:8px 12px; border-radius:10px; background:#13284a; }}
  a.btn:hover {{ border-color:#5a86ff; box-shadow:0 0 0 3px rgba(90,134,255,.2) inset; }}
</style>
</head><body><div class="wrap">
  <div class="card">
    <h1>Reply Ingest</h1>
    <div class="muted">Minimal status endpoint served by the ingest service.</div>
    <div class="row">
      <div class="pill">port <b>{PORT}</b></div>
      <div class="pill">state <b>ok</b></div>
      <div class="pill">time <b>{time.strftime('%Y-%m-%d %H:%M:%S')}</b></div>
      <a class="btn" href="/health">JSON /health</a>
    </div>
    <div class="kv">
      <div>Spec:</div> <div>GET <code>/health</code> → <code>{{"ok": true}}</code></div>
      <div>Root:</div> <div>GET <code>/</code> → this page</div>
    </div>
  </div>
</div></body></html>"""

class H(BaseHTTPRequestHandler):
    def _json(self, obj, code=200):
        self.send_response(code)
        self.send_header("Content-Type","application/json")
        self.end_headers()
        self.wfile.write(json.dumps(obj).encode())

    def do_GET(self):
        if self.path == "/health":
            return self._json({"ok": True, "port": PORT})
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type","text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML.encode())
            return
        self.send_error(404)

    def log_message(self, *a, **k): pass

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), H).serve_forever()
