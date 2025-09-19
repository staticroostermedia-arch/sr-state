#!/usr/bin/env bash
set -euo pipefail
URL="http://127.0.0.1:8888/forge/index.html"
exec chromium-browser --noerrdialogs --disable-session-crashed-bubble \
  --disable-infobars --kiosk "$URL"
