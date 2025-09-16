#!/usr/bin/env bash
# sr_emit_heartbeat_v0_2.sh — write/update latest heartbeat json
set -eu
ROOT="${HOME}/static-rooster"
RC="$ROOT/receipts/heartbeats"; mkdir -p "$RC"
latest="$RC/latest.json"

bytes="$(du -sb "$ROOT" | awk '{print $1}')"
docs="$(find "$ROOT/docs" -type f 2>/dev/null | wc -l | tr -d ' ')"
binf="$(find "$ROOT/bin" -type f 2>/dev/null | wc -l | tr -d ' ')"
rcp="$(find "$ROOT/receipts" -type f 2>/dev/null | wc -l | tr -d ' ')"
snap="$(find "$ROOT/snapshots" -type f 2>/dev/null | wc -l | tr -d ' ')"
branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo "")"

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
tmp="$(mktemp)"
cat > "$tmp" <<EOF
{
  "schema":"sr.heartbeat.v0_2",
  "generated_at_utc":"$ts",
  "root_bytes": $bytes,
  "counts": { "docs": $docs, "bin": $binf, "receipts": $rcp, "snapshots": $snap },
  "git_branch":"$branch"
}
EOF
mv "$tmp" "$latest"

R="$ROOT/receipts/sr_done_receipt_heartbeat_${ts//[:]/_}.json"
printf '{ "schema":"sr.receipt.v0_1","tool":"sr.heartbeat.v0_2","generated_at_utc":"%s","status":"ok","summary":"heartbeat written"}\n' "$ts" > "$R"
echo "$latest"
