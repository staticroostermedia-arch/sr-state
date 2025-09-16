#!/usr/bin/env sh
# sr_push_heartbeat_commit_v0_1.sh — commit heartbeats to repo (optional)
set -eu
REPO="${1:-.}"
BR="${BRANCH:-main}"
cd "$REPO"
git add receipts/heartbeats || true
if git diff --cached --quiet; then
  echo "No new heartbeats to commit."
  exit 0
fi
git config user.name "sr-heartbeat"
git config user.email "sr-heartbeat@users.noreply.github.com"
git commit -m "chore(heartbeat): add heartbeat receipt(s)"
git push origin "$BR"
