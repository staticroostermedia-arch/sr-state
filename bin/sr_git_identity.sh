#!/usr/bin/env bash
set -euo pipefail
GIT_USER="StaticRoosterMedia"
GIT_EMAIL="sr-bot@example.local"

git config --global user.name  "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

ROOT="${SR_ROOT:-$HOME/static-rooster}"
REPO="$ROOT/public/state"
if [ -d "$REPO/.git" ]; then
  git -C "$REPO" config user.name  "$GIT_USER"
  git -C "$REPO" config user.email "$GIT_EMAIL"
  echo "Local git identity set in $REPO"
else
  echo "Repo not found at $REPO (skipping local config)"
fi
