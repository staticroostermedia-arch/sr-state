#!/usr/bin/env sh
# sr_git_fixup_v0_1.sh — helps ensure a usable branch and pushes workflows/artifacts.
set -eu
REPO="${1:-.}"
BR="${BRANCH:-main}"
cd "$REPO" || { echo "Repo not found: $REPO"; exit 1; }

if [ ! -d ".git" ]; then
  echo "Initializing new git repo (no .git found)…"
  git init
fi

cur="$(git branch --show-current || true)"
if [ -z "$cur" ]; then
  echo "No current branch; creating $BR"
  git checkout -b "$BR"
else
  echo "Current branch: $cur"
  BR="$cur"
fi

# Ensure .github workflow exists
mkdir -p .github/workflows
if [ -f "$HOME/static-rooster/.github/workflows/ark_watcher_v0_1_3.yml" ]; then
  cp "$HOME/static-rooster/.github/workflows/ark_watcher_v0_1_3.yml" .github/workflows/ark_watcher_v0_1_3.yml
fi

git add .github/workflows || true
if git diff --cached --quiet; then
  echo "No workflow changes to commit."
else
  git commit -m "ci: add/update Ark watcher (2h schedule)"
fi

# Check remote
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "No remote 'origin' set. To set one:"
  echo "  git remote add origin <YOUR_GIT_REMOTE_URL>"
  echo "  git push -u origin $BR"
  exit 0
fi

# Push
git push -u origin "$BR" || {
  echo "Push failed. If remote default branch is not $BR, adjust with:"
  echo "  BRANCH=<remote_default> ./sr_git_fixup_v0_1.sh"
  exit 1
}
echo "Pushed branch $BR to origin."
