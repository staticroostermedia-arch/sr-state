#!/bin/sh
set -eu
URL="http://127.0.0.1:8888/decisionhub/start_here_v0_3.html"
for c in "${BROWSER:-}" chromium google-chrome google-chrome-stable brave-browser; do
  [ -n "$c" ] || continue
  command -v "$c" >/dev/null 2>&1 && B="$c" && break || true
done
[ -n "${B:-}" ] || { echo "No Chromium/Chrome found"; exit 1; }
exec "$B" --app="$URL" --user-data-dir=/tmp/sr_kiosk_profile --no-first-run --no-default-browser-check \
  --disable-extensions --disable-sync --disable-translate --disable-background-networking \
  --disable-features=Translate,AutofillServerCommunication,OptimizationHints --password-store=basic
