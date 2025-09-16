#!/usr/bin/env bash
# sr_make_core_snapshot_v0_1.sh — create pruned core snapshot and receipt
set -eu
ROOT="${HOME}/static-rooster"
OUT="${ROOT}/snapshots"; mkdir -p "$OUT" "$ROOT/receipts"
ts="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
tgz="$OUT/core_snapshot_${ts}.tgz"

tmp="$(mktemp -d)"
rsync -a --delete --prune-empty-dirs \
  --include="identity/***" \
  --include="docs/***" \
  --include="config/***" \
  --include="bin/***" \
  --include="ark/exports/***" \
  --include="receipts/heartbeats/***" \
  --include="receipts/watch_checkpoint*" \
  --exclude="receipts/***" \
  --exclude="snapshots/***" \
  --exclude="archives/***" \
  --exclude="quarantine/***" \
  --exclude="forge/***" \
  --exclude="failures/***" \
  --exclude=".venv/***" --exclude=".git/***" \
  --include="*/" --exclude="*" \
  "$ROOT/" "$tmp/core/"

tar czf "$tgz" -C "$tmp/core" .
rm -rf "$tmp"

R="$ROOT/receipts/sr_done_receipt_core_snapshot_${ts}.json"
printf '{ "schema":"sr.receipt.v0_1","tool":"sr.core.snapshot.v0_1","generated_at_utc":"%s","status":"ok","artifact":"%s"}\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$(basename "$tgz")" > "$R"
echo "$tgz"
