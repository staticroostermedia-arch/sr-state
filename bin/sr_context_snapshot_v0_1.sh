#!/usr/bin/env sh
# sr_context_snapshot_v0_1.sh — make a slim state snapshot for rehydration
set -eu
ROOT="${HOME}/static-rooster"
OUTDIR="${ROOT}/snapshots"
mkdir -p "$OUTDIR" "$ROOT/receipts"
ts="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
out="$OUTDIR/context_snapshot_${ts}.tgz"

# Build include list
tmp="$(mktemp -d)"
mkdir -p "$tmp/include"
# Copy minimal spine
rsync -a --delete --prune-empty-dirs \
  --include="docs/***" --include="config/***" --include="bin/***" \
  --include="ark/exports/***" \
  --include="receipts/heartbeats/***" \
  --include="receipts/watch_checkpoint*" \
  --exclude="receipts/***" \
  --exclude="snapshots/***" \
  --exclude=".venv/***" --exclude=".git/***" \
  --exclude="archives/***" \
  --exclude="forge/***" \
  --include="*/" --exclude="*" \
  "$ROOT/" "$tmp/include/"

tar czf "$out" -C "$tmp/include" .
rm -rf "$tmp"

# Receipt
R="$ROOT/receipts/sr_done_receipt_context_snapshot_${ts}.json"
printf '{ "schema":"sr.receipt.v0_1","generated_at_utc":"%s","tool_name":"sr.context.snapshot.v0_1","status":"ok","summary":"%s"}\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$(basename "$out")" > "$R"
echo "Snapshot: $out"
