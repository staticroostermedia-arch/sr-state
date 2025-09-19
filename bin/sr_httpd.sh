#!/usr/bin/env bash
set -euo pipefail
PORT=8888
cd "$HOME/static-rooster"
exec python3 -m http.server "$PORT" --directory . 
