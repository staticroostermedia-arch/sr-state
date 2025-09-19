#!/usr/bin/env bash
set -euo pipefail
ROOT="${SR_ROOT:-$HOME/static-rooster}"
cd "$ROOT/public/state"
git add .
if ! git diff --cached --quiet; then
  git commit -m "beacon $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  git push origin HEAD:main
fi
