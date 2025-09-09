#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/static-rooster"

echo "== Patch theme into missing pages =="
patch_one () {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "  WARN: $f missing, skipping"
    return
  fi
  if grep -q 'document.documentElement.dataset.theme' "$f"; then
    echo "  OK: theme already present -> $f"
    return
  fi
  local tmp; tmp="$(mktemp)"
  awk '
    BEGIN{ins=0}
    /<head[^>]*>/ && !ins {
      print
      print "  <script>const k=\"sr_theme\"; if(!localStorage.getItem(k)) localStorage.setItem(k,\"bocazon\"); document.documentElement.dataset.theme = localStorage.getItem(k);</script>"
      ins=1; next
    }
    {print}
  ' "$f" > "$tmp" && mv "$tmp" "$f"
  echo "  PATCHED -> $f"
}

# These were the two with the odd theme:
patch_one "forge/gate_reports/index_v0_1.html"
patch_one "decisionhub/watch_checkpoint_viewer_v0_1.html"

echo
echo "== Rebuild DecisionHub config =="
python3 ./bin/sr_cfg_rebuild.py

echo
echo "== Restart static server on 8888 =="
pkill -f "http.server 8888" >/dev/null 2>&1 || true
python3 -m http.server 8888 --directory "$PWD" >/tmp/sr.http.log 2>&1 &
sleep 0.6

echo
echo "== Health check (5/5) =="
urls=(
  "http://localhost:8888/forge/reply_builder_v0_1.html?config=/config/decisionhub.config.json"
  "http://localhost:8888/receipts/receipts_timeline_viewer_v0_1.html?index=/receipts/index_v0_1.json"
  "http://localhost:8888/forge/gate_reports/index_v0_1.html?index=/forge/gate_reports/index_v0_1.json"
  "http://localhost:8888/decisionhub/watch_checkpoint_viewer_v0_1.html?src=/receipts/sr_watch_checkpoint_v0_1.json"
  "http://localhost:8891/health"
)
for u in "${urls[@]}"; do
  code="$(curl -s -o /dev/null -w "%{http_code}" "$u")"
  printf "  %-88s -> %s\n" "$u" "$code"
done

echo
echo "== Snapshot =="
ts="$(date +%Y%m%d_%H%M%S)"
mkdir -p snapshots
snap="snapshots/sr_snapshot_${ts}.tgz"
tar --exclude='snapshots/*' -czf "$snap" .
sha256sum "$snap" | tee "${snap}.sha256"
echo "SNAP READY: $snap"
