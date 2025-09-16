#!/usr/bin/env bash
# sr_rename_canonical_v0_1.sh — compute and apply canonical renames
[ -n "$BASH_VERSION" ] || exec /usr/bin/env bash "$0" "$@"

set -euo pipefail

ROOT="${HOME}/static-rooster"
REN_DIR="${ROOT}/receipts/renames"
mkdir -p "$REN_DIR"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TS_SAFE="$(printf "%s" "$TS" | tr ":" "_")"

PLAN_JSON="${REN_DIR}/sr_rename_plan_v0_1_${TS_SAFE}.json"
DONE_JSON="${REN_DIR}/sr_done_receipt_rename_v0_1_${TS_SAFE}.json"
CHANGELOG="${ROOT}/99_sr_change_log.md"

is_excluded() {
  case "$1" in
    "$ROOT/.git/"*|"$ROOT/.venv/"*|"$ROOT/receipts/"*|"$ROOT/snapshots/"*|"$ROOT/quarantine/"*|"$ROOT/archives/"*|"$ROOT/failures/"*|"$ROOT/forge/"*|"$ROOT/support/logs/"*) return 0;;
  esac
  return 1
}

# canonicalize only the basename
canon_name() {
  local base="$1"
  # lower
  base="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
  # spaces -> underscore
  base="${base//[[:space:]]/_}"
  # strip illegal chars (keep a-z0-9._-)
  base="$(printf '%s' "$base" | sed 's/[^a-z0-9._-]/_/g')"
  # collapse multiple underscores
  base="$(printf '%s' "$base" | sed 's/_\{2,\}/_/g')"
  # trim leading/trailing underscores
  base="$(printf '%s' "$base" | sed 's/^_//; s/_$//')"
  printf '%s' "$base"
}

mapfile -d '' FILES < <(find "$ROOT" -type f -print0 2>/dev/null)

declare -a ORIGS=()
declare -a NEWS=()

for f in "${FILES[@]}"; do
  if is_excluded "$f"; then continue; fi
  rel="${f#"${ROOT}/"}"
  dir="$(dirname "$rel")"
  base="$(basename "$rel")"
  canon="$(canon_name "$base")"
  # only rename if basename changes
  if [[ "$canon" != "$base" && -n "$canon" ]]; then
    new_rel="${dir}/${canon}"
    # avoid collision with existing file by skipping if target exists
    if [[ -e "${ROOT}/${new_rel}" ]]; then
      echo "SKIP (exists): $rel -> $new_rel" >&2
      continue
    fi
    ORIGS+=("$rel")
    NEWS+=("$new_rel")
  fi
done

# write plan
{
  echo '{'
  echo '  "schema": "sr.rename.plan.v0_1",'
  echo '  "generated_at_utc": "'"$TS"'",'
  echo '  "pairs": ['
  n=${#ORIGS[@]}
  for ((i=0;i<n;i++)); do
    o="${ORIGS[$i]}"; nrel="${NEWS[$i]}"
    o="${o//\\/\\\\}"; o="${o//\"/\\\"}"
    nrel="${nrel//\\/\\\\}"; nrel="${nrel//\"/\\\"}"
    printf '    { "from": "%s", "to": "%s" }' "$o" "$nrel"
    (( i < ${#ORIGS[@]}-1 )) && printf ','
    printf '\n'
  done
  echo '  ]'
  echo '}'
} > "$PLAN_JSON"

echo "Plan written: $PLAN_JSON"
echo "Pairs: ${#ORIGS[@]}"
if [[ "${SR_APPLY:-0}" != "1" ]]; then
  echo "DRY RUN — set SR_APPLY=1 to apply."
  exit 0
fi

# apply renames
applied=0; skipped=0
for ((i=0;i<${#ORIGS[@]};i++)); do
  from="${ROOT}/${ORIGS[$i]}"
  to="${ROOT}/${NEWS[$i]}"
  mkdir -p "$(dirname "$to")"
  # use git mv if tracked
  if git -C "$ROOT" ls-files --error-unmatch "$ORIGS" >/dev/null 2>&1; then
    git -C "$ROOT" mv -f "$from" "$to" || { echo "WARN git mv failed: $from"; ((skipped++)); continue; }
  else
    mv -f "$from" "$to" || { echo "WARN mv failed: $from"; ((skipped++)); continue; }
  fi
  ((applied++))
done

# append to changelog
{
  echo ""
  echo "## Canonical renames @ ${TS}"
  echo ""
  for ((i=0;i<${#ORIGS[@]};i++)); do
    echo "- \`${ORIGS[$i]}\` → \`${NEWS[$i]}\`"
  done
} >> "$CHANGELOG" || true

# write done receipt
{
  echo '{'
  echo '  "schema": "sr.rename.done.v0_1",'
  echo '  "generated_at_utc": "'"$TS"'",'
  echo '  "counts": { "planned": '"${#ORIGS[@]}"', "applied": '"$applied"', "skipped": '"$skipped"' },'
  echo '  "plan": "'$PLAN_JSON'"'
  echo '}'
} > "$DONE_JSON"

echo "Applied: $applied, skipped: $skipped"
echo "Done receipt: $DONE_JSON"
