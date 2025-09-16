#!/usr/bin/env sh
# sr_push_ark_commit_v0_1.sh — commit ark/exports/* and push (used by CI or dev)
set -eu
BRANCH="${1:-main}"
git config user.name "sr-ark-watcher"
git config user.email "sr-ark-watcher@users.noreply.github.com"
git add ark/exports || true
if git diff --cached --quiet; then
  echo "No new exports to commit."
  exit 0
fi
git commit -m "chore(ark): export bundle(s)"
git push origin "$BRANCH"
