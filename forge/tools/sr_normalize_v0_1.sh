#!/bin/sh
# sr_normalize_v0_1.sh  —  default: plan only;  --apply to perform renames
# Rule: lowercase, no spaces; replace spaces with '_'; drop ()[] characters.
set -eu
ROOT="${HOME}/static-rooster"
cd "$ROOT"

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SNAPDIR="$(ls -1dt snapshots/* 2>/dev/null | head -n1 || true)"
OFFJSON=""
[ -n "$SNAPDIR" ] && OFFJSON="$(ls -1 "$SNAPDIR"/offenders_*.json 2>/dev/null | head -n1 || true)"

# Build candidate list:
tmp_candidates="$(mktemp)"
if [ -n "$OFFJSON" ]; then
  # Extract "path": "..." from offenders json
  sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p' "$OFFJSON" \
    | sed 's#^#./#' > "$tmp_candidates"
else
  # Fallback: scan working tree for violations (skip .git and snapshots tarballs)
  find . -type f \
    -not -path "./.git/*" \
    -not -path "./snapshots/*.tgz" \
    \( -name "* *" -o -regex ".*[()\\[\\]].*" -o -regex ".*[A-Z].*" \) \
    -printf "%p\n" > "$tmp_candidates"
fi

norm_basename() {
  # lowercase, spaces->_, strip ()[]
  bn="$1"
  bn="$(printf "%s" "$bn" | tr 'A-Z' 'a-z')"
  bn="$(printf "%s" "$bn" | sed 's/[[:space:]]\+/_/g; s/[()\[\]]//g')"
  printf "%s" "$bn"
}

PLAN="$(mktemp)"
COLLISIONS=0
while IFS= read -r p; do
  [ -f "$p" ] || continue
  dir="$(dirname "$p")"
  base="$(basename "$p")"
  nbase="$(norm_basename "$base")"
  # Keep directory same; only change basename
  if [ "$base" != "$nbase" ]; then
    tgt="$dir/$nbase"
    # Detect collision
    if [ -e "$tgt" ] && [ "$tgt" != "$p" ]; then
      printf "COLLISION\t%s\t%s\n" "$p" "$tgt" >> "$PLAN"
      COLLISIONS=$((COLLISIONS+1))
    else
      printf "RENAME\t%s\t%s\n" "$p" "$tgt" >> "$PLAN"
    fi
  fi
done < "$tmp_candidates"

PLANCOUNT="$(wc -l < "$PLAN" | tr -d ' ')"
TSu="$(date -u +%Y%m%dT%H%M%SZ)"
RCPT="$ROOT/receipts/sr_normalize_${TSu}.json"
SNAP="$ROOT/snapshots/${TSu}_normalize"
mkdir -p "$SNAP"

# Write receipt (always)
{
  printf '{\n'
  printf '  "schema":"sr.normalize.v0_1",\n'
  printf '  "generated_at":"%s",\n' "$TS"
  printf '  "plan_entries":%s,\n' "$PLANCOUNT"
  printf '  "collisions":%s,\n' "$COLLISIONS"
  printf '  "snapshot_dir":"%s"\n' "$SNAP"
  printf '}\n'
} > "$RCPT"

cp "$PLAN" "$SNAP/plan.tsv"

if [ "$PLANCOUNT" -eq 0 ]; then
  echo "Normalize: nothing to do. (plan empty)"
  echo "receipt: $RCPT"
  exit 0
fi

echo "Plan entries (orig -> new): $PLANCOUNT"
echo
echo "Top 20:"
head -n 20 "$PLAN" | sed 's/^/  /'
echo

if [ "$COLLISIONS" -gt 0 ] && [ "$APPLY" -eq 1 ]; then
  echo "ERROR: collisions present ($COLLISIONS). Resolve first; aborting apply."
  exit 2
fi

if [ "$APPLY" -eq 0 ]; then
  echo "DRY-RUN complete. Review $SNAP/plan.tsv ."
  echo "receipt: $RCPT"
  exit 0
fi

# Apply renames
APPLIED=0
while IFS="$(printf '\t')" read -r kind orig tgt; do
  [ "$kind" = "RENAME" ] || continue
  odir="$(dirname "$tgt")"
  mkdir -p "$odir"
  mv -vn -- "$orig" "$tgt" || true
  APPLIED=$((APPLIED+1))
done < "$PLAN"

echo "APPLIED renames: $APPLIED"
echo "receipt: $RCPT"
exit 0
