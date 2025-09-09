#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/static-rooster" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
BR="sr-autosave_$(date +%Y%m%d)"
git add -A || true
git commit -m "autosave: $(date -u +%F@%H:%MZ)" || true
git push -u origin HEAD:"$BR" || true
