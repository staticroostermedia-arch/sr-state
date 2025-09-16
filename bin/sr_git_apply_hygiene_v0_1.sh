#!/usr/bin/env sh
# sr_git_apply_hygiene_v0_1.sh — write .gitignore, commit policy, and push stabilize branch
set -eu
ROOT="${HOME}/static-rooster"
SSH_URL="${SSH_URL:-git@github.com:staticroostermedia-arch/decisionhub.git}"
BR_MAIN="${BR_MAIN:-main}"
BR_STAB="stabilize_$(date -u +%Y%m%d)"
cd "$ROOT"

cat > .gitignore <<'EOF'
!.gitignore
identity/**
docs/**
config/**
bin/**
ark/exports/**
receipts/heartbeats/**
receipts/watch_checkpoint*
receipts/**
snapshots/**
archives/**
quarantine/**
forge/**
failures/**
.secrets/**
.venv/**
__pycache__/
*.log
*.tmp
*.tgz
EOF

git add -A || true
git checkout -B "$BR_STAB"
git config user.name "Static Rooster"
git config user.email "bot@staticrooster.local"
git commit -m "chore(hygiene): apply .gitignore and normalize tree" || true

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$SSH_URL"
else
  git remote add origin "$SSH_URL"
fi

git push -u origin "$BR_STAB" || true

echo "Open PR: $BR_STAB -> $BR_MAIN"
