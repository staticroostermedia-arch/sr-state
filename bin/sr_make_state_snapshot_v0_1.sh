#!/usr/bin/env sh
# sr_make_state_snapshot_v0_1.sh — create a pruned snapshot tgz of ~/static-rooster
set -eu
ROOT="${HOME}/static-rooster"
OUTDIR="${1:-$HOME/Desktop}"
TS="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
NAME="static_rooster_state_${TS}.tgz"
DEST="$OUTDIR/$NAME"

# Exclusions: big/binary churn. Keep docs/config/bin/receipts, skip forge & large snapshots.
EXCLUDES="--exclude=forge --exclude=ark --exclude=*.zip --exclude=*.tgz --exclude=snapshots/*"

mkdir -p "$OUTDIR"
( cd "$ROOT" && tar czf "$DEST" $EXCLUDES . )

echo "Snapshot: $DEST"
