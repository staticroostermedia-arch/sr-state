from http.server import BaseHTTPRequestHandler, HTTPServer
import os, io, cgi, time, json, zipfile, shutil, urllib.parse, re, subprocess

ROOT = os.path.expanduser('~/static-rooster')
PORT = int(os.environ.get('SR_INGEST_PORT','8891'))

def norm(name: str) -> str:
    s = name.lower()
    s = re.sub(r'[^a-z0-9._-]+','-', s)
    s = re.sub(r'-+','-', s).strip('-')
    return s or 'file'

def reply_zip_path():
    ts = time.strftime('%Y%m%d_%H%M%S', time.gmtime())
    os.makedirs(os.path.join(ROOT,'staging','reply'), exist_ok=True)
    return os.path.join(ROOT,'staging','reply', f'sr_reply_{ts}.zip')

def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path,'w') as f: json.dump(obj,f,indent=2)

def allow_cors(h):
    h.send_header('Access-Control-Allow-Origin','http://localhost:8888')
    h.send_header('Access-Control-Allow-Methods','GET,POST,OPTIONS')
    h.send_header('Access-Control-Allow-Headers','*')

class H(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(204)
        allow_cors(self); self.end_headers()

    def _ok_json(self, payload):
        data = json.dumps(payload, indent=2).encode()
        self.send_response(200); allow_cors(self)
        self.send_header('Content-Type','application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers(); self.wfile.write(data)

    def do_GET(self):
        # tiny status
        if self.path.startswith('/'):
            data = b'OK'
            self.send_response(200); allow_cors(self)
            self.send_header('Content-Type','text/plain'); self.send_header('Content-Length',str(len(data)))
            self.end_headers(); self.wfile.write(data)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == '/build':
            self.handle_build(download=('download=1' in (parsed.query or '')))
        else:
            self.send_response(404); allow_cors(self); self.end_headers()

    def handle_build(self, download=False):
        ctype, pdict = cgi.parse_header(self.headers.get('Content-Type',''))
        if ctype != 'multipart/form-data':
            self.send_response(400); allow_cors(self); self.end_headers(); return
        pdict['boundary'] = pdict['boundary'].encode()
        fs = cgi.FieldStorage(fp=self.rfile, headers=self.headers, environ={'REQUEST_METHOD':'POST','CONTENT_TYPE':self.headers.get('Content-Type')})

        notes = (fs.getfirst('notes') or '').strip()
        include_cfg = (fs.getfirst('include_config') == '1')
        apply_now = (fs.getfirst('apply_now') == '1')
        title_suffix = (fs.getfirst('title_suffix') or '').strip()

        # build a temp dir
        tmp = os.path.join(ROOT,'staging','_build_tmp'); shutil.rmtree(tmp, ignore_errors=True)
        os.makedirs(tmp, exist_ok=True)
        write_json(os.path.join(tmp,'manifest.json'), {"schema":"sr.reply_manifest.v0_1","made_at":time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),"notes":notes})
        write_json(os.path.join(tmp,'state','last_checkpoint.json'), {"schema":"sr.checkpoint.v0_1","ts":time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),"foedus":"intactum"})

        # include current config, optionally patch title
        if include_cfg:
            cfg_src = os.path.join(ROOT,'config','decisionhub.config.json')
            cfg_dst = os.path.join(tmp,'config','decisionhub.config.json')
            if os.path.exists(cfg_src):
                os.makedirs(os.path.dirname(cfg_dst), exist_ok=True)
                with open(cfg_src,'r') as f: cfg = json.load(f)
                if title_suffix:
                    t = cfg.get('title','DecisionHub')
                    if title_suffix not in t: cfg['title'] = f"{t} {title_suffix}"
                with open(cfg_dst,'w') as f: json.dump(cfg,f,indent=2)

        # handle attachments (possibly multiple)
        atts = fs['attachments'] if 'attachments' in fs else []
        if not isinstance(atts, list): atts = [atts]
        for part in atts:
            if not getattr(part, 'filename', None): continue
            rel = part.filename
            rel = '/'.join([norm(p) for p in rel.split('/')])
            dest = os.path.join(tmp, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, 'wb') as f: f.write(part.file.read())

        # make zip
        zpath = reply_zip_path()
        with zipfile.ZipFile(zpath, 'w', compression=zipfile.ZIP_DEFLATED) as z:
            for dp,_,files in os.walk(tmp):
                for fn in files:
                    ap = os.path.join(dp,fn)
                    rp = os.path.relpath(ap, tmp)
                    z.write(ap, rp)

        # if asked, apply now (best-effort)
        apply_rc = None
        if apply_now:
            sh = os.path.expanduser('~/static-rooster/bin/sr_reply_apply.sh')
            if os.path.exists(sh):
                try:
                    apply_rc = subprocess.call(['bash', sh, zpath])
                except Exception as e:
                    apply_rc = 99

        # stream the file if download=1, else JSON
        if download:
            with open(zpath,'rb') as f:
                data = f.read()
            self.send_response(200); allow_cors(self)
            self.send_header('Content-Type','application/zip')
            self.send_header('Content-Disposition','attachment; filename="sr_reply.zip"')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers(); self.wfile.write(data)
            return

        self._ok_json({"ok":True,"zip":zpath,"applied_rc":apply_rc})
