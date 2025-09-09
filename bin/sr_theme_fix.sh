#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/static-rooster"

echo "== ensure shared CSS =="
mkdir -p docs
gold="decisionhub/start_here_v0_2.html"
core="docs/staticrooster_uikit_v1_0.css"
if [[ ! -f "$gold" ]]; then
  echo "FATAL: $gold not found"; exit 1
fi
# extract Start Here <style> block once (gold source of truth)
awk '/<style>/{s=1;next} /<\/style>/{s=0} s' "$gold" > "$core"
echo "wrote $core"

cat > docs/ui_overrides_v1.css <<'CSS'
/* lightweight bridge so older viewers inherit the Start Here look */
html[data-theme] body{background:var(--bg-body,#0b1020);color:var(--fg,#c9d1d9)}
.wrap,.card{background:var(--bg-card,rgba(12,31,60,.6));border-radius:12px}
a,.btn{color:var(--accent,#58a6ff)}
.btn{border-color:var(--accent,#58a6ff);box-shadow:0 0 0 2px rgba(0,0,0,.15) inset}
CSS

ts="$(date +%s)"
patch_page () {
  local f="$1"
  [[ -f "$f" ]] || { echo "WARN: missing $f (skip)"; return; }
  cp -n "$f" "${f}.bak"

  # 1) ensure theme init (same as Start Here)
  if ! grep -q 'document.documentElement.dataset.theme' "$f"; then
    sed -i '/<\/head>/i \
<script>const K="sr_theme";if(!localStorage.getItem(K))localStorage.setItem(K,"bocazon");document.documentElement.dataset.theme=localStorage.getItem(K);</script>' "$f"
    echo "  theme init  -> $f"
  fi

  # 2) link shared CSS (last in <head> so it wins)
  if ! grep -q 'staticrooster_uikit_v1_0.css' "$f"; then
    sed -i "/<\/head>/i <link rel=\"stylesheet\" href=\"\/docs\/staticrooster_uikit_v1_0.css?v=$ts\">" "$f"
    echo "  core css    -> $f"
  fi
  if ! grep -q 'ui_overrides_v1.css' "$f"; then
    sed -i "/<\/head>/i <link rel=\"stylesheet\" href=\"\/docs\/ui_overrides_v1.css?v=$ts\">" "$f"
    echo "  overrides   -> $f"
  fi

  # 3) drop obvious hardcoded bg overrides that fight theme
  sed -i \
    -e '/background:\s*linear-gradient/d' \
    -e '/background:\s*radial-gradient/d' \
    -e '/background-color:\s*#[0-9a-fA-F]\{3,8\}/d' \
    "$f"

  echo "patched $f"
}

echo "== patch viewers =="
patch_page forge/gate_reports/index_v0_1.html
patch_page decisionhub/watch_checkpoint_viewer_v0_1.html

echo "== rebuild hub config & restart static server =="
python3 ./bin/sr_cfg_rebuild.py
pkill -f "http.server 8888" >/dev/null 2>&1 || true
python3 -m http.server 8888 --directory "$PWD" >/tmp/sr.http.log 2>&1 &
sleep 1

echo "== verify CSS is referenced from the pages =="
for u in \
  http://localhost:8888/forge/gate_reports/index_v0_1.html \
  http://localhost:8888/decisionhub/watch_checkpoint_viewer_v0_1.html
do
  echo "  $u"
  curl -s "$u" | grep -Eo 'docs/(staticrooster_uikit_v1_0|ui_overrides_v1)\.css[^"]*' | sed 's/^/    -> /' || true
done

echo "OK. Hard-refresh those two pages (Ctrl+F5) to bust browser cache."
