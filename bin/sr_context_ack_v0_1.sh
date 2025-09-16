#!/usr/bin/env sh
# sr_context_ack_v0_1.sh — print a one-line Ark ack (ts, bytes, counts, branch)
set -eu
ROOT="${HOME}/static-rooster"
HB="$ROOT/receipts/heartbeats/latest.json"
if [ ! -f "$HB" ]; then
  echo "Ark ack: (no heartbeat)"
  exit 0
fi
ts="$(jq -r '.generated_at_utc' "$HB" 2>/dev/null || echo '?')"
root="$(jq -r '.root_bytes' "$HB" 2>/dev/null || echo '0')"
docs="$(jq -r '.counts.docs' "$HB" 2>/dev/null || echo '0')"
bin="$(jq -r '.counts.bin' "$HB" 2>/dev/null || echo '0')"
rcp="$(jq -r '.counts.receipts' "$HB" 2>/dev/null || echo '0')"
br="$(jq -r '.git_branch' "$HB" 2>/dev/null || echo '')"
printf "Ark ack: %s | root=%sB | docs=%s bin=%s receipts=%s | branch=%s\n" "$ts" "$root" "$docs" "$bin" "$rcp" "$br"
