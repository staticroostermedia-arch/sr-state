#!/usr/bin/env bash
set -euo pipefail
. "$HOME/static-rooster/bin/sr_secrets_load.sh" || true
cd "$HOME/static-rooster"
# prefer SSH; fallback to HTTPS+PAT if provided
if git remote get-url origin >/dev/null 2>&1; then
  :
else
  if [ -n "${SR_GIT_REMOTE_SSH:-}" ]; then
    git remote add origin "$SR_GIT_REMOTE_SSH"
  elif [ -n "${SR_GIT_REMOTE_HTTPS:-}" ]; then
    git remote add origin "$SR_GIT_REMOTE_HTTPS"
    if [ -n "${SR_GITHUB_TOKEN:-}" ]; then
      git config credential.helper store
      printf "https://%s:x-oauth-basic@github.com\n" "$SR_GITHUB_TOKEN" >> ~/.git-credentials
      chmod 600 ~/.git-credentials
    fi
  fi
fi
STAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
LASTREC=$(ls -1 receipts/sr.done_receipt_*_v0_1.json 2>/dev/null | tail -n1 || true)
MSG="checkpoint: ${STAMP}"
if [ -n "$LASTREC" ]; then
  WHO=$(jq -r '.foedus // "intactum"' "$LASTREC" 2>/dev/null || echo intactum)
  MSG="tick: ${STAMP} · foedus=${WHO}"
fi
git add -A
git commit -m "$MSG" || true
git push -u origin HEAD || git push || true
echo "pushed: $MSG"
