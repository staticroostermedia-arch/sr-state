#!/usr/bin/env sh
# sr_push_ark_commit_v0_1_2.sh — always commit: exports or heartbeat
set -eu
BRANCH="${1:-main}"
EXPORTS_DIR="ark/exports"
mkdir -p "$EXPORTS_DIR"

git config user.name "sr-ark-watcher"
git config user.email "sr-ark-watcher@users.noreply.github.com"

# Stage any new bundles
git add "$EXPORTS_DIR" || true

# If nothing to commit, create a heartbeat and stage it
if git diff --cached --quiet; then
  ts="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
  hb="$EXPORTS_DIR/heartbeat_${ts}.json"
  printf '{ "schema":"sr.receipt.v0_1","generated_at_utc":"%s","tool_name":"sr.ark.watch.heartbeat","status":"ok"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$hb"
  git add "$hb"
fi

git commit -m "chore(ark): export bundle(s) or heartbeat"
git push origin "$BRANCH"
