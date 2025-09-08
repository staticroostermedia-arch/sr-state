#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
SNAP="$ROOT/snapshots"; mkdir -p "$SNAP"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$SNAP/sr_snapshot_$STAMP.tgz"
tar -C "$ROOT" -czf "$OUT" \
  --exclude='dossiers/*' --exclude='captures/*' --exclude='logs/*' \
  --exclude='ark/current/*' --exclude='state/*' \
  decisionhub hub_registry tools forge receipts canon indices docs config ark
sha256sum "$OUT" | tee "$OUT.sha256"
echo "Snapshot saved: $OUT"
