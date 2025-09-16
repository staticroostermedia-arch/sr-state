#!/usr/bin/env sh
# sr_heartbeat_v0_1.sh — emit a single heartbeat receipt
set -eu
ROOT="${HOME}/static-rooster"
RCPTS="${ROOT}/receipts/heartbeats"
mkdir -p "$RCPTS"

ts="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
out="$RCPTS/sr_heartbeat_${ts}.json"

# lightweight stats
du_bytes() { { du -sb "$1" 2>/dev/null || gdu -sb "$1" 2>/dev/null; } | awk '{print $1+0}'; }
count_files() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' '; }

root_bytes="$(du_bytes "$ROOT" 2>/dev/null || echo 0)"
docs_cnt="$(count_files "$ROOT/docs" 2>/dev/null || echo 0)"
cfg_cnt="$(count_files "$ROOT/config" 2>/dev/null || echo 0)"
bin_cnt="$(count_files "$ROOT/bin" 2>/dev/null || echo 0)"
forge_cnt="$(count_files "$ROOT/forge" 2>/dev/null || echo 0)"
rcpt_cnt="$(count_files "$ROOT/receipts" 2>/dev/null || echo 0)"
snap_cnt="$(count_files "$ROOT/snapshots" 2>/dev/null || echo 0)"

branch=""
if [ -d ".git" ]; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
fi

last_bundle="$(ls -1t "$ROOT/ark/exports"/ark_bundle_* 2>/dev/null | head -n1 || true)"
last_snapshot="$(ls -1t "$ROOT"/snapshots/*.tgz 2>/dev/null | head -n1 || true)"
webhook="${HEARTBEAT_WEBHOOK:-}"
web_status=""
payload="$(mktemp)"
cat > "$payload" <<EOF
{
  "schema":"sr.heartbeat.v0_1",
  "generated_at_utc":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "root_bytes": $root_bytes,
  "counts": {"docs": $docs_cnt, "config": $cfg_cnt, "bin": $bin_cnt, "forge": $forge_cnt, "receipts": $rcpt_cnt, "snapshots": $snap_cnt },
  "git_branch": "$(printf "%s" "$branch")",
  "last_bundle": "$(printf "%s" "$last_bundle")",
  "last_snapshot": "$(printf "%s" "$last_snapshot")"
}
EOF

# optional webhook post
if [ -n "$webhook" ]; then
  web_status="$(curl -sS -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" --data-binary "@$payload" "$webhook" || echo "error")"
fi

# write final heartbeat (include webhook result if any)
{
  printf '{\n'
  printf '  "schema":"sr.heartbeat.v0_1",\n'
  printf '  "generated_at_utc":"%s",\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '  "root_bytes": %s,\n' "$root_bytes"
  printf '  "counts": {"docs": %s, "config": %s, "bin": %s, "forge": %s, "receipts": %s, "snapshots": %s},\n' "$docs_cnt" "$cfg_cnt" "$bin_cnt" "$forge_cnt" "$rcpt_cnt" "$snap_cnt"
  printf '  "git_branch": "%s",\n' "$branch"
  printf '  "last_bundle": "%s",\n' "$last_bundle"
  printf '  "last_snapshot": "%s",\n' "$last_snapshot"
  printf '  "webhook_status": "%s"\n' "$web_status"
  printf '}\n'
} > "$out"
ln -sfn "$out" "$RCPTS/latest.json"
echo "Heartbeat: $out"
