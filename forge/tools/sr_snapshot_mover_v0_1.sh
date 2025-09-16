#!/bin/sh
# sr_snapshot_mover_v0_1.sh
# Move loose snapshot artifacts into snapshots/<UTC>/ and emit a receipt.
set -eu
ROOT="${HOME}/static-rooster"
cd "$ROOT" 2>/dev/null || { echo "ERR: $ROOT not found"; exit 2; }

UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TS="$(printf %s "$UTC" | tr -d ':TZ')"   # compact ts for filenames
SNAP_DIR="snapshots/${UTC}"
mkdir -p "$SNAP_DIR"

# patterns considered "snapshot artifacts"
# (expand as needed; only top-level files, skip ones already inside snapshots/)
PATTERNS='
sr_snapshot_*.tgz
sr_snapshot_*.tgz.sha256
sr_snapshot_*.manifest.json
env_*.json
git_log_*.txt
offenders_*.json
canon_parity_*.json
watch_checkpoint_*.json
'

moved_count=0
moved_list_file="$(mktemp)"
for p in $PATTERNS; do
  for f in "$ROOT"/$p; do
    [ -e "$f" ] || continue
    # skip anything already inside snapshots/
    case "$f" in
      "$ROOT"/snapshots/*) continue ;;
    esac
    # only regular files
    [ -f "$f" ] || continue
    mv -f -- "$f" "$SNAP_DIR"/
    printf '%s\n' "$(basename "$f")" >> "$moved_list_file"
    moved_count=$((moved_count+1))
  done
done

# minimal manifest (if none existed)
if ! ls "$SNAP_DIR"/sr_snapshot_*.manifest.json >/dev/null 2>&1; then
  MAN="$SNAP_DIR/sr_snapshot_${TS}.manifest.json"
  {
    echo "{"
    echo '  "schema":"sr.snapshot.manifest.v0_1",'
    echo "  \"generated_at\":\"$UTC\","
    echo "  \"snapshot_dir\":\"$SNAP_DIR\""
    echo "}"
  } > "$MAN"
fi

# receipt
RCPT="$ROOT/receipts/sr_snapshot_move_${TS}.json"
{
  echo "{"
  echo '  "schema":"sr.snapshot.move.v0_1",'
  echo "  \"generated_at\":\"$UTC\","
  echo "  \"snapshot_dir\":\"$SNAP_DIR\","
  echo "  \"moved_count\":$moved_count,"
  echo '  "moved_files": ['
  awk 'BEGIN{first=1}{if(!first)printf(",");printf("\n    \"%s\"", $0); first=0}END{if(!first)printf("\n")}' "$moved_list_file"
  echo "  ]"
  echo "}"
} > "$RCPT"
rm -f "$moved_list_file"

echo "[snapshot-mover] moved: $moved_count -> $SNAP_DIR"
echo "[snapshot-mover] receipt: $RCPT"
