#!/usr/bin/env python3
import http.server, json, os, io, tarfile, datetime, glob
ROOT=os.path.expanduser('~/static-rooster'); RE=os.path.join(ROOT,'receipts'); SH=os.path.join(ROOT,'share')
os.makedirs(RE,exist_ok=True); os.makedirs(SH,exist_ok=True)
def latest(pattern):
  xs=sorted(glob.glob(pattern)); return xs[-1] if xs else None
class H(http.server.BaseHTTPRequestHandler):
  def do_POST(self):
    l=int(self.headers.get('content-length','0')); b=self.rfile.read(l) if l>0 else b'{}'
    data=json.loads(b or b'{}')
    ts=datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    # write a tiny “context pack” (right now: last snapshot manifest if present)
    snap=latest(os.path.join(ROOT,'receipts','snapshot_latest.json'))
    pack_path=os.path.join(SH, f'ctx_{ts}.tar.gz')
    buf=io.BytesIO()
    with tarfile.open(fileobj=buf, mode='w:gz') as tar:
      if snap and os.path.exists(snap):
        tar.add(snap, arcname='snapshot_latest.json')
    open(pack_path,'wb').write(buf.getvalue())
    open(os.path.join(RE,f'context_pack_{ts}.json'),'w').write(json.dumps(
      {"ok":True,"ts":ts,"pack":os.path.relpath(pack_path, ROOT)}))
    self.send_response(200); self.end_headers()
    self.wfile.write(json.dumps({"ok":True,"pack":f"/share/{os.path.basename(pack_path)}"}).encode())
  def do_GET(self):
    if self.path=="/share/":
      # simple index of share dir
      files=[f for f in os.listdir(SH) if os.path.isfile(os.path.join(SH,f))]
      html="<h1>share/</h1><ul>"+"".join(f"<li><a href='/share/{f}'>{f}</a></li>" for f in files)+"</ul>"
      self.send_response(200); self.end_headers(); self.wfile.write(html.encode()); return
    self.send_response(404); self.end_headers()
  def log_message(self,*a,**k): pass
class S(http.server.ThreadingHTTPServer): pass
S(('127.0.0.1',8893),H).serve_forever()
