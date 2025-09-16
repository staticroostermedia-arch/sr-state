#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
cd "$ROOT"
INBOX="./_inbox"
mkdir -p "$INBOX"
TS="$(date -u +%Y-%m-%dT%H%M%SZ)"
ORDER="$INBOX/order_${TS}.sh"
printf "%s" "$1" > "$ORDER"
chmod +x "$ORDER"
echo "$ORDER"
