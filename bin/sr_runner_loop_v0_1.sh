#!/bin/sh
set -eu
ROOT="$HOME/static-rooster"; ORD="$ROOT/orders"; REC="$ROOT/receipts"
mkdir -p "$ORD" "$REC"
echo "runner loop started: $(date -u +%FT%TZ)"
while :; do
  for f in "$ORD"/*.json; do
    [ -e "$f" ] || { sleep 2; continue; }
    TS=$(date -u +%Y%m%dT%H%M%SZ)
    ( command -v jq >/dev/null 2>&1 && jq -c . "$f" || cat "$f" ) > "$REC/sr_order_seen_${TS}.json"
    mv "$f" "$ORD/processed_${TS}.json"
  done
done
