#!/usr/bin/env bash
set -euo pipefail
PORT="${1:-8891}"
exec /usr/bin/python3 -u "$HOME/static-rooster/bin/sr_ingest_server.py" --port "$PORT"
