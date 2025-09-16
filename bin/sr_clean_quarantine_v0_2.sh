#!/usr/bin/env bash
# sr_clean_quarantine_v0_2.sh — non-destructive filename normalization via quarantine
# Re-exec in bash if invoked via sh
[ -n "$BASH_VERSION" ] || exec /usr/bin/env bash "$0" "$@"

set -euo pipefail

ROOT="${HOME}/static-rooster"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TS_SAFE="$(printf "%s" "$TS" | tr ":" "_")"

RECEIPTS_DIR="${ROOT}/receipts"
OUT_JSON="${RECEIPTS_DIR}/sr_done_receipt_cleanup_v0_2.json"
QUAR_ROOT="${ROOT}/quarantine/${TS_SAFE}"
FORGE="${QUAR_ROOT}/forge"
LOGS="${ROOT}/logs"
mkdir -p "${RECEIPTS_DIR}" "${FORGE}" "${LOGS}"

echo "== Static Rooster :: Cleanup v0.2 =="
echo "Time: ${TS}"
echo "Root: ${ROOT}"
echo "Mode: ${SR_APPLY:-0} (apply=1), purge=${SR_PURGE:-0}"

# find offenders
mapfile -d '' ALLFILES < <(find "$ROOT" -type f -print0 2>/dev/null)

is_excluded() {
  case "$1" in
    "$ROOT/.git/"*|"$ROOT/.venv/"*|"$ROOT/receipts/"*|"$ROOT/snapshots/"*|"$ROOT/quarantine/"*|"$ROOT/archives/"*|"$ROOT/failures/"*|"$ROOT/forge/"*|"$ROOT/support/logs/"*) return 0;;
  esac
  return 1
}

declare -a OFF_UPPER=()
declare -a OFF_SPACE=()
declare -a OFF_BADEXT=()

for f in "${ALLFILES[@]}"; do
  # normalize path
  rel="${f#"${ROOT}/"}"
  # exclusions
  if is_excluded "$f"; then continue; fi

  # classify
  if [[ "$rel" =~ [A-Z] ]]; then OFF_UPPER+=("$rel"); fi
  if [[ "$rel" =~ [[:space:]] ]]; then OFF_SPACE+=("$rel"); fi
  if [[ ! "$rel" =~ ^[a-z0-9._/\-]+$ ]]; then OFF_BADEXT+=("$rel"); fi
done

# unique union of offenders
declare -A SEEN
declare -a UNION=()
for arr in "${OFF_UPPER[@]}";  do SEEN["$arr"]=1; done
for arr in "${OFF_SPACE[@]}";  do SEEN["$arr"]=1; done
for arr in "${OFF_BADEXT[@]}"; do SEEN["$arr"]=1; done
for k in "${!SEEN[@]}"; do UNION+=("$k"); done

count=${#UNION[@]}
echo "Found offenders: $count (uppercase: ${#OFF_UPPER[@]}, space: ${#OFF_SPACE[@]}, badext: ${#OFF_BADEXT[@]})"

# Apply moves if requested
moved=0
if [[ "${SR_APPLY:-0}" = "1" && $count -gt 0 ]]; then
  echo "Applying: moving to ${FORGE}"
  for rel in "${UNION[@]}"; do
    src="${ROOT}/${rel}"
    dst="${FORGE}/${rel}"
    mkdir -p "$(dirname "$dst")"
    if [[ -f "$src" ]]; then
      mv -f "$src" "$dst"
      ((moved++)) || true
    fi
  done
  echo "Moved: $moved"
else
  echo "DRY RUN — no files moved. Set SR_APPLY=1 to move."
fi

# Purge current quarantine if asked
purged=0
if [[ "${SR_PURGE:-0}" = "1" ]]; then
  if [[ -d "$QUAR_ROOT" ]]; then
    echo "Purging quarantine batch: $QUAR_ROOT"
    rm -rf "$QUAR_ROOT"
    purged=1
  else
    echo "No current quarantine batch to purge: $QUAR_ROOT"
  fi
fi

# helper to emit small JSON arrays (truncated)
emit_array() {
  local -n ref=$1
  local limit=${2:-50}
  local n=${#ref[@]}
  (( n > limit )) && n=$limit
  printf "["
  local i
  for ((i=0;i<n;i++)); do
    item="${ref[$i]}"
    esc="${item//\\/\\\\}"
    esc="${esc//\"/\\\"}"
    printf "\"%s\"" "$esc"
    (( i < n-1 )) && printf ", "
  done
  printf "]"
}

# Write receipt
{
  printf '{\n'
  printf '  "schema": "sr.cleanup.v0_2",\n'
  printf '  "generated_at_utc": "%s",\n' "$TS"
  printf '  "root": "%s",\n' "$ROOT"
  printf '  "apply": %s,\n' "${SR_APPLY:-0}"
  printf '  "purge": %s,\n' "${SR_PURGE:-0}"
  printf '  "quarantine_dir": "%s",\n' "$QUAR_ROOT"
  printf '  "counts": { "offenders": %s, "moved": %s },\n' "$count" "$moved"
  printf '  "offenders": {\n'
  printf '    "uppercase": '; emit_array OFF_UPPER 25; printf ',\n'
  printf '    "spaces": '; emit_array OFF_SPACE 25; printf ',\n'
  printf '    "bad_ext": '; emit_array OFF_BADEXT 25; printf '\n'
  printf '  }\n'
  printf '}\n'
} > "$OUT_JSON"

echo "Receipt: $OUT_JSON"
echo "Done."
