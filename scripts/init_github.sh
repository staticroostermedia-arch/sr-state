#!/usr/bin/env bash
set -euo pipefail
REPO_URL="${1:-}"
git init
git branch -M main || git checkout -b main
git add -A
git commit -m "Initial commit: Static Rooster Pip-Boy EH1003006 bundle v1.0"
if [[ -n "${REPO_URL}" ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "${REPO_URL}"
  else
    git remote add origin "${REPO_URL}"
  fi
  git push -u origin main
else
  echo "No remote provided. To push later:"
  echo "  git remote add origin <REPO_URL>"
  echo "  git push -u origin main"
fi
