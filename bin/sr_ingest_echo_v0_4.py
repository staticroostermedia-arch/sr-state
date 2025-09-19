from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os, datetime, glob
DOCROOT = os.path.expanduser("~/static-rooster")
RECEIPTS = os.path.join(DOCROOT, "receipts")
CHATDIR  = os.path.join(RECEIPTS, "chat")
SHARE    = os.path.join(DOCROOT, "share")
CTX      = os.path.join(SHARE, "context")
os.makedirs(RECEIPTS, exist_ok=True)
os.makedirs(CHATDIR,  exist_ok=True)
os.makedirs(CTX,      exist_ok=True)
def utc(): return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H_%M_%SZ")
def most_recent(n=50):
    files = sorted(glob.glob(os.path.join(RECEIPTS, "sr_*_*.json")), reverse=True)
    items=[]
    for p in files[:n]:
        try:
            with open(p) as f: j=json.load(f)
            items.append({"path": p.replace(DOCROOT,""), "summary": j.get("summary",""), "generated_at_utc": j.get("generated_at_utc")})
        except: items.append({"path": p.replace(DOCROOT,""), "summary":"", "generated_at_utc": None})
    return items
def write_context_latest():
    inv = sorted(glob.glob(os.path.join(RECEIPTS, "sr_inventory_*.json")), reverse=True)
    latest_inv = inv[0].replace(DOCROOT,"") if inv else None
    watch = os.path.join(RECEIPTS,"sr_watch_checkpoint_v0_1.json")
    watch_rel = watch.replace(DOCROOT,"") if os.path.exists(watch) else None
    chat_latest = os.path.join(CHATDIR,"latest_context.json")
    chat_rel = chat_latest.replace(DOCROOT,"") if os.path.exists(chat_latest) else None
    j = {"schema":"sr.context.latest.v0_1","generated_at_utc":utc(),
         "inventory":latest_inv,"watch_checkpoint":watch_rel,"last_chat":chat_rel,
         "recent_receipts":[it["path"] for it in most_recent(25)]}
    with open(os.path.join(CTX, "latest.json"),"w") as f: json.dump(j,f,indent=2)
    with open(os.path.join(CTX, "timeline.json"),"w") as f: json.dump({"schema":"sr.context.timeline.v0_1","generated_at_utc":utc(),"items":most_recent(100)},f,indent=2)
class H(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "content-type")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
    def do_OPTIONS(self): self.send_response(204); self._cors(); self.end_headers()
    def do_POST(self):
        n=int(self.headers.get("Content-Length","0") or 0); raw=self.rfile.read(n) if n else b""
        txt=raw.decode("utf-8","replace"); ts=utc()
        if self.path.startswith("/chat"):
            rec={"schema":"sr.chat_message.v0_1","generated_at_utc":ts,"status":"ok","path":self.path,"text":txt}
            os.makedirs(CHATDIR,exist_ok=True)
            with open(os.path.join(CHATDIR,f"chat_{ts}.json"),"w") as f: json.dump(rec,f,indent=2)
            with open(os.path.join(CHATDIR,"latest_context.json"),"w") as f: json.dump({"latest":f"/receipts/chat/chat_{ts}.json","ts":ts,"preview":txt[:240]},f,indent=2)
            write_context_latest(); self.send_response(200); self._cors(); self.end_headers(); self.wfile.write(b"ok"); return
        with open(os.path.join(RECEIPTS,f"sr_ingest_echo_{ts}.json"),"w") as f:
            json.dump({"schema":"sr.done_receipt.v0_1","generated_at_utc":ts,"status":"ok","path":self.path,"received_bytes":len(raw),"preview":txt[:240]},f,indent=2)
        write_context_latest(); self.send_response(200); self._cors(); self.end_headers(); self.wfile.write(b"ok")
    def log_message(self,*a): pass
if __name__=="__main__":
    HTTPServer(("0.0.0.0", int(os.environ.get("PORT","8891"))), H).serve_forever()
