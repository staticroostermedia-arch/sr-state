#!/bin/sh
# Emit snapshot + write watch checkpoint + compact status (won't close shell).
set -eu
ROOT="${HOME}/static-rooster"
PORT="${SR_PORT:-8888}"
cd "$ROOT"

TS="$(date -u +%Y-%m-%dT%H%M%SZ)"
SNAP_DIR="snapshots/${TS}"
mkdir -p "$SNAP_DIR"

# Pack project (skip snapshots and .git)
TAR="${SNAP_DIR}/sr_snapshot_${TS}.tgz"
tar --exclude='./snapshots' --exclude='./.git' -czf "$TAR" . 2>/dev/null || true
SHA="$(sha256sum "$TAR" | awk '{print $1}')"
printf '%s\n' "$SHA" > "${TAR}.sha256"

cat > "${SNAP_DIR}/sr_snapshot_${TS}.manifest.json" <<JSON
{
  "schema": "sr.snapshot.v0_3",
  "generated_at": "${TS}",
  "snapshot_dir": "${SNAP_DIR}",
  "files": { "tgz": "$(basename "$TAR")", "sha256": "${SHA}" }
}
JSON

probe() { curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}$1" 2>/dev/null || true; }
P_DECISIONHUB="$(probe /decisionhub)"
P_FORGE="$(probe /forge)"
VERDICT="foedus_intactum"
[ "$P_DECISIONHUB" != "200" ] && VERDICT="penitential_rite"
[ "$P_FORGE" != "200" ] && VERDICT="penitential_rite"

cat > receipts/sr_watch_checkpoint_v0_1.json <<JSON
{
  "schema": "sr.watch_checkpoint.v0_1",
  "generated_at": "${TS}",
  "snapshot_dir": "${SNAP_DIR}",
  "http_probe": { "/decisionhub": "${P_DECISIONHUB}", "/forge": "${P_FORGE}" },
  "offenders": [],
  "summary": "checkpoint after snapshot ${TS}",
  "verdict": "${VERDICT}"
}
JSON

cat > receipts/sr_status_dump_v0_3.json <<JSON
{
  "schema": "sr_status_dump_v0_3",
  "generated_at": "${TS}",
  "verdict": "${VERDICT}",
  "snapshot_dir": "${SNAP_DIR}"
}
JSON

printf '\n== Snapshot == %s\n== Probes == /decisionhub:%s /forge:%s\n== Verdict == %s\n' \
  "$SNAP_DIR" "$P_DECISIONHUB" "$P_FORGE" "$VERDICT"
