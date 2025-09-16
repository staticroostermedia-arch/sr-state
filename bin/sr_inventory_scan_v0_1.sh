#!/usr/bin/env bash
# sr_inventory_scan_v0_1.sh — scan ~/static-rooster and write a machine-readable inventory receipt
set -euo pipefail

ROOT="${HOME}/static-rooster"
OUT_DIR="${ROOT}/receipts/inventory"
mkdir -p "$OUT_DIR"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TS_SAFE="$(printf "%s" "$TS" | tr ":" "_")"
OUT_JSON="${OUT_DIR}/sr_inventory_${TS_SAFE}.json"

# helpers
bytes_of() { du -sb "$1" 2>/dev/null | awk '{print $1}'; }
count_files() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' '; }
count_dirs()  { find "$1" -type d 2>/dev/null | wc -l | tr -d ' '; }

to_json_string() {
  # escape double quotes and backslashes
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

exists_dir() { [ -d "$1" ]; }
exists_file() { [ -f "$1" ]; }

TOTAL_BYTES="$(bytes_of "$ROOT")"
FILES="$(count_files "$ROOT")"
DIRS="$(count_dirs "$ROOT")"
DOCS="$(exists_dir "$ROOT/docs" && count_files "$ROOT/docs" || echo 0)"
CFG="$(exists_dir "$ROOT/config" && count_files "$ROOT/config" || echo 0)"
BIN="$(exists_dir "$ROOT/bin" && count_files "$ROOT/bin" || echo 0)"
RCP="$(exists_dir "$ROOT/receipts" && count_files "$ROOT/receipts" || echo 0)"
SNP="$(exists_dir "$ROOT/snapshots" && count_files "$ROOT/snapshots" || echo 0)"

# git summary
BRANCH="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo "")"
DIRTY="$(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
AHEAD=0; BEHIND=0; UNTR=0
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" fetch -q >/dev/null 2>&1 || true
  if git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    AHEAD="$(git -C "$ROOT" rev-list --left-right --count @{u}...HEAD 2>/dev/null | awk '{print $2}')"
    BEHIND="$(git -C "$ROOT" rev-list --left-right --count @{u}...HEAD 2>/dev/null | awk '{print $1}')"
  fi
  UNTR="$(git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"
fi

# timers
HB_T="unknown"; CS_T="unknown"
if command -v systemctl >/dev/null 2>&1; then
  HB_T="$(systemctl --user is-enabled sr-heartbeat.timer 2>/dev/null || echo disabled)"
  CS_T="$(systemctl --user is-enabled sr-core-snapshot.timer 2>/dev/null || echo disabled)"
fi

# latest snapshot
LATEST_SNAP="$(ls -1t "$ROOT"/snapshots/core_snapshot_*.tgz 2>/dev/null | head -n1 || true)"
LATEST_SNAP_BYTES=0
[ -n "$LATEST_SNAP" ] && LATEST_SNAP_BYTES="$(bytes_of "$LATEST_SNAP")"

# offenders (truncate to 50 each)
UPPER=()
SPACES=()
BAD_EXT=()
LARGE=()

while IFS= read -r -d '' f; do
  bname="${f#"${ROOT}/"}"
  case "$bname" in
    .git/*|.venv/*|snapshots/*|archives/*|receipts/*|quarantine/*|forge/*|failures/*) continue ;;
  esac
  if printf '%s' "$bname" | grep -q '[A-Z]'; then UPPER+=("$bname"); fi
  if printf '%s' "$bname" | grep -q '[[:space:]]'; then SPACES+=("$bname"); fi
  if ! printf '%s' "$bname" | grep -qE '^[a-z0-9._/\-]+$'; then BAD_EXT+=("$bname"); fi
  # large > 100MB
  sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
  if [ "$sz" -ge 104857600 ]; then LARGE+=("$bname"); fi
done < <(find "$ROOT" -type f -print0 2>/dev/null)

trim_array_json() {
  local -n arr=$1
  local limit=${2:-50}
  local out="["
  local n=${#arr[@]}
  if [ $n -gt $limit ]; then n=$limit; fi
  for ((i=0; i<n; i++)); do
    esc=$(to_json_string "${arr[$i]}")
    out="$out\"$esc\""
    if [ $i -lt $((n-1)) ]; then out="$out, "; fi
  done
  out="$out]"
  printf '%s' "$out"
}

TOP_HEAVY="["
# biggest top-level dirs
for d in "$ROOT"/*; do
  [ -d "$d" ] || continue
  base="${d##*/}"
  case "$base" in .git|.venv|archives|snapshots|receipts|quarantine|forge|failures) continue ;; esac
  b=$(bytes_of "$d")
  TOP_HEAVY="$TOP_HEAVY{ \"path\":\"$base\", \"bytes\": $b },"
done
TOP_HEAVY="${TOP_HEAVY%,}]"

# write JSON
{
  printf '{\n'
  printf '  "schema": "sr.inventory.v0_1",\n'
  printf '  "generated_at_utc": "%s",\n' "$TS"
  printf '  "root": "%s",\n' "$(to_json_string "$ROOT")"
  printf '  "bytes_total": %s,\n' "$TOTAL_BYTES"
  printf '  "counts": { "files": %s, "dirs": %s, "docs": %s, "config": %s, "bin": %s, "receipts": %s, "snapshots": %s },\n' "$FILES" "$DIRS" "$DOCS" "$CFG" "$BIN" "$RCP" "$SNP"
  printf '  "git": { "branch": "%s", "dirty": %s, "ahead": %s, "behind": %s, "untracked": %s },\n' "$BRANCH" "$DIRTY" "$AHEAD" "$BEHIND" "$UNTR"
  printf '  "timers": { "heartbeat_timer": "%s", "core_snapshot_timer": "%s" },\n' "$HB_T" "$CS_T"
  printf '  "latest_snapshot": { "path": "%s", "bytes": %s },\n' "$(to_json_string "$LATEST_SNAP")" "$LATEST_SNAP_BYTES"
  printf '  "offenders": {\n'
  printf '    "uppercase": %s,\n' "$(trim_array_json UPPER 50)"
  printf '    "spaces": %s,\n' "$(trim_array_json SPACES 50)"
  printf '    "bad_ext": %s,\n' "$(trim_array_json BAD_EXT 50)"
  printf '    "large_files": %s\n' "$(trim_array_json LARGE 50)"
  printf '  },\n'
  printf '  "top_heavy": %s\n' "$TOP_HEAVY"
  printf '}\n'
} > "$OUT_JSON"

echo "Inventory written: $OUT_JSON"
echo "Bytes: $TOTAL_BYTES | files: $FILES | receipts: $RCP | snapshots: $SNP | git: $BRANCH (dirty:$DIRTY a:$AHEAD b:$BEHIND u:$UNTR)"
