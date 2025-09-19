from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os, datetime, glob, subprocess, shlex

DOCROOT = os.path.expanduser("~/static-rooster")
RECEIPTS = os.path.join(DOCROOT, "receipts")
CHATDIR  = os.path.join(RECEIPTS, "chat")
SHARE    = os.path.join(DOCROOT, "share")
CTX      = os.path.join(SHARE, "context")
SNAP     = os.path.join(DOCROOT, "snapshots")
ARKDIR   = os.path.join(SHARE, "ark")
os.makedirs(RECEIPTS, exist_ok=True)
os.makedirs(CHATDIR,  exist_ok=True)
os.makedirs(CTX,      exist_ok=True)
os.makedirs(SNAP,     exist_ok=True)
os.makedirs(ARKDIR,   exist_ok=True)

def utc(): return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H_%M_%SZ")

def most_recent(n=50):
    files = sorted(glob.glob(os.path.join(RECEIPTS, "sr_*_*.json")), reverse=True)
    out=[]
    for p in files[:n]:
        try:
            with open(p) as f: j=json.load(f)
            out.append({"path": p.replace(DOCROOT,""), "summary": j.get("summary",""), "generated_at_utc": j.get("generated_at_utc")})
        except: out.append({"path": p.replace(DOCROOT,""), "summary": "", "generated_at_utc": None})
    return out

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

def make_ark(mode="lite"):
    ts = utc()
    snapdir = os.path.join(SNAP, ts); os.makedirs(snapdir, exist_ok=True)
    if mode == "full":
        out = os.path.join(snapdir, "ark_full.tgz")
        cmd = f"tar -czf {shlex.quote(out)} -C {shlex.quote(DOCROOT)} ."
    else:
        include = [p for p in ["config","forge","decisionhub","receipts","share"] if os.path.exists(os.path.join(DOCROOT,p))]
        out = os.path.join(snapdir, "ark_lite.tgz")
        inc = " ".join(shlex.quote(p) for p in include)
        cmd = f"tar -czf {shlex.quote(out)} -C {shlex.quote(DOCROOT)} {inc}"
    subprocess.run(cmd, shell=True, check=True, timeout=180)
    # publish pointers
    latest_tgz = os.path.join(ARKDIR, "latest.tgz")
    try:
        if os.path.islink(latest_tgz) or os.path.exists(latest_tgz): os.remove(latest_tgz)
    except: pass
    os.link(out, latest_tgz) if os.path.samefile(os.path.dirname(out), os.path.dirname(latest_tgz)) else subprocess.run(f"cp -f {shlex.quote(out)} {shlex.quote(latest_tgz)}", shell=True, check=True)
    rel_out = "/" + os.path.relpath(out, DOCROOT)
    size_b = os.path.getsize(latest_tgz) if os.path.exists(latest_tgz) else None
    latest = {"schema":"sr.ark.latest.v0_1","generated_at_utc":ts,"mode":mode,"path":"/share/ark/latest.tgz","source":rel_out,"size_bytes":size_b,"size_mb": (round(size_b/1048576,2) if size_b is not None else None)}
    with open(os.path.join(ARKDIR,"latest.json"),"w") as f: json.dump(latest,f,indent=2)
    with open(os.path.join(RECEIPTS, f"sr_done_receipt_make_ark_{ts}.json"),"w") as f:
        json.dump({"schema":"sr.done_receipt.v0_1","tool_name":"sr_make_ark","status":"ok","generated_at_utc":ts,"summary":latest["path"]}, f, indent=2)
    return latest

class H(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "content-type")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS, GET")

    def do_OPTIONS(self): self.send_response(204); self._cors(); self.end_headers()

    def do_GET(self):
        # Serve ark manifest (static also serves this)
        if self.path.startswith("/ark/latest.json"):
            p = os.path.join(ARKDIR,"latest.json")
            self.send_response(200 if os.path.exists(p) else 404); self._cors(); self.end_headers()
            if os.path.exists(p): self.wfile.write(open(p,"rb").read()); return
        if self.path.startswith("/ark/latest.tgz"):
            p = os.path.join(ARKDIR,"latest.tgz")
            self.send_response(200 if os.path.exists(p) else 404); self._cors()
            self.send_header("Content-Type","application/gzip")
            self.end_headers()
            if os.path.exists(p): self.wfile.write(open(p,"rb").read()); return
        self.send_response(404); self._cors(); self.end_headers()

    def do_POST(self):
        n=int(self.headers.get("Content-Length","0") or 0); raw=self.rfile.read(n) if n else b""
        txt = raw.decode("utf-8","replace"); ts=utc()

        if self.path.startswith("/chat"):
            rec={"schema":"sr.chat_message.v0_1","generated_at_utc":ts,"status":"ok","path":self.path,"text":txt}
            os.makedirs(CHATDIR,exist_ok=True)
            with open(os.path.join(CHATDIR,f"chat_{ts}.json"),"w") as f: json.dump(rec,f,indent=2)
            with open(os.path.join(CHATDIR,"latest_context.json"),"w") as f: json.dump({"latest":f"/receipts/chat/chat_{ts}.json","ts":ts,"preview":txt[:240]},f,indent=2)
            write_context_latest(); self.send_response(200); self._cors(); self.end_headers(); self.wfile.write(b"ok"); return

        if self.path.startswith("/make-ark"):
            mode="lite"
            try:
                j=json.loads(txt) if txt.strip() else {}
                if isinstance(j,dict) and j.get("mode")=="full": mode="full"
            except: pass
            try:
                latest=make_ark(mode)
                b=json.dumps(latest).encode("utf-8")
                self.send_response(200); self._cors(); self.end_headers(); self.wfile.write(b); return
            except Exception as e:
                self.send_response(500); self._cors(); self.end_headers(); self.wfile.write(str(e).encode("utf-8")); return

        with open(os.path.join(RECEIPTS,f"sr_ingest_echo_{ts}.json"),"w") as f:
            json.dump({"schema":"sr.done_receipt.v0_1","generated_at_utc":ts,"status":"ok","path":self.path,"received_bytes":len(raw),"preview":txt[:240]},f,indent=2)
        write_context_latest(); self.send_response(200); self._cors(); self.end_headers(); self.wfile.write(b"ok")
    def log_message(self,*a): pass

if __name__=="__main__":
    HTTPServer(("0.0.0.0", int(os.environ.get("PORT","8891"))), H).serve_forever()
