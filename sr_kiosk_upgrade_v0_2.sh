#!/bin/sh
# sr_kiosk_upgrade_v0_2.sh — Zero-hand-edit upgrade to full kiosk
# Idempotent, receipt-writing, probes for 200s.

set -eu
ROOT="${HOME}/static-rooster"
BIN="$ROOT/bin"
DH="$ROOT/decisionhub"
CFG="$ROOT/config"
RECP="$ROOT/receipts"
LOG="$ROOT/logs"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BIN" "$DH" "$CFG" "$RECP" "$LOG"

# 0) helper for receipts
receipt () {
  # receipt <status> <note> [extra_json]
  STATUS="$1"; NOTE="$2"; EXTRA="${3-}"
  printf '{"generated_at":"%s","tool":"sr_kiosk_upgrade_v0_2.sh","status":"%s","note":"%s"%s}\n' \
    "$TS" "$STATUS" "$NOTE" "${EXTRA:-}" \
    > "$RECP/sr_upgrade_receipt_kiosk_$TS.json"
}

# 1) Ensure http server systemd unit serves $ROOT
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/sr-httpd.service" <<EOF
[Unit]
Description=Static Rooster HTTP server
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8888 --directory $ROOT
WorkingDirectory=$ROOT
Restart=always

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now sr-httpd.service || true

