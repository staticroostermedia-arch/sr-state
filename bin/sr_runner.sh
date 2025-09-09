#!/usr/bin/env bash
set -euo pipefail
. "${SR_HOME:-$HOME/static-rooster}/bin/sr_env.sh"
cd "$SR_HOME"

log(){ printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$SR_LOG_DIR/runner.log"; }
trap 'log "runner done (rc=$?)"' EXIT

need(){ command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need jq; need python3; need git; need curl
command -v sponge >/dev/null || echo "TIP: sudo apt-get install -y moreutils (for sponge)"

log "== runner start =="

# 1) git (no push yet; safe no-op if not a repo)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git fetch -q "$SR_GIT_REMOTE" || true
  git add -A || true
  if ! git diff --quiet --staged; then git commit -m "runner: auto-commit $(date -Is)" || true; fi
  git pull --rebase "$SR_GIT_REMOTE" "$SR_GIT_BRANCH" || true
  [[ "${SR_GIT_PUSH}" == "true" ]] && git push "$SR_GIT_REMOTE" HEAD:"$SR_GIT_BRANCH" || true
fi

# 2) rebuild decisionhub config (best-effort)
log "rebuild config"
python3 "$SR_HOME/bin/sr_cfg_rebuild.py" >>"$SR_LOG_DIR/runner.log" 2>&1 || log "WARN: sr_cfg_rebuild.py failed"

# 3) static server on :8888
if ! pgrep -f "http.server ${SR_PORT_STATIC}.*--directory ${SR_HOME}" >/dev/null; then
  log "start static :$SR_PORT_STATIC"
  nohup python3 -m http.server "$SR_PORT_STATIC" --directory "$SR_HOME" \
    >"$SR_LOG_DIR/static.$(date +%s).log" 2>&1 &
  sleep 0.6
fi

# 4) ingest service (systemd user unit should already exist; just start)
log "ensure ingest service"
systemctl --user start sr-ingest.service 2>>"$SR_LOG_DIR/runner.log" || log "WARN: ingest start failed"

# 5) health checks
curl -fsS "http://localhost:${SR_PORT_STATIC}/config/decisionhub.config.json" >/dev/null || log "WARN: cfg 404"
curl -fsS "http://localhost:${SR_PORT_INGEST}/health" >/dev/null || log "WARN: ingest 404"

# 6) snapshot (exclude .git, logs, snapshots to avoid 'file changed' warning)
TS=$(date +%Y%m%d_%H%M%S)
OUT="$SR_SNAP_DIR/sr_snapshot_${TS}.tgz"
log "snapshot -> $OUT"
tar -C "$SR_HOME" \
  --exclude='./.git' --exclude='./snapshots/*' --exclude='./logs/*' \
  -czf "$OUT" .
sha256sum "$OUT" | tee "${OUT}.sha256" >/dev/null
log "OK"
