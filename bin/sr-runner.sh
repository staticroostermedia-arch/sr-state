#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
CFG="$ROOT/config/runner_config_v0_1.json"
LOG="$ROOT/support/logs/sr-runner.log"

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "[$ts] Runner tick" >>"$LOG"

# Ensure server
"$ROOT/bin/sr_httpd.sh" ensure || true

# Probe core routes
for route in $(jq -r '.paths.tiles[]' "$CFG"); do
  url="http://localhost:8888$route"
  status=$(curl -o /dev/null -s -w "%{http_code}" "$url" || echo "000")
  echo "[$ts] Probe $route → $status" >>"$LOG"
done

# Write simple checkpoint receipt
cat >"$ROOT/receipts/sr_watch_checkpoint_v0_1.json" <<JSON
{"ts":"$ts","status":"ok","note":"tick/tock executed"}
JSON
