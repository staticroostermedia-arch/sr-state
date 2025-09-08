from http.server import HTTPServer, BaseHTTPRequestHandler
import cgi, os, subprocess, pathlib, time

ROOT = os.path.expanduser('~/static-rooster')
INBOX = os.path.join(ROOT,'inbox','replies')
os.makedirs(INBOX, exist_ok=True)

PAGE = b"""<!doctype html><meta charset=utf-8>
<title>Reply Dossier Ingest</title>
<body style="background:#0f172a;color:#e2e8f0;font-family:system-ui">
<h2>Upload Reply Dossier (.zip)</h2>
<form method=POST enctype=multipart/form-data>
<input type=file name=file accept=".zip">
<button type=submit>Upload</button>
</form>
<hr>
<pre>{msg}</pre>
</body>"""

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers()
        self.wfile.write(PAGE.replace(b"{msg}", b"ready"))
    def do_POST(self):
        ctype, pdict = cgi.parse_header(self.headers.get('content-type'))
        if ctype != 'multipart/form-data':
            self.send_response(400); self.end_headers(); self.wfile.write(b"bad form"); return
        fs = cgi.FieldStorage(fp=self.rfile, headers=self.headers, environ={'REQUEST_METHOD':'POST','CONTENT_TYPE':self.headers['Content-Type']})
        f = fs['file']
        if not f.filename or not f.filename.endswith('.zip'):
            self.send_response(400); self.end_headers(); self.wfile.write(b"need .zip"); return
        name = f"reply_{int(time.time())}.zip"
        dest = os.path.join(INBOX, name)
        with open(dest, 'wb') as out: out.write(f.file.read())
        # run apply
        p = subprocess.run([os.path.join(ROOT,'bin','sr_reply_apply.sh'), dest], capture_output=True, text=True)
        msg = (p.stdout + "\n" + p.stderr).strip().encode('utf-8', 'ignore')
        self.send_response(200); self.end_headers()
        self.wfile.write(PAGE.replace(b"{msg}", msg or b"ok"))

if __name__ == "__main__":
    HTTPServer(('127.0.0.1', int(__import__('os').environ.get('SR_INGEST_PORT','8891'))), H).serve_forever()
