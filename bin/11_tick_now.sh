#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
source "$ROOT/.venv/bin/activate" || true
# Try the systemd service first (matches the timer)
systemctl --user start sr-runner.service || echo "systemd kick failed; calling runner directly"
python "$ROOT/runner/runner.py"
jq -r '.foedus' "$ROOT/state/last_checkpoint.json" || cat "$ROOT/state/last_checkpoint.json"
ls -1t "$ROOT/dossiers"/sr_dossier_*.zip | head -n 1
