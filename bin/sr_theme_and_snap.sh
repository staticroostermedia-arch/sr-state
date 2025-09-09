#!/usr/bin/env bash
set -Eeuo pipefail
SR="${SR:-$HOME/static-rooster}"
cd "$SR"

mkdir -p docs snapshots logs

echo "== 1) shared theme =="
cat > docs/staticrooster_ukit_v1_0.css <<'CSS'
:root{
  --bg:#0b0c06; --grid:#1a2b1a; --text:#b4ffb4; --glow:#39ff14; --accent:#9ae89a;
  --warn:#ffd166; --danger:#ff6b6b; --rooster:#ff504a;
  --fs-title:clamp(15px,1.9vw,18px); --fs-small:clamp(10px,1.7vw,13px);
  --fs-chip:clamp(11px,2vw,15px); --fs-tile:clamp(13px,2.1vw,16px); --pad-tiles:clamp(8px,1.6vw,12px);
}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);color:var(--text);font-family:ui-monospace,Consolas,monospace}
.pip-chip{border:1px solid var(--grid);background:#0f140f;color:var(--text);padding:6px 10px;border-radius:999px;font-size:var(--fs-small)}
.pip-tile{border:1px solid var(--grid);border-radius:12px;background:#0f130f;padding:var(--pad-tiles)}
.pip-title{color:var(--glow);font-size:var(--fs-title);margin:0}
.pip-danger{color:var(--danger)} .pip-warn{color:var(--warn)}
a.btn{border:1px solid var(--grid);padding:8px 10px;border-radius:8px;background:#101a10;color:var(--text);text-decoration:none;font-size:var(--fs-chip)}
a.btn:hover{border-color:var(--glow);box-shadow:0 0 8px rgba(57,255,20,.2) inset}
CSS

echo "== 2) patch pages to load theme (idempotent) =="
patch_html() {
  local f="$1"
  [[ -f "$f" ]] || { echo "MISS $f"; return 0; }
  cp -n "$f" "$f.bak" 2>/dev/null || true
  # ensure meta viewport
  grep -q '<meta name="viewport"' "$f" || \
    sed -i 's#<head>#<head>\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">#' "$f"
  # ensure theme token init
  grep -q 'document.documentElement.dataset.theme' "$f" || \
    sed -i '/<\/head>/i \
<script>const K="sr_theme";if(!localStorage.getItem(K))localStorage.setItem(K,"bocazon");document.documentElement.dataset.theme=localStorage.getItem(K);</script>' "$f"
  # ensure shared css link (placed last so it wins)
  grep -q 'staticrooster_ukit_v1_0.css' "$f" || \
    sed -i '/<\/head>/i <link rel="stylesheet" href="/docs/staticrooster_ukit_v1_0.css">' "$f"
  echo "PATCHED $(realpath --relative-to="$SR" "$f")"
}

# the two that looked off:
patch_html "forge/gate_reports/index_v0_1.html"
patch_html "decisionhub/watch_checkpoint_viewer_v0_1.html"
# (optional) normalize others too:
patch_html "forge/reply_builder_v0_1.html"
patch_html "receipts/receipts_timeline_viewer_v0_1.html"

echo "== 3) restart static server :8888 =="
pkill -f "http.server 8888" >/dev/null 2>&1 || true
python3 -m http.server 8888 --directory "$SR" > /tmp/sr.http.log 2>&1 & disown
sleep 0.8

echo "== 4) health checks =="
urls=(
  "http://localhost:8888/forge/reply_builder_v0_1.html?config=/config/decisionhub.config.json"
  "http://localhost:8888/receipts/receipts_timeline_viewer_v0_1.html?index=/receipts/index_v0_1.json"
  "http://localhost:8888/forge/gate_reports/index_v0_1.html?index=/forge/gate_reports/index_v0_1.json"
  "http://localhost:8888/decisionhub/watch_checkpoint_viewer_v0_1.html?src=/receipts/sr_watch_checkpoint_v0_1.json"
  "http://localhost:8891/health"
)
for u in "${urls[@]}"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$u" || true)
  printf '  %-88s -> %s\n' "$u" "$code"
done

echo "== 5) snapshot (theme-related bits) =="
ts=$(date +%Y%m%d_%H%M%S)
SNAP="snapshots/sr_snapshot_${ts}.tgz"
tar -czf "$SNAP" \
  docs/staticrooster_ukit_v1_0.css \
  forge/gate_reports/index_v0_1.html \
  decisionhub/watch_checkpoint_viewer_v0_1.html \
  forge/reply_builder_v0_1.html \
  receipts/receipts_timeline_viewer_v0_1.html \
  config/decisionhub.config.json receipts/index_v0_1.json 2>/dev/null || true
echo "SNAP READY: $SNAP"
