#!/usr/bin/env bash
set -euxo pipefail
ROOT="$HOME/static-rooster"
source "$ROOT/.venv/bin/activate"
echo "python: $(which python) $(python -V)"
echo "tree:"
command -v tree >/dev/null || sudo apt-get install -y tree
tree -L 2 "$ROOT" || true
echo "--- run runner ---"
python "$ROOT/runner/runner.py"
echo "--- checkpoint ---"
cat "$ROOT/state/last_checkpoint.json" | jq .foedus
echo "--- dossiers ---"
ls -lh "$ROOT/dossiers" | tail -n 5
