#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"; RE="$ROOT/receipts"; LOG="$ROOT/logs"
mkdir -p "$LOG" "$RE"
# kill any old
pkill -f "cloudflared tunnel --url" 2>/dev/null || true
# start quick tunnel
nohup cloudflared tunnel --url http://127.0.0.1:8888 --metrics localhost:0 --no-autoupdate \
  > "$LOG/quicktunnel.log" 2>&1 &
sleep 2
# scrape hostname
HOST=$(grep -m1 -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG/quicktunnel.log" || true)
TS=$(date -u +%Y%m%dT%H%M%SZ)
printf '{"generated_at":"%s","tool":"sr_quicktunnel_enable_v0_1","status":"%s","host":"%s"}\n' \
  "$TS" "$([ -n "$HOST" ] && echo ok || echo err)" "$HOST" \
  > "$RE/sr_quicktunnel_receipt_${TS}.json"
[ -n "$HOST" ] && echo "$HOST" > "$ROOT/QUICKTUNNEL_HOST"
[ -n "$HOST" ] && echo "Tunnel up: $HOST" || { echo "Tunnel failed. See $LOG/quicktunnel.log"; exit 1; }
