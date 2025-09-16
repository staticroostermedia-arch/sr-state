#!/bin/sh
# sr_status_dump_v0_3.sh — Ark-aware status dump (POSIX sh)
set -eu
ROOT="${HOME}/static-rooster"
cd "$ROOT" 2>/dev/null || { echo "ERR: $ROOT not found"; exit 2; }

UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STAMP="$(printf %s "$UTC" | tr -d ':TZ')"
RECEIPTS="receipts"
mkdir -p "$RECEIPTS"

# Latest snapshot dir (normalized discipline)
SNAP_DIR="$(ls -1dt snapshots/* 2>/dev/null | head -n1 || true)"
[ -n "$SNAP_DIR" ] || SNAP_DIR=""

# Detect manifest inside snapshot
MANIFEST=""
if [ -n "$SNAP_DIR" ]; then
  MANIFEST="$(ls -1 "$SNAP_DIR"/*manifest*.json 2>/dev/null | head -n1 || true)"
fi

# Tolerant Ark artifact discovery inside snapshot
ARK_MAP=""
ARK_PREVIEW=""
if [ -n "$SNAP_DIR" ]; then
  ARK_MAP="$(find "$SNAP_DIR" -maxdepth 2 -type f -iname '*ark*map*.json' 2>/dev/null | head -n1 || true)"
  [ -n "$ARK_MAP" ] || ARK_MAP="$(find "$SNAP_DIR" -maxdepth 2 -type f -iname 'map_*.json' 2>/dev/null | head -n1 || true)"
  ARK_PREVIEW="$(find "$SNAP_DIR" -maxdepth 2 -type f -iname '*preview*.html' -o -iname '*ark*preview*.html' 2>/dev/null | head -n1 || true)"
fi

# Canon parity & offenders from snapshot (best-effort)
CANON_PARITY="$( [ -n "$SNAP_DIR" ] && ls -1 "$SNAP_DIR"/canon_parity_*.json 2>/dev/null | head -n1 || true )"
OFFENDERS="$( [ -n "$SNAP_DIR" ] && ls -1 "$SNAP_DIR"/offenders_*.json 2>/dev/null | head -n1 || true )"

# Verdict from checkpoint (global receipt)
CP="receipts/sr_watch_checkpoint_v0_1.json"
VERDICT="$(grep -E '"verdict"' "$CP" 2>/dev/null | sed 's/.*"verdict"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/;t; s/.*/unknown/')"

# Env bits
HOST="$(hostname 2>/dev/null || echo unknown)"
KERNEL="$(uname -sr 2>/dev/null || echo unknown)"
IFACE="$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}' || echo unknown)"
POWER="$(acpi -b 2>/dev/null || echo unknown)"

# Git short log (recent)
GIT_LOG_FILE="$SNAP_DIR/git_log_${STAMP}.txt"
if [ -n "$SNAP_DIR" ]; then
  git log -n 25 --pretty=format:'%h %ad %s' --date=iso-strict 2>/dev/null > "$GIT_LOG_FILE" || true
fi

# Dump receipt
OUT="$RECEIPTS/sr_status_dump_${STAMP}.json"
{
  echo "{"
  echo '  "schema":"sr.status.dump.v0_3",'
  echo "  \"generated_at\":\"$UTC\","
  echo "  \"verdict\":\"$VERDICT\","
  echo "  \"snapshot_dir\":\"${SNAP_DIR:-}\","
  echo "  \"manifest\":\"$(basename "${MANIFEST:-}")\","
  echo "  \"canon_parity\":\"$(basename "${CANON_PARITY:-}")\","
  echo "  \"offenders\":\"$(basename "${OFFENDERS:-}")\","
  echo "  \"ark_map\":\"$(basename "${ARK_MAP:-}")\","
  echo "  \"ark_preview\":\"$(basename "${ARK_PREVIEW:-}")\","
  echo "  \"env\": {"
  echo "    \"host\":\"$HOST\",\"kernel\":\"$KERNEL\",\"iface\":\"$IFACE\",\"power\":\"$POWER\""
  echo "  }"
  echo "}"
} > "$OUT"

echo "[status v0.3] $OUT"
