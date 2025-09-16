#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
RCPTS="$ROOT/receipts"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HOST="$(uname -n)"
KERNEL="$(uname -sr)"
IFACE="$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')"
[ -n "$IFACE" ] || IFACE="unknown"
POWER="unknown"; command -v upower >/dev/null 2>&1 && POWER="$(upower -i $(upower -e | head -n1) 2>/dev/null | awk -F: '/state/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')"

LATEST_SNAP="$(ls -1dt "$ROOT"/snapshots/* 2>/dev/null | head -n1 || true)"
MANI=""; [ -n "$LATEST_SNAP" ] && MANI="$(ls -1 "$LATEST_SNAP"/*manifest*.json 2>/dev/null | head -n1 || true)"

http_probe() {
  url="$1"
  code="$(curl -fsS -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || echo 000)"
  echo "$code"
}
PORT="${SR_PORT:-8888}"
BASE="http://127.0.0.1:${PORT}"
P_DECISION="$(http_probe "${BASE}/decisionhub/index_v1.html" )"
P_FORGE="$(http_probe "${BASE}/forge/index_v0_1.html" )"
P_VIEWER="$(http_probe "${BASE}/receipts/index_v0_1.html" )"

VERDICT="unknown"
# If you already have a watch checkpoint receipt, prefer its verdict
CHECK="$(ls -1t "$RCPTS"/sr_watch_checkpoint_*.json 2>/dev/null | head -n1 || true)"
if [ -n "$CHECK" ]; then
  VERDICT="$(grep -Eo '"verdict"[[:space:]]*:[[:space:]]*"[^"]+"' "$CHECK" 2>/dev/null | sed 's/.*"verdict"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo unknown)"
fi

OUT="$RCPTS/sr_status_dump_${TS}.json"
printf '%s\n' "{
  \"schema\": \"sr.status_dump.v0_3\",
  \"generated_at\": \"${TS}\",
  \"host\": {\"name\": \"${HOST}\", \"kernel\": \"${KERNEL}\", \"iface\": \"${IFACE}\", \"power\": \"${POWER}\"},
  \"http\": {\"/decisionhub\": ${P_DECISION:-0}, \"/forge\": ${P_FORGE:-0}, \"/receipts\": ${P_VIEWER:-0}},
  \"snapshot_dir\": \"${LATEST_SNAP}\",
  \"manifest\": \"${MANI}\",
  \"verdict\": \"${VERDICT}\"
}" > "$OUT"
echo "$OUT"
exit 0
