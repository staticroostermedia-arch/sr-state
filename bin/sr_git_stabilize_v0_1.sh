#!/usr/bin/env sh
# sr_git_stabilize_v0_1.sh — normalize, commit, and push safely
set -eu

REPO="${HOME}/static-rooster"
SSH_URL="${SSH_URL:-git@github.com:staticroostermedia-arch/decisionhub.git}"
BR_MAIN="${BR_MAIN:-main}"
BR_STAB="stabilize_$(date -u +%Y%m%d)"
BACKUP="${HOME}/static-rooster_backup_$(date -u +%Y%m%d_%H%M%SZ).tgz"

echo "== Git Stabilize v0.1 =="
echo "Repo: $REPO"
echo "Remote: $SSH_URL"

# 0) Safety backup
if [ -d "$REPO" ]; then
  tar czf "$BACKUP" -C "$REPO" .
  echo "Backup written: $BACKUP"
else
  echo "ERROR: repo dir not found: $REPO" >&2
  exit 1
fi

cd "$REPO"

# 1) Ensure repo and branch
if [ ! -d .git ]; then
  git init
  git checkout -b "$BR_MAIN"
fi

# Remember current branch if any; else default to main
CUR="$(git branch --show-current 2>/dev/null || echo "$BR_MAIN")"

# 2) Install .gitignore (idempotent)
cat > .gitignore <<'EOF'
# --- Static Rooster repo hygiene ---
# keep docs/config/bin and ark metadata
!.gitignore
docs/**
config/**
bin/**
ark/exports/**

# heartbeats + watch checkpoint are allowed
receipts/heartbeats/**
receipts/watch_checkpoint*

# ignore everything else under receipts
receipts/**

# ignore heavy and transient
snapshots/**
archives/**
quarantine/**
failures/**
forge/**
.secrets/**
.venv/**
__pycache__/
*.pyc
*.log
*.tmp

EOF

# 3) Stage + commit all changes (including deletions)
git add -A || true
if git diff --cached --quiet; then
  echo "Nothing to commit (index clean)."
else
  # Create stabilize branch off current state (without losing local branch)
  git checkout -B "$BR_STAB"
  git config user.name "Static Rooster"
  git config user.email "bot@staticrooster.local"
  git commit -m "chore(stabilize): normalize tree, apply .gitignore, commit adds/deletes"
fi

# 4) Wire SSH remote
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$SSH_URL"
else
  git remote add origin "$SSH_URL"
fi

# 5) Push branch
git push -u origin "$BR_STAB" || {
  echo "Push failed. Check SSH access or repo permissions." >&2
  exit 2
}

echo "== Done =="
echo "Stabilize branch: $BR_STAB"
echo "Next: Open a PR from $BR_STAB -> $BR_MAIN, or fast-forward locally:"
echo "   git checkout $BR_MAIN && git merge --ff-only $BR_STAB && git push"
