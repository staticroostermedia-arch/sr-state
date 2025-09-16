#!/usr/bin/env bash
# sr_watch_git_now_v0_1.sh — quick human-friendly view, no receipts
[ -n "$BASH_VERSION" ] || exec /usr/bin/env bash "$0" "$@"

set -euo pipefail
ROOT="${HOME}/static-rooster"
git -C "$ROOT" fetch --all --prune
echo "== branches =="
git -C "$ROOT" branch -vv
echo
echo "== shortlog (last 10) =="
git -C "$ROOT" log --oneline -n 10
echo
echo "== heartbeat branches on origin =="
git -C "$ROOT" ls-remote --heads origin 'chore/heartbeat*' | awk '{print $2}' | sed 's#refs/heads/##' || true
echo
echo "== workflow on main? =="
if git -C "$ROOT" ls-tree -r origin/main --name-only | grep -qE '^\.github/workflows/ark_watcher_v0_1\.yml$'; then
  echo "ark_watcher_v0_1.yml PRESENT"
else
  echo "ark_watcher_v0_1.yml MISSING"
fi
