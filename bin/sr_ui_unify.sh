#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/static-rooster"

echo "== ensure docs/ exists =="
mkdir -p docs

echo "== build shared CSS from Start Here (gold source) =="
gold=decisionhub/start_here_v0_2.html
if [[ ! -f "$gold" ]]; then
  echo "FATAL: $gold not found"; exit 1
fi
awk '/<style>/{f=1;next} /<\/style>/{f=0} f' "$gold" > docs/staticrooster_uikit_v1_0.css
echo "wrote docs/staticrooster_uikit_v1_0.css"

# pages that looked off
targets=(
  "forge/gate_reports/index_v0_1.html"
  "decisionhub/watch_checkpoint_viewer_v0_1.html"
)

echo "== patch theme + CSS link (added just before </head> so it wins the cascade) =="
for f in "${targets[@]}"; do
  [[ -f "$f" ]] || { echo "WARN: missing $f (skip)"; continue; }

  # Add theme init if absent
  if ! grep -q 'document.documentElement.dataset.theme' "$f"; then
    sed -i '/<\/head>/i \
  <script>const k="sr_theme";if(!localStorage.getItem(k))localStorage.setItem(k,"bocazon");document.documentElement.dataset.theme=localStorage.getItem(k);</script>' "$f"
    echo "  theme script -> $f"
  else
    echo "  theme present  -> $f"
  fi

  # Add shared CSS link (last in <head>)
  if ! grep -q 'staticrooster_uikit_v1_0.css' "$f"; then
    sed -i '/<\/head>/i \
  <link rel="stylesheet" href="/docs/staticrooster_uikit_v1_0.css">' "$f"
    echo "  css link added -> $f"
  else
    echo "  css link present -> $f"
  fi
done

echo
echo "== rebuild config & restart static server on 8888 =="
python3 ./bin/sr_cfg_rebuild.py
pkill -f "http.server 8888" >/dev/null 2>&1 || true
python3 -m http.server 8888 --directory "$PWD" >/tmp/sr.http.log 2>&1 &
sleep 0.7

echo
echo "== quick health =="
urls=(
  "http://localhost:8888/forge/reply_builder_v0_1.html?config=/config/decisionhub.config.json"
  "http://localhost:8888/receipts/receipts_timeline_viewer_v0_1.html?index=/receipts/index_v0_1.json"
  "http://localhost:8888/forge/gate_reports/index_v0_1.html?index=/forge/gate_reports/index_v0_1.json"
  "http://localhost:8888/decisionhub/watch_checkpoint_viewer_v0_1.html?src=/receipts/sr_watch_checkpoint_v0_1.json"
  "http://localhost:8891/health"
)
for u in "${urls[@]}"; do code="$(curl -s -o /dev/null -w "%{http_code}" "$u")"; printf "  %-88s -> %s\n" "$u" "$code"; done

echo
echo "== snapshot =="
ts="$(date +%Y%m%d_%H%M%S)"
mkdir -p snapshots
snap="snapshots/sr_snapshot_${ts}.tgz"
tar --exclude='snapshots/*' -czf "$snap" .
sha256sum "$snap" | tee "${snap}.sha256"
echo "SNAP READY: $snap"
