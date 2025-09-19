#!/bin/sh
set -eu
: "${OPENAI_API_KEY:?set OPENAI_API_KEY first (sk-...)}"
python3 - <<'PY'
import http.server, socketserver, os, json, datetime, urllib.request
KEY=os.environ['OPENAI_API_KEY']; ROOT=os.path.expanduser('~/static-rooster'); REC=os.path.join(ROOT,'receipts'); os.makedirs(REC,exist_ok=True)
def ask(q, snap=None):
  data=json.dumps({"model":"gpt-4o-mini","messages":[{"role":"system","content":"You are Static Rooster build steward."},{"role":"user","content":q if not snap else q+"\n\n[latest snapshot]\\n"+json.dumps(snap)[:4000]}],"temperature":0.2}).encode()
  req=urllib.request.Request('https://api.openai.com/v1/chat/completions',data=data,headers={'Authorization':f'Bearer {KEY}','Content-Type':'application/json'})
  with urllib.request.urlopen(req,timeout=60) as r: return json.loads(r.read().decode())['choices'][0]['message']['content']
class H(http.server.BaseHTTPRequestHandler):
  def do_POST(self):
    if self.path!="/ask": self.send_response(404); self.end_headers(); return
    L=int(self.headers.get('content-length','0')); body=self.rfile.read(L) if L else b'{}'; data=json.loads(body or b'{}')
    q=data.get('q','(empty)')
    snap=None
    try:
      snap=json.load(open(os.path.join(ROOT,'receipts','snapshot_latest.json')))
    except Exception: pass
    ts=datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    try:
      reply=ask(q,snap); open(os.path.join(REC,f'llm_reply_{ts}.json'),'w').write(json.dumps({"generated_at":ts,"tool":"sr_llm_relay_v0_1","status":"ok","q":q,"reply":reply}))
      self.send_response(200); self.end_headers(); self.wfile.write(json.dumps({"ok":True,"reply":reply}).encode())
    except Exception as e:
      open(os.path.join(REC,f'llm_reply_{ts}.json'),'w').write(json.dumps({"generated_at":ts,"tool":"sr_llm_relay_v0_1","status":"error","error":str(e)}))
      self.send_response(500); self.end_headers(); self.wfile.write(json.dumps({"ok":False,"error":str(e)}).encode())
PORT=8892
with socketserver.TCPServer(("127.0.0.1",PORT), H) as httpd: httpd.serve_forever()
PY
