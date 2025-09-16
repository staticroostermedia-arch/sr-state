#!/usr/bin/env sh
# sr_toolgen_v0_1.sh — spec -> HTML generator (minimal, deterministic, POSIX sh)
set -eu
SPEC="$1"  # path to .yaml
ROOT="${HOME}/static-rooster"
FORGE="${ROOT}/forge"
mkdir -p "$FORGE"

# naive parse (expects simple 'key: value' per line for these fields)
get(){ awk -F':' -v k="$1" '$1==k {sub(/^[ ]+/,"",$2); gsub(/^[ ]+/,"",$2); print $2; exit}' "$SPEC"; }
KEY="$(get key || true)"
NAME="$(get name || true)"
VERSION="$(get version || true)"

# fallbacks
if [ -z "${KEY:-}" ]; then
  # derive from name
  KEY="$(printf "%s" "${NAME:-tool}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-z0-9_')"
fi
if [ -z "${VERSION:-}" ]; then VERSION="0.1.0"; fi
BADGE="$(printf "%s" "$VERSION")"
VER_U="$(printf "%s" "$VERSION" | tr '.' '_' )"

FILENAME="${KEY}_v${VER_U}.html"
OUT="$FORGE/$FILENAME"

cat > "$OUT" <<HTML
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${NAME:-$KEY}</title>
<style>:root{--bg:#0b0c06;--grid:#1a2b1a;--text:#b4ffb4;--glow:#39ff14}
html,body{margin:0;background:var(--bg);color:var(--text);font-family:ui-monospace,Consolas,monospace}
.header{display:flex;justify-content:space-between;align-items:center;padding:10px;border-bottom:1px solid var(--grid)}
.badge{border:1px solid var(--grid);padding:2px 8px;border-radius:999px}
.main{padding:12px}
.tile{border:1px solid var(--grid);border-radius:12px;padding:10px;margin:10px 0;background:#0f140f}
.btn{border:1px solid var(--grid);padding:8px 10px;border-radius:10px;background:#101a10;color:var(--text);cursor:pointer}
pre{white-space:pre-wrap}
</style>
<div class="header"><div>${NAME:-$KEY}</div><div class="badge">v${BADGE}</div></div>
<div class="main">
  <div class="tile">
    <h3 style="margin:0">QuickCheck</h3>
    <button id="qc" class="btn">Run QuickCheck</button>
    <pre id="log">ready…</pre>
  </div>
  <div class="tile">
    <h3 style="margin:0">Actions</h3>
    <button id="action" class="btn">Do Action</button>
  </div>
</div>
<script>
(function(){
  function emit(type,payload){ parent && parent.postMessage({type:type,toolKey:"${KEY}",payload:payload||{},version:"${BADGE}"},"*"); }
  // ready
  setTimeout(()=>emit("ready",{ok:true,version:"${BADGE}"}), 100);
  // wire actions
  document.getElementById('qc').onclick = function(){
    const secure = window.isSecureContext===true;
    const httpok = /^(http|https)$/.test(location.protocol.replace(':',''));
    const rpt = {schema:"eh1003006.dh.health.v1", generatedAt:new Date().toISOString(),
                 status:(secure&&httpok)?"ok":"warn",
                 checks:[{name:"secure-context",ok:secure},{name:"http(s)",ok:httpok}]};
    document.getElementById('log').textContent = JSON.stringify(rpt,null,2);
    emit("status",{ok:true,notes:"qc"});
  };
  document.getElementById('action').onclick = function(){
    emit("capture",{ok:true,what:"action"});
  };
  window.addEventListener('error', e=>emit("error",{message:String(e&&e.message||'error')}));
})();
</script>
HTML

echo "$OUT"
