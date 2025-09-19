#!/bin/sh
# sr_kiosk_chat_enable_v0_1.sh — bring the kiosk fully to life
# Idempotent, receipt-writing, minimal dependencies.

set -eu
ROOT="${HOME}/static-rooster"
BIN="$ROOT/bin"
CFG="$ROOT/config"
DH="$ROOT/decisionhub"
FORGE="$ROOT/forge"
RECP="$ROOT/receipts"
LOG="$ROOT/logs"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BIN" "$CFG" "$DH" "$FORGE" "$RECP" "$LOG"

# ----- helper: write a receipt -----
receipt () {
  STATUS="$1"; NOTE="$2"; EXTRA="${3-}"
  printf '{"generated_at":"%s","tool":"sr_kiosk_chat_enable_v0_1.sh","status":"%s","note":"%s"%s}\n' \
    "$TS" "$STATUS" "$NOTE" "${EXTRA:-}" > "$RECP/sr_done_receipt_kiosk_chat_enable_$TS.json"
}

# ----- 1) Kiosk chat tool (DecisionHub -> /forge/kiosk_chat_v0_1.html) -----
cat > "$FORGE/kiosk_chat_v0_1.html" <<'HTML'
<!doctype html><html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Kiosk Chat v0.1</title>
<style>
:root{--bg:#0b0c06;--grid:#1a2b1a;--text:#b4ffb4;--ok:#39ff14;--err:#ff6b6b}
html,body{margin:0;height:100%;background:var(--bg);color:var(--text);font-family:ui-monospace,Consolas,monospace}
.bar{position:fixed;top:0;left:0;right:0;height:46px;display:flex;align-items:center;gap:8px;padding:8px 10px;background:#0f130f;border-bottom:1px solid var(--grid)}
.chip{border:1px solid var(--grid);border-radius:999px;padding:4px 10px}
.grow{flex:1}
.viewer{position:absolute;top:46px;left:0;right:0;bottom:124px;overflow:auto}
.composer{position:fixed;left:0;right:0;bottom:0;height:124px;border-top:1px solid var(--grid);background:#0f130f;padding:10px;display:grid;grid-template-columns:1fr auto;gap:10px}
textarea{width:100%;height:100%;resize:none;background:#0b0f0b;color:var(--text);border:1px solid var(--grid);border-radius:10px;padding:10px}
button{border:1px solid var(--grid);background:#101a10;color:var(--text);padding:10px 14px;border-radius:10px;cursor:pointer}
.pill{font-size:12px;padding:4px 8px}
.ok{color:var(--ok)} .err{color:var(--err)}
pre{white-space:pre-wrap;word-wrap:break-word;margin:0;padding:12px}
</style></head><body>
  <div class="bar">
    <span class="chip">Kiosk Chat v0.1</span>
    <span class="chip" id="snapshot">snapshot: …</span>
    <span class="chip" id="ckpt">checkpoint: …</span>
    <div class="grow"></div>
    <button id="ping" class="pill">Send ping</button>
    <button id="fullscreen" class="pill">Fullscreen</button>
    <button id="wake" class="pill">WakeLock</button>
  </div>
  <div class="viewer">
    <pre id="log">Ready. Messages will POST to http://localhost:8891/build and write receipts under ~/static-rooster/receipts/</pre>
  </div>
  <div class="composer">
    <textarea id="msg" placeholder="Type a message… (Ctrl/Cmd+Enter to send)"></textarea>
    <div style="display:flex;flex-direction:column;gap:8px">
      <label><input type="checkbox" id="attach"> attach full snapshot tarball</label>
      <button id="send">Send</button>
      <div id="status" class="chip">idle</div>
    </div>
  </div>
<script>
const SNAPSHOT_LATEST_PATH = '/receipts/snapshot_latest.json';
const CHECKPOINT_PATH = '/receipts/sr_watch_checkpoint_v0_1.json';
const INGEST_URL = 'http://localhost:8891/build';

function log(line){ const el=document.getElementById('log'); el.textContent += "\n" + line; el.scrollTop = el.scrollHeight; }

async function fetchJSON(url){
  const res = await fetch(url,{cache:'no-store'}); if(!res.ok) throw new Error(url+" → "+res.status); return res.json();
}

async function refreshSnapshot(){
  try{ const j = await fetchJSON(SNAPSHOT_LATEST_PATH);
       window._latest = j;
       document.getElementById('snapshot').textContent = 'snapshot: '+(j.path||'none').split('/').pop();
  }catch(e){ window._latest=null; document.getElementById('snapshot').textContent='snapshot: none'; }
}

async function refreshCheckpoint(){
  try{ const j = await fetchJSON(CHECKPOINT_PATH);
       const v = j.verdict || 'n/a';
       const chip = document.getElementById('ckpt');
       chip.textContent = 'checkpoint: ' + v;
       chip.className = 'chip ' + (v==='foedus_intactum' ? 'ok' : 'err');
  }catch(e){ document.getElementById('ckpt').textContent='checkpoint: n/a'; }
}

async function sendMessage(text){
  const status = document.getElementById('status');
  status.textContent = 'preparing…';
  const payload = { schema:'sr.message.v0_1', when:new Date().toISOString(), text, snapshot: window._latest||null };
  const fd = new FormData();
  fd.append('message.json', new Blob([JSON.stringify(payload)],{type:'application/json'}), 'message.json');

  if(document.getElementById('attach').checked && window._latest?.path){
    status.textContent = 'fetching snapshot…';
    const res = await fetch(window._latest.path,{cache:'no-store'});
    if(res.ok){ const blob = await res.blob(); const name = (window._latest.path.split('/').pop()||'snapshot.tgz'); fd.append('snapshot', blob, name); }
  }

  status.textContent = 'sending…';
  const r = await fetch(INGEST_URL,{method:'POST', body:fd});
  status.textContent = r.ok ? 'sent ✓' : ('error '+r.status);
  log(r.ok ? '→ sent ok' : '→ error '+r.status);
  if(r.ok) document.getElementById('msg').value = '';
}

document.getElementById('send').onclick = ()=>sendMessage(document.getElementById('msg').value.trim());
document.getElementById('msg').addEventListener('keydown',(e)=>{ if(e.key==='Enter'&&(e.ctrlKey||e.metaKey)){ e.preventDefault(); sendMessage(document.getElementById('msg').value.trim()); }});
document.getElementById('ping').onclick = ()=>sendMessage('ping from kiosk');
document.getElementById('fullscreen').onclick = ()=>document.documentElement.requestFullscreen().catch(()=>{});
let wl=null; document.getElementById('wake').onclick = async function(){ try{ if(!wl){ wl=await navigator.wakeLock.request('screen'); this.textContent='WakeLock ✓'; } else { await wl.release(); wl=null; this.textContent='WakeLock'; } }catch{} }

refreshSnapshot(); refreshCheckpoint(); setInterval(refreshCheckpoint,5000);
</script>
</body></html>
HTML

# ----- 2) DecisionHub tile (add if missing) -----
mkdir -p "$CFG"
CONF="$CFG/decisionhub_config.json"
if [ ! -f "$CONF" ]; then
  cat > "$CONF" <<'JSON'
{ "title":"DecisionHub - Start Here", "items":[
  {"key":"kiosk_chat","name":"Kiosk Chat","badge":"v0.1.0","route":"/forge/kiosk_chat_v0_1.html"}
]}
JSON
else
  if command -v jq >/dev/null 2>&1; then
    tmp="$CONF.tmp"
    jq '.items += [{"key":"kiosk_chat","name":"Kiosk Chat","badge":"v0.1.0","route":"/forge/kiosk_chat_v0_1.html"}] | (.items |= unique_by(.key))' "$CONF" > "$tmp" && mv "$tmp" "$CONF" || true
  else
    # simple append if jq not available and tile key absent
    grep -q '"kiosk_chat"' "$CONF" || sed -i 's#"items":[#&{"key":"kiosk_chat","name":"Kiosk Chat","badge":"v0.1.0","route":"/forge/kiosk_chat_v0_1.html"},#' "$CONF"
  fi
fi

# ----- 3) Ingest server (multipart endpoint :8891) -----
cat > "$BIN/sr_ingest_server_v0_1.sh" <<'PYRUN'
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
PYRUN
chmod +x "$BIN/sr_ingest_server_v0_1.sh"

# ----- 4) Snapshot maker (writes snapshot_latest.json) -----
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

# ----- 5) Start-here shim (optional) and kiosk launcher -----
cat > "$DH/start_here_v0_3.html" <<'H'
<!doctype html><meta charset="utf-8"><title>Start Here</title>
<meta http-equiv="refresh" content="0; url=/forge/kiosk_chat_v0_1.html">
<p>Redirecting to Kiosk Chat…</p>
H

cat > "$BIN/sr_kiosk_launch_v0_1.sh" <<'L'
#!/bin/sh
set -eu
URL="http://127.0.0.1:8888/decisionhub/start_here_v0_3.html"
for c in "${BROWSER:-}" chromium google-chrome google-chrome-stable brave-browser; do
  [ -n "$c" ] || continue
  command -v "$c" >/dev/null 2>&1 && B="$c" && break || true
done
[ -n "${B:-}" ] || { echo "No Chromium/Chrome found"; exit 1; }
exec "$B" --app="$URL" --user-data-dir=/tmp/sr_kiosk_profile --no-first-run --no-default-browser-check \
  --disable-extensions --disable-sync --disable-translate --disable-background-networking \
  --disable-features=Translate,AutofillServerCommunication,OptimizationHints --password-store=basic
L
chmod +x "$BIN/sr_kiosk_launch_v0_1.sh"

# ----- 6) Make initial snapshot so the UI has state -----
"$BIN/sr_make_state_snapshot_v0_2.sh" || true

# ----- 7) Probe: verify the tool is served (HTTP 200) -----
# Ensure python http.server is running (user may already have a systemd unit)
PIDF="$ROOT/.httpd_pid"
if ! curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8888/ | grep -qE '^(200|301|302)$'; then
  ( cd "$ROOT" && python3 -m http.server 8888 >"$LOG/httpd.log" 2>&1 & echo $! > "$PIDF" )
  sleep 0.5
fi
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8888/forge/kiosk_chat_v0_1.html || echo 000)

# ----- 8) Final receipt -----
receipt "ok" "kiosk tool installed; tile ensured; ingest+snapshot scripts present; probe /forge/kiosk_chat_v0_1.html=$CODE" \
", \"http_status\": $CODE, \"tile\": \"/forge/kiosk_chat_v0_1.html\", \"launchers\": {\"kiosk\":\"bin/sr_kiosk_launch_v0_1.sh\",\"ingest\":\"bin/sr_ingest_server_v0_1.sh\"}"
echo "Kiosk Chat installed. Probe HTTP=$CODE"
echo "Launch kiosk: $BIN/sr_kiosk_launch_v0_1.sh"
echo "Start ingest: $BIN/sr_ingest_server_v0_1.sh"
echo "Receipt: $RECP/sr_done_receipt_kiosk_chat_enable_$TS.json"
