#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$ROOT/snapshots" "$ROOT/receipts"
TAR="$ROOT/snapshots/sr_snapshot_$TS.tgz"
( cd "$ROOT" && tar --exclude="snapshots/*" --exclude="quarantine/*" -czf "$TAR" decisionhub forge config receipts docs 2>/dev/null ) || true
SIZE=$(stat -c%s "$TAR" 2>/dev/null || stat -f%z "$TAR" 2>/dev/null || echo 0)
SHA=$(sha256sum "$TAR" 2>/dev/null | awk '{print $1}' || echo "")
MAN="$ROOT/snapshots/sr_snapshot_$TS.manifest.json"
printf '{"schema":"sr.snapshot.v0_1","generated_at":"%s","path":"%s","size_bytes":%s,"sha256":"%s"}\n' "$TS" "/snapshots/$(basename "$TAR")" "$SIZE" "$SHA" > "$MAN"
cp "$MAN" "$ROOT/receipts/snapshot_latest.json"
printf '{"generated_at":"%s","tool":"sr_make_state_snapshot_v0_2.sh","snapshot":"%s","manifest":"%s","status":"created"}\n' "$TS" "/snapshots/$(basename "$TAR")" "/snapshots/$(basename "$MAN")" > "$ROOT/receipts/sr_snapshot_receipt_$TS.json"
echo "snapshot → $TAR"
