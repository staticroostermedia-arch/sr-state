#!/usr/bin/env sh
# sr_blip_mark_v0_1.sh — record a blip/reset sentinel
set -eu
ROOT="${HOME}/static-rooster"
DIR="$ROOT/receipts/blips"; mkdir -p "$DIR"
HB="$ROOT/receipts/heartbeats/latest.json"
ts="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
reason="${1:-sandbox_reset_or_context_gap}"
hbts="$(jq -r '.generated_at_utc' "$HB" 2>/dev/null || echo "")"
R="$DIR/sr_blip_${ts}.json"
{
  printf '{\n'
  printf '  "schema":"sr.blip.v0_1",\n'
  printf '  "generated_at_utc":"%s",\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '  "reason":"%s",\n' "$reason"
  printf '  "last_heartbeat_ts":"%s"\n' "$hbts"
  printf '}\n'
} > "$R"
echo "Blip noted: $R"
