#!/usr/bin/env bash
set -euo pipefail
PORT="${1:-8000}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
DIST="$ROOT/dist"
if ! pgrep -f "http.server $PORT" >/dev/null 2>&1; then
  ( cd "$DIST" && python3 -m http.server "$PORT" ) &
fi
xdg-open "http://localhost:$PORT/index.html" >/dev/null 2>&1 || true
echo "Serving $DIST on http://localhost:$PORT"
