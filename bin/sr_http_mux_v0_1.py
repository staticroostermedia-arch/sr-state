import os, json, urllib.parse, http.server, socketserver, http.client
DOCROOT = os.path.expanduser("~/static-rooster")
UPSTREAM_HOST, UPSTREAM_PORT = "127.0.0.1", 8891  # ingest server
CORS_ALLOW="*"

class MuxHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Serve files from DOCROOT (not cwd)
        path = path.split('?',1)[0].split('#',1)[0]
        path = os.path.normpath(urllib.parse.unquote(path))
        words = [w for w in path.split('/') if w]
        p = DOCROOT
        for w in words: p = os.path.join(p,w)
        return p

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", CORS_ALLOW)
        self.send_header("Access-Control-Allow-Headers", "content-type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204); self.end_headers()

    def _proxy(self, method):
        # /ingest/<rest> → http://127.0.0.1:8891/<rest>
        rest = self.path[len("/ingest"):] or "/"
        length = int(self.headers.get("Content-Length","0") or 0)
        body = self.rfile.read(length) if length else None
        conn = http.client.HTTPConnection(UPSTREAM_HOST, UPSTREAM_PORT, timeout=30)
        headers = {k:v for k,v in self.headers.items() if k.lower()!="host"}
        try:
            conn.request(method, rest, body=body, headers=headers)
            r = conn.getresponse()
            data = r.read()
            self.send_response(r.status)
            # pass through minimal headers
            ct = r.getheader("Content-Type") or "application/octet-stream"
            self.send_header("Content-Type", ct)
            self.end_headers()
            self.wfile.write(data)
        finally:
            conn.close()

    def do_GET(self):
        if self.path.startswith("/ingest/"): return self._proxy("GET")
        return super().do_GET()

    def do_POST(self):
        if self.path.startswith("/ingest/"): return self._proxy("POST")
        return super().do_POST()

if __name__ == "__main__":
    os.chdir(DOCROOT)
    with socketserver.TCPServer(("0.0.0.0", 8888), MuxHandler) as httpd:
        httpd.serve_forever()
