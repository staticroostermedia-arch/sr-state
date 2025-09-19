from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os, datetime
DOCROOT = os.path.expanduser("~/static-rooster")
RECEIPTS = os.path.join(DOCROOT, "receipts"); os.makedirs(RECEIPTS, exist_ok=True)
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        ln = int(self.headers.get('Content-Length','0') or 0)
        body = self.rfile.read(ln) if ln else b''
        ts = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H_%M_%SZ")
        rec = {"schema":"sr.done_receipt.v0_1","tool_name":"sr_ingest_echo","status":"ok",
               "received_bytes":len(body),"path":self.path,"generated_at_utc":ts}
        with open(os.path.join(RECEIPTS,f"sr_ingest_echo_{ts}.json"),"w") as f: json.dump(rec,f,indent=2)
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
    def log_message(self,*a): pass
HTTPServer(("127.0.0.1", int(os.environ.get("PORT","8891"))), H).serve_forever()
