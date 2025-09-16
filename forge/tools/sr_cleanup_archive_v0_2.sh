#!/usr/bin/env bash
# SR Cleanup + Archive v0.2  (dry-run by default; pass --apply to enact)
set -u  # no 'set -e' so we don't close your shell

ROOT="${HOME}/static-rooster"
SNAPS="$ROOT/snapshots"
ARCH="$ROOT/archives"
RCPTS="$ROOT/receipts"
NOW="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
OUT="$RCPTS/sr_cleanup_${NOW}.json"

KEEP_LIVE="${KEEP_LIVE:-8}"         # keep newest N snapshots in live/
TAR_AFTER_DAYS="${TAR_AFTER_DAYS:-30}"
TRIM_RECEIPTS_AFTER_DAYS="${TRIM_RECEIPTS_AFTER_DAYS:-60}"
APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1

log(){ printf "%s\n" "$*"; }
doit(){ if ((APPLY)); then eval "$*"; else printf "[dry-run] %s\n" "$*"; fi; }

mkdir -p "$ARCH" "$RCPTS"

# 1) move older snapshots to archives/
if [[ -d "$SNAPS" ]]; then
  mapfile -t ALL < <(ls -1dt "$SNAPS"/* 2>/dev/null || true)
  COUNT=${#ALL[@]}
  if (( COUNT > KEEP_LIVE )); then
    for ((i=KEEP_LIVE;i<COUNT;i++)); do
      src="${ALL[$i]}"
      base="$(basename "$src")"
      dst="$ARCH/$base"
      doit "mkdir -p '$ARCH' && mv '$src' '$dst'"
    done
  fi
else
  log "no snapshots/ yet"
fi

# 2) tar.gz archives older than TAR_AFTER_DAYS
find "$ARCH" -maxdepth 1 -type d -mtime +"$TAR_AFTER_DAYS" 2>/dev/null | while read -r d; do
  base="$(basename "$d")"
  tgz="$ARCH/${base}.tar.gz"
  test -f "$tgz" && continue
  doit "tar -C '$ARCH' -czf '$tgz' '$base' && rm -rf '$d'"
done

# 3) trim old receipts
find "$RCPTS" -type f -name '*.json' -mtime +"$TRIM_RECEIPTS_AFTER_DAYS" -print0 2>/dev/null | \
xargs -0 -r -I{} bash -c '[[ '"$APPLY"' -eq 1 ]] && rm -f "$1" || echo "[dry-run] rm -f $1"' _ {}

# 4) write receipt
cat > "$OUT" <<JSON
{
  "schema": "sr.cleanup.v0_2",
  "generated_at": "$NOW",
  "apply_mode": $APPLY,
  "keep_live": $KEEP_LIVE,
  "tar_after_days": $TAR_AFTER_DAYS,
  "trim_receipts_after_days": $TRIM_RECEIPTS_AFTER_DAYS
}
JSON

log "receipt: $OUT"
