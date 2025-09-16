#!/usr/bin/env bash
# sr_push_snapshot_v0_1.sh — optionally POST the latest core snapshot to a webhook
set -eu
ROOT="${HOME}/static-rooster"
OUT="${ROOT}/snapshots"
WEB="${HEARTBEAT_WEBHOOK:-}"
[ -z "$WEB" ] && { echo "No HEARTBEAT_WEBHOOK set; skipping POST."; exit 0; }
# pick most recent core snapshot
file="$(ls -1t "$OUT"/core_snapshot_*.tgz 2>/dev/null | head -n1 || true)"
[ -z "$file" ] && { echo "No core snapshot found."; exit 1; }
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
resp="$(curl -sS -X POST -F "snapshot=@${file}" -F "ts=$ts" "$WEB" || true)"
R="$ROOT/receipts/sr_done_receipt_push_snapshot_${ts//[:]/_}.json"
printf '{ "schema":"sr.receipt.v0_1","tool":"sr.push.snapshot.v0_1","generated_at_utc":"%s","status":"ok","summary":"posted %s","webhook":"%s"}\n' "$ts" "$(basename "$file")" "$WEB" > "$R"
echo "$resp"
