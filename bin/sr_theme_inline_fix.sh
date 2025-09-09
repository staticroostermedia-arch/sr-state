#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/static-rooster"

gold="decisionhub/start_here_v0_2.html"
inline="docs/staticrooster_uikit_inline_v1.css"
awk 'BEGIN{p=0} /<style>/{p=1;next} /<\/style>/{p=0} p' "$gold" > "$inline"

inject () {
  f="$1"; [[ -f "$f" ]] || { echo "MISS $f"; return; }
  cp -n "$f" "$f.bak"
  sed -i "/<\/head>/i <style data-sr-theme-inline>\n$(sed 's/[&/\]/\\&/g' "$inline")\n</style>" "$f"
  echo "inlined theme -> $f"
}
inject forge/gate_reports/index_v0_1.html
inject decisionhub/watch_checkpoint_viewer_v0_1.html

python3 ./bin/sr_cfg_rebuild.py
pkill -f "http.server 8888" >/dev/null 2>&1 || true
python3 -m http.server 8888 --directory "$PWD" >/tmp/sr.http.log 2>&1 & sleep 1
echo "Hard-refresh the two pages (Ctrl+F5)."
