from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os, datetime, io

DOCROOT = os.path.expanduser("~/static-rooster")
RECEIPTS = os.path.join(DOCROOT, "receipts")
CHATDIR  = os.path.join(RECEIPTS, "chat")
os.makedirs(RECEIPTS, exist_ok=True)
os.makedirs(CHATDIR, exist_ok=True)

def utc(): return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H_%M_%SZ")

class H(BaseHTTPRequestHandler):
    def _write_json(self, obj, path):
        with open(path, "w") as f: json.dump(obj, f, indent=2)

    def do_POST(self):
        n = int(self.headers.get("Content-Length","0") or 0)
        raw = self.rfile.read(n) if n else b""
        body_text = ""
        body_json = None
        try:
            body_text = raw.decode("utf-8", errors="replace")
            body_json = json.loads(body_text)
        except Exception:
            pass

        ts = utc()
        if self.path.startswith("/chat"):
            # write a rich chat receipt
            rec = {
                "schema":"sr.chat_message.v0_1",
                "generated_at_utc": ts,
                "tool_name":"sr_ingest_echo",
                "status":"ok",
                "path": self.path,
                "headers": dict(self.headers),
                "text": body_text,
                "json": body_json
            }
            p = os.path.join(CHATDIR, f"chat_{ts}.json")
            self._write_json(rec, p)
            # keep a latest pointer for easy reading
            self._write_json({"latest": p, "ts": ts}, os.path.join(CHATDIR, "latest_context.json"))
            self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
            return

        # default /build echo as before, but include body length + preview
        rec = {
            "schema":"sr.done_receipt.v0_1",
            "tool_name":"sr_ingest_echo",
            "status":"ok",
            "generated_at_utc": ts,
            "path": self.path,
            "received_bytes": len(raw),
            "preview": body_text[:256]
        }
        self._write_json(rec, os.path.join(RECEIPTS, f"sr_ingest_echo_{ts}.json"))
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok")

    def log_message(self, *args): pass

def run():
    import sys
    port = int(os.environ.get("PORT","8891"))
    HTTPServer(("0.0.0.0", port), H).serve_forever()

if __name__ == "__main__": run()