# 2) Full kiosk HTML (chat + snapshot attach + checkpoint LED)
cat > "$DH/minimal_shell_v0_1.html" <<'HTML'
<!doctype html><html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>DecisionHub • Minimal Shell v0.1</title>
<style>
:root{--bg:#0b0c06;--grid:#1a2b1a;--text:#b4ffb4;--glow:#39ff14;--danger:#ff6b6b}
html,body{margin:0;height:100%;background:var(--bg);color:var(--text);font-family:ui-monospace,Consolas,monospace}
.bar{position:fixed;top:0;left:0;right:0;height:42px;display:flex;align-items:center;gap:8px;padding:8px 10px;background:#0f130f;border-bottom:1px solid var(--grid)}
.chip{border:1px solid var(--grid);border-radius:999px;padding:4px 10px}
.grow{flex:1}
.viewer{position:absolute;top:42px;left:0;right:0;bottom:120px;overflow:auto}
.composer{position:fixed;left:0;right:0;bottom:0;height:120px;border-top:1px solid var(--grid);background:#0f130f;padding:10px;display:grid;grid-template-columns:1fr auto;gap:10px}
textarea{width:100%;height:100%;resize:none;background:#0b0f0b;color:var(--text);border:1px solid var(--grid);border-radius:10px;padding:10px}
button{border:1px solid var(--grid);background:#101a10;color:var(--text);padding:10px 14px;border-radius:10px;cursor:pointer}
.pill{font-size:12px;padding:4px 8px}
.ok{color:var(--glow)} .err{color:var(--danger)}
</style></head><body>
  <div class="bar">
    <span class="chip">Minimal Shell v0.1</span>
    <span class="chip" id="snapshot">snapshot: …</span>
    <span class="chip" id="ckpt">checkpoint: …</span>
    <div class="grow"></div>
    <button id="fullscreen" class="pill">Fullscreen</button>
    <button id="wake" class="pill">WakeLock</button>
  </div>
  <div class="viewer">
    <div style="padding:12px">
      <h2 style="margin:0 0 8px 0;color:var(--glow)">Kiosk Chat</h2>
      <p>Posts <code>message.json</code> + latest snapshot manifest (and optional tarball) to the local ingest.</p>
      <ul>
        <li>Reads <code>/receipts/snapshot_latest.json</code></li>
        <li>Reads <code>/receipts/sr_watch_checkpoint_v0_1.json</code></li>
        <li>POST → <code>http://localhost:8891/build</code></li>
      </ul>
    </div>
  </div>
  <div class="composer">
    <textarea id="msg" placeholder="Type a message… (Ctrl+Enter to send)"></textarea>
    <div style="display:flex;flex-direction:column;gap:10px">
      <label><input type="checkbox" id="attach"> attach snapshot tarball</label>
      <button id="send">Send</button>
      <div id="status" class="chip">idle</div>
    </div>
  </div>
<script>
const SNAPSHOT_LATEST_PATH = '/receipts/snapshot_latest.json';
const CHECKPOINT_PATH = '/receipts/sr_watch_checkpoint_v0_1.json';
const INGEST_URL = localStorage.getItem('sr_ingest_url') || 'http://localhost:8891/build';
async function fetchJSON(p){ const r=await fetch(p,{cache:'no-store'}); if(!r.ok) throw new Error(r.status); return r.json(); }
async function loadSnapshotLatest(){ try{ const j=await fetchJSON(SNAPSHOT_LATEST_PATH); window._latest=j; document.getElementById('snapshot').textContent='snapshot: '+(j.path||'').split('/').pop(); }catch{ document.getElementById('snapshot').textContent='snapshot: none'; window._latest=null; } }
async function loadCheckpoint(){ try{ const j=await fetchJSON(CHECKPOINT_PATH); const v=j.verdict||'n/a'; const tag=document.getElementById('ckpt'); tag.textContent='checkpoint: '+v; tag.className='chip '+(v==='foedus_intactum'?'ok':'err'); }catch{ document.getElementById('ckpt').textContent='checkpoint: n/a'; } }
async function sendMessage(){
  const st=document.getElementById('status'); st.textContent='preparing…';
  const text=document.getElementById('msg').value.trim();
  const payload={schema:'sr.message.v0_1', when:new Date().toISOString(), text, snapshot: window._latest||null};
  const fd=new FormData();
  fd.append('message.json', new Blob([JSON.stringify(payload)],{type:'application/json'}), 'message.json');
  if(document.getElementById('attach').checked && window._latest?.path){
    st.textContent='fetching snapshot…';
    const snap=await fetch(window._latest.path,{cache:'no-store'}); if(snap.ok){ const blob=await snap.blob(); fd.append('snapshot', blob, (window._latest.path.split('/').pop()||'snapshot.tgz')); }
  }
  st.textContent='sending…';
  const res=await fetch(INGEST_URL,{method:'POST',body:fd});
  st.textContent = res.ok ? 'sent ✓' : ('error '+res.status);
  if(res.ok) document.getElementById('msg').value='';
}
document.getElementById('send').onclick=sendMessage;
document.getElementById('msg').addEventListener('keydown',e=>{ if(e.key==='Enter'&&(e.ctrlKey||e.metaKey)){ e.preventDefault(); sendMessage(); }});
document.getElementById('fullscreen').onclick=()=>document.documentElement.requestFullscreen().catch(()=>{});
let wl=null; document.getElementById('wake').onclick=async function(){ try{ if(!wl){ wl=await navigator.wakeLock.request('screen'); this.textContent='WakeLock ✓'; } else { await wl.release(); wl=null; this.textContent='WakeLock'; } }catch{} }
loadSnapshotLatest(); loadCheckpoint(); setInterval(loadCheckpoint, 5000);
</script></body></html>
HTML

# 3) Start-Here shim to avoid broken links
cat > "$DH/start_here_v0_3.html" <<'HTML'
<!doctype html><meta charset="utf-8"><title>Start Here</title>
<meta http-equiv="refresh" content="0; url=minimal_shell_v0_1.html">
<p>Redirecting to Minimal Shell v0.1…</p>
HTML

# 4) Kiosk launcher (Chromium app window, no browser chrome)
cat > "$BIN/sr_kiosk_launch_v0_1.sh" <<EOF
#!/bin/sh
set -eu
URL="http://127.0.0.1:8888/decisionhub/start_here_v0_3.html"
for c in "\${BROWSER:-}" chromium google-chrome google-chrome-stable brave-browser; do
  [ -n "\$c" ] || continue
  command -v "\$c" >/dev/null 2>&1 && B="\$c" && break || true
done
[ -n "\${B:-}" ] || { echo "No Chromium/Chrome found in PATH"; exit 1; }
exec "\$B" --app="\$URL" --user-data-dir=/tmp/sr_kiosk_profile --no-first-run --no-default-browser-check \
  --disable-extensions --disable-sync --disable-translate --disable-background-networking \
  --disable-features=Translate,AutofillServerCommunication,OptimizationHints --password-store=basic
EOF
chmod +x "$BIN/sr_kiosk_launch_v0_1.sh"

# 5) Snapshot maker that also writes snapshot_latest.json
cat > "$BIN/sr_make_state_snapshot_v0_2.sh" <<'B'
#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$ROOT/snapshots" "$ROOT/receipts"
TAR="$ROOT/snapshots/sr_snapshot_$TS.tgz"
( cd "$ROOT" && tar --exclude="snapshots/*" --exclude="quarantine/*" -czf "$TAR" decisionhub forge config receipts docs 2>/dev/null ) || true
SIZE=$(stat -c%s "$TAR" 2>/dev/null || stat -f%z "$TAR" 2>/dev/null || echo 0)
SHA=$(sha256sum "$TAR" 2>/dev/null | awk '{print $1}' || echo "")
MAN="$ROOT/snapshots/sr_snapshot_$TS.manifest.json"
printf '{"schema":"sr.snapshot.v0_1","generated_at":"%s","path":"%s","size_bytes":%s,"sha256":"%s"}\n' "$TS" "/snapshots/$(basename "$TAR")" "$SIZE" "$SHA" > "$MAN"
cp "$MAN" "$ROOT/receipts/snapshot_latest.json"
printf '{"generated_at":"%s","tool":"sr_make_state_snapshot_v0_2.sh","snapshot":"%s","manifest":"%s","status":"created"}\n' "$TS" "/snapshots/$(basename "$TAR")" "/snapshots/$(basename "$MAN")" > "$ROOT/receipts/sr_snapshot_receipt_$TS.json"
echo "snapshot → $TAR"
B
chmod +x "$BIN/sr_make_state_snapshot_v0_2.sh"

# 6) Watch checkpoint emitter (simple probes → verdict)
cat > "$BIN/sr_watch_checkpoint_emit_v0_1.sh" <<'B'
#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"; TS="$(date -u +%Y%m%dT%H%M%SZ)"
RECP="$ROOT/receipts"; mkdir -p "$RECP"
ROUTES="/ /decisionhub/start_here_v0_3.html /decisionhub/minimal_shell_v0_1.html"
probe_json="["; first=true
for r in $ROUTES; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8888${r}" || echo 000)
  $first && first=false || probe_json="$probe_json,"
  probe_json="$probe_json{\"route\":\"$r\",\"status\":$CODE}"
done; probe_json="$probe_json]"
bad=$(echo "$probe_json" | jq '[.[]|select(.status!=200)]|length' 2>/dev/null || echo 0)
verdict="foedus_intactum"; note="All probes 200"
[ "$bad" -gt 0 ] && { verdict="penitential_rite"; note="Probe failures:$bad"; }
printf '{"generated_at":"%s","schema":"sr.watch_checkpoint.v0_1","probes":%s,"verdict":"%s","note":"%s"}\n' \
  "$TS" "$probe_json" "$verdict" "$note" > "$RECP/sr_watch_checkpoint_v0_1.json"
echo "watch checkpoint → $verdict"
B
chmod +x "$BIN/sr_watch_checkpoint_emit_v0_1.sh"

# 7) Ingest server (multipart: message.json, snapshot, build_order.json)
cat > "$BIN/sr_ingest_server_v0_1.sh" <<'B'
#!/bin/sh
set -eu
python3 - <<'PY'
import http.server, socketserver, os, cgi, datetime, json
ROOT=os.path.expanduser('~/static-rooster')
OUT=os.path.join(ROOT,'ingest'); os.makedirs(OUT,exist_ok=True)
RECP=os.path.join(ROOT,'receipts'); os.makedirs(RECP,exist_ok=True)
ORD=os.path.join(ROOT,'orders'); os.makedirs(ORD,exist_ok=True)
class H(http.server.BaseHTTPRequestHandler):
  def do_POST(self):
    ctype, pd = cgi.parse_header(self.headers.get('content-type',''))
    if ctype!='multipart/form-data': self.send_response(400); self.end_headers(); return
    fs=cgi.FieldStorage(fp=self.rfile, headers=self.headers,environ={'REQUEST_METHOD':'POST'},keep_blank_values=True)
    ts=datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    rec={'generated_at':ts,'tool':'sr_ingest_server_v0_1','from':self.client_address[0],'status':'ok'}
    if 'message.json' in fs:
      m=fs['message.json'].file.read(); p=os.path.join(OUT,f'message_{ts}.json'); open(p,'wb').write(m); rec['message']=os.path.relpath(p,ROOT)
    if 'snapshot' in fs:
      s=fs['snapshot']; p=os.path.join(OUT, s.filename or f'snapshot_{ts}.tgz'); open(p,'wb').write(s.file.read()); rec['snapshot']=os.path.relpath(p,ROOT)
    if 'build_order.json' in fs:
      o=fs['build_order.json'].file.read(); p=os.path.join(ORD,f'order_{ts}.json'); open(p,'wb').write(o); rec['order']=os.path.relpath(p,ROOT)
    open(os.path.join(RECP,f'ingest_receipt_{ts}.json'),'w').write(json.dumps(rec))
    self.send_response(200); self.end_headers(); self.wfile.write(b'{"ok":true}')
PORT=8891
with socketserver.TCPServer(("",PORT), H) as httpd:
  httpd.serve_forever()
PY
B
chmod +x "$BIN/sr_ingest_server_v0_1.sh"

# 8) Probes + initial snapshot so UI has state
"$BIN/sr_make_state_snapshot_v0_2.sh" || true
"$BIN/sr_watch_checkpoint_emit_v0_1.sh" || true

# 9) Success receipt + hints
receipt "ok" "kiosk installed/updated; start_here shim, full minimal shell, launcher, snapshot+checkpoint ready." \
', "launchers": {"kiosk":"bin/sr_kiosk_launch_v0_1.sh","ingest":"bin/sr_ingest_server_v0_1.sh"}, "urls": ["/decisionhub/start_here_v0_3.html","/decisionhub/minimal_shell_v0_1.html"]'
echo "Upgrade complete."
echo "Open kiosk: $BIN/sr_kiosk_launch_v0_1.sh"
echo "Start ingest: $BIN/sr_ingest_server_v0_1.sh"
echo "Receipt: $RECP/sr_upgrade_receipt_kiosk_$TS.json"
