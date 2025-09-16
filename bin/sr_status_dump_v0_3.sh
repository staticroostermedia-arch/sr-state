#!/bin/sh
set -eu
ROOT="$HOME/static-rooster"
RCPTS="$ROOT/receipts"
NOW="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
SNAP="$(ls -ldt "$ROOT"/snapshots/* 2>/dev/null | head -n1 | awk '{print $9}' || true)"
mkdir -p "$RCPTS"
cat > "$RCPTS/sr_status_dump_v0_3.json" <<JSON
{
  "schema": "sr_status_dump_v0_3",
  "generated_at": "$NOW",
  "verdict": "penitential_rite",
  "snapshot_dir": "${SNAP:-unknown}"
}
JSON
