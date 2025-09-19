#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import json, subprocess, os
ROOT=os.path.expanduser('~/static-rooster'); BIN=os.path.join(ROOT,'bin')
def run(cmd): return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False).stdout
class H(BaseHTTPRequestHandler):
    def _ok(self,obj):
        b=json.dumps(obj).encode(); self.send_response(200)
        self.send_header('content-type','application/json'); self.send_header('content-length',str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def do_POST(self):
        ln=int(self.headers.get('content-length','0') or 0); body=self.rfile.read(ln).decode() if ln else '{}'
        try: data=json.loads(body) if body.strip() else {}
        except: data={}
        p=self.path.rstrip('/')
        if p=='/make-ark':
            mode=data.get('mode','lite'); out=run([os.path.join(BIN,'sr_make_ark_v1_1.sh'), mode]); self._ok({"ok":True,"mode":mode,"output":out})
        elif p=='/copy-ark':
            out=run([os.path.join(BIN,'sr_copy_ark_link_v0_1.sh')]); self._ok({"ok":True,"url":out.strip()})
        elif p=='/push-ark':
            out=run([os.path.join(BIN,'sr_push_ark_v0_1.sh')]); self._ok({"ok":True,"pushed":out.strip()})
        else:
            self._ok({"ok":False,"error":"unknown endpoint"})
if __name__=='__main__': HTTPServer(('127.0.0.1', int(os.environ.get('ARK_PORT','8892'))), H).serve_forever()
