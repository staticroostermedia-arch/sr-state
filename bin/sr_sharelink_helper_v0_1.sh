#!/bin/sh
set -eu
python3 - <<'PY'
import http.server, socketserver, os, json, glob, html, datetime
ROOT=os.path.expanduser('~/static-rooster')
REC=os.path.join(ROOT,'receipts')
ING=os.path.join(ROOT,'ingest')
OUT=os.path.join(ROOT,'share')
os.makedirs(OUT,exist_ok=True)
BASE='http://127.0.0.1:8888'
def newest(pattern):
    paths=sorted(glob.glob(pattern))
    return paths[-1] if paths else None
def build_share():
    # latest ingest receipt -> discover message/snapshot relative paths
    rfile=newest(os.path.join(REC,'ingest_receipt_*.json'))
    msg_rel=snap_rel=None
    if rfile and os.path.exists(rfile):
        try:
            j=json.load(open(rfile))
            msg_rel=j.get('message')
            snap_rel=j.get('snapshot')
        except Exception:
            pass
    # fallback: pick newest message in ingest
    if not msg_rel:
        m=newest(os.path.join(ING,'message_*.json'))
        if m: msg_rel=os.path.relpath(m,ROOT)
    # write share card
    ts=datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    card=os.path.join(OUT,f'share_{ts}.html')
    # absolute URLs for browser copy
    msg_url=(BASE+msg_rel) if (msg_rel and msg_rel.startswith('/')) else (BASE+'/'+msg_rel if msg_rel else '')
    snap_url=(BASE+snap_rel) if (snap_rel and snap_rel.startswith('/')) else (BASE+'/'+snap_rel if snap_rel else '')
    with open(card,'w') as f:
        f.write(f"<!doctype html><meta charset='utf-8'><title>Static Rooster Share {ts}</title>")
        f.write("<body style='font-family:ui-monospace,Consolas,monospace;background:#0b0c06;color:#b4ffb4'>")
        f.write(f"<h3>Share {ts}</h3>")
        if msg_rel:
            f.write(f"<p>Latest message: <a href='{html.escape(msg_url)}'>{html.escape(msg_url)}</a></p>")
        else:
            f.write("<p>No message found yet. Send from kiosk first.</p>")
        if snap_rel:
            f.write(f"<p>Attached snapshot: <a href='{html.escape(snap_url)}'>{html.escape(snap_url)}</a></p>")
        f.write("<p>Copy this page URL into Chat:</p>")
        page_url=f"{BASE}/share/{os.path.basename(card)}"
        f.write(f"<p style='background:#101410;padding:8px;border:1px solid #224;border-radius:8px'>{html.escape(page_url)}</p>")
        f.write("</body>")
    # machine-readable json too
    j={"generated_at":ts,"tool":"sr_sharelink_helper_v0_1","status":"ok","page":f"/share/{os.path.basename(card)}","message":msg_rel,"snapshot":snap_rel}
    json_path=os.path.join(OUT,f'share_{ts}.json'); open(json_path,'w').write(json.dumps(j))
    return j
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path!="/make": self.send_response(404); self.end_headers(); return
        j=build_share()
        self.send_response(200); self.end_headers(); self.wfile.write(json.dumps(j).encode())
    def do_GET(self):
        if self.path=="/health": self.send_response(200); self.end_headers(); self.wfile.write(b'{"ok":true}'); return
        self.send_response(404); self.end_headers()
PORT=8893
with socketserver.TCPServer(("127.0.0.1",PORT), H) as httpd:
    httpd.serve_forever()
PY
