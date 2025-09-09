#!/usr/bin/env bash
set -euo pipefail

SR="${HOME}/static-rooster"
ARKDIR="$(mktemp -d "${SR}/ark_XXXX")"
STAMP="$(date -u +%Y%m%d_%H%M%S)"
OUT="${SR}/snapshots/sr_ark_${STAMP}.zip"

say(){ printf '\n--- %s ---\n' "$*"; }

mkdir -p "$ARKDIR"/{configs,viewers,indexes,logs,services,bin,probe,trees}

say "System & tool versions"
{
  echo "# system"
  uname -a || true
  command -v lsb_release >/dev/null 2>&1 && lsb_release -ds || true
  echo "# tools"
  python3 -V || true
  node -v 2>/dev/null || true
  jq --version 2>/dev/null || true
  curl --version | head -n1 || true
  systemctl --user --version 2>/dev/null | head -n1 || true
} > "$ARKDIR/probe/sr_env.txt"

say "Ports"
{
  ss -ltnp 2>/dev/null | grep -E ':(8888|8890|8891)\b' || true
  echo "--- lsof ---"
  lsof -i -P -n 2>/dev/null | grep -E ':(8888|8890|8891)\b' || true
} > "$ARKDIR/probe/ports.txt"

say "Copy configs (with secret scrubbing)"
if [ -f "${SR}/config/decisionhub.config.json" ]; then
  # scrub obvious tokens/passwords
  sed -E 's/("(token|password|secret|GITHUB_TOKEN)"\s*:\s*")([^"]+)"/\1[REDACTED]"/g' \
    "${SR}/config/decisionhub.config.json" > "$ARKDIR/configs/decisionhub.config.json"
fi
cp -f "${SR}"/config/decisionhub.config.backup.*.json "$ARKDIR/configs/" 2>/dev/null || true

say "Copy viewer HTMLs"
cp -f "${SR}"/decisionhub/start_here_v0_2.html                     "$ARKDIR/viewers/" 2>/dev/null || true
cp -f "${SR}"/forge/reply_builder_v0_1.html                        "$ARKDIR/viewers/" 2>/dev/null || true
cp -f "${SR}"/receipts/receipts_timeline_viewer_v0_1.html          "$ARKDIR/viewers/" 2>/dev/null || true
cp -f "${SR}"/forge/gate_reports/index_v0_1.html                   "$ARKDIR/viewers/" 2>/dev/null || true
cp -f "${SR}"/decisionhub/watch_checkpoint_viewer_v0_1.html        "$ARKDIR/viewers/" 2>/dev/null || true

say "Copy indexes & latest receipts"
cp -f "${SR}/receipts/index_v0_1.json"                             "$ARKDIR/indexes/" 2>/dev/null || true
cp -f "${SR}"/receipts/sr_watch_checkpoint_*_v0_1.json             "$ARKDIR/indexes/" 2>/dev/null || true
cp -f "${SR}/forge/gate_reports/index_v0_1.json"                   "$ARKDIR/indexes/" 2>/dev/null || true

say "Copy service units & logs"
cp -f "${HOME}/.config/systemd/user/sr-ingest.service"             "$ARKDIR/services/" 2>/dev/null || true
cp -f "${HOME}/.config/systemd/user/sr-runner.service"             "$ARKDIR/services/" 2>/dev/null || true
cp -f "${SR}/logs/"*                                               "$ARKDIR/logs/"     2>/dev/null || true

say "Copy important scripts"
cp -f "${SR}/bin/sr_ingest_server.sh"                              "$ARKDIR/bin/" 2>/dev/null || true
cp -f "${SR}/bin/sr_ingest_server.py"                              "$ARKDIR/bin/" 2>/dev/null || true
cp -f "${SR}/bin/sr_cfg_rebuild.py"                                "$ARKDIR/bin/" 2>/dev/null || true
cp -f "${SR}/bin/sr_hub_health.sh"                                 "$ARKDIR/bin/" 2>/dev/null || true
cp -f "${SR}/bin/sr_git_diag.sh"                                   "$ARKDIR/bin/" 2>/dev/null || true

say "Health probes (page + JSON targets)"
base="http://localhost:8888"
{
  echo "# reply_builder page + cfg"
  curl -s -o /dev/null -w "page=%{http_code}\n" \
    "$base/forge/reply_builder_v0_1.html?config=/config/decisionhub.config.json"
  curl -s -o /dev/null -w "json=%{http_code}\n" \
    "$base/config/decisionhub.config.json"

  echo "# receipts timeline page + index"
  curl -s -o /dev/null -w "page=%{http_code}\n" \
    "$base/receipts/receipts_timeline_viewer_v0_1.html?index=/receipts/index_v0_1.json"
  curl -s -o /dev/null -w "json=%{http_code}\n" \
    "$base/receipts/index_v0_1.json"

  echo "# gate reports page + index"
  curl -s -o /dev/null -w "page=%{http_code}\n" \
    "$base/forge/gate_reports/index_v0_1.html?index=/forge/gate_reports/index_v0_1.json"
  curl -s -o /dev/null -w "json=%{http_code}\n" \
    "$base/forge/gate_reports/index_v0_1.json"

  echo "# watch checkpoint page + sample src"
  latest="$(ls -1 ${SR}/receipts/sr_watch_checkpoint_*_v0_1.json 2>/dev/null | tail -n1 || true)"
  curl -s -o /dev/null -w "page=%{http_code}\n" \
    "$base/decisionhub/watch_checkpoint_viewer_v0_1.html?src=/receipts/$(basename "$latest" 2>/dev/null)"
  [ -n "$latest" ] && curl -s -o /dev/null -w "json=%{http_code}\n" "$base/receipts/$(basename "$latest")" || true
} > "$ARKDIR/probe/http_8888.txt"

say "Service status (sr-ingest)"
systemctl --user --no-pager -l status sr-ingest.service  > "$ARKDIR/probe/sr_ingest_status.txt" 2>&1 || true
journalctl --user -u sr-ingest.service -n 400 --no-pager > "$ARKDIR/probe/sr_ingest_journal.txt" 2>&1 || true

say "Directory trees"
( cd "$SR" && find . -maxdepth 3 -type f | sort ) > "$ARKDIR/trees/files_flat.txt" 2>/dev/null || true

say "Package"
cd "$(dirname "$ARKDIR")"
zip -qr "$OUT" "$(basename "$ARKDIR")"
echo "$OUT"
