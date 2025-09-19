#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
LOG="$ROOT/logs"
TUN="$LOG/quicktunnel.log"
OUT="$ROOT/QUICKTUNNEL_HOST.txt"
SHARE="$ROOT/share"
mkdir -p "$LOG" "$SHARE"

# 1) stop any old cloudflared
pkill -f '^cloudflared tunnel --url' 2>/dev/null || true

# 2) start a fresh quick tunnel; tee log so we can parse the URL
nohup cloudflared tunnel --url http://127.0.0.1:8888 \
  --metrics localhost:0 --no-autoupdate \
  >"$TUN" 2>&1 &

# 3) wait up to ~20s for the URL to appear, capture it
HOST=""
for i in {1..40}; do
  if grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$TUN" >/dev/null; then
    HOST="$(grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$TUN" | head -n1)"
    break
  fi
  sleep 0.5
done

if [[ -z "$HOST" ]]; then
  echo "Tunnel failed to produce a host. See $TUN" >&2
  exit 1
fi

echo "$HOST" | tee "$OUT"

# 4) publish a tiny index JSON the kiosk can read
echo "{\"latest\":\"$HOST\"}" > "$SHARE/share_index_latest.json"

# 5) prove it works
curl -sf "$HOST/forge/kiosk_chat_v0_1.html" >/dev/null || true
echo "ok: tunnel=$HOST"
