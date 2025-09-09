#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/static-rooster"

OUT="snapshots/sr_theme_bundle_$(date +%Y%m%d_%H%M%S).tgz"
mkdir -p snapshots reports served

# grab what the server actually serves
python3 -m http.server 8888 --directory "$PWD" >/tmp/sr.http.log 2>&1 &
srv=$!; sleep 1
curl -fsS http://localhost:8888/decisionhub/start_here_v0_2.html \
  -o served/start_here_v0_2.html || true
curl -fsS "http://localhost:8888/forge/gate_reports/index_v0_1.html?index=/forge/gate_reports/index_v0_1.json" \
  -o served/gate_reports_index_v0_1.served.html || true
curl -fsS "http://localhost:8888/decisionhub/watch_checkpoint_viewer_v0_1.html?src=/receipts/sr_watch_checkpoint_v0_1.json" \
  -o served/watch_checkpoint_viewer_v0_1.served.html || true
kill $srv >/dev/null 2>&1 || true

# minimal git context
git status > reports/git_status.txt || true
git branch -vv > reports/git_branches.txt || true
git log --oneline --decorate -n 30 > reports/git_log.txt || true
git remote -v > reports/git_remotes.txt || true

# source files that matter for the theme
tar -czf "$OUT" \
  decisionhub/start_here_v0_2.html \
  decisionhub/watch_checkpoint_viewer_v0_1.html \
  forge/gate_reports/index_v0_1.html \
  docs/staticrooster_uikit_v1_0.css \
  docs/ui_overrides_v1.css \
  config/decisionhub.config.json \
  bin/sr_cfg_rebuild.py \
  bin/sr_theme_fix.sh \
  served/ reports/

echo "$OUT"
