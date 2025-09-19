#!/usr/bin/env bash
set -euo pipefail
PORT=8888
ROOT="$HOME/static-rooster/decisionhub"
BEST="$(ls "$ROOT"/start_here_v*.html 2>/dev/null | sort -V | tail -1 || true)"
[ -n "$BEST" ] || BEST="$ROOT/start_here_v0_1.html"
URL="http://127.0.0.1:${PORT}/decisionhub/$(basename "$BEST")"
BIN="$(command -v chromium-browser || true)"; [ -n "$BIN" ] || BIN="$(command -v google-chrome || true)"
[ -n "$BIN" ] || BIN="$(command -v chromium || true)"
[ -n "$BIN" ] || { echo "[ERR] no chromium/google-chrome binary found"; exit 1; }
exec "$BIN" --app="$URL" --user-data-dir="$HOME/.local/share/staticrooster_chromium" \
  --no-first-run --disable-sync --disable-translate --disable-background-networking \
  --disk-cache-size=52428800 --window-size=1200,800 --class=StaticRooster
