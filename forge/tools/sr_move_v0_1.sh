#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/static-rooster"
cd "$ROOT"

SRC="${1:-}"
MODE="${2:---plan}"    # default = dry-run plan; use --apply to enact

if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Usage: forge/tools/sr_move_v0_1.sh /path/to/file [--apply|--plan]"
  exit 2
fi

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
json_escape() { python3 - <<PY "$1"; 
import json,sys; print(json.dumps(sys.argv[1])) 
PY
}

mkdir -p receipts docs/identity docs/contracts

# --- decide canonical target ----
base="$(basename "$SRC")"
lower="$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' )"

DEST=""
SYMLINK_UPDATE=""   # for toolkit latest pointer

if [[ "$lower" =~ (^|_)99.*change.*log.*\.md$ ]]; then
  DEST="docs/identity/99_SR_Change_Log.md"
elif [[ "$lower" =~ canon.*\.md$ ]]; then
  DEST="docs/identity/01_SR_Canon.md"
elif [[ "$lower" =~ parable.*\.md$ ]]; then
  DEST="docs/identity/02_SR_Parables.md"
elif [[ "$lower" =~ build.*master.*toolkit.*\.md$ ]]; then
  # keep version if present (e.g., _v0_3); also maintain a stable symlink
  v=$(echo "$lower" | sed -n 's/.*\(v[0-9][0-9_]*\)\.md/\1/p')
  if [[ -n "${v:-}" ]]; then
    DEST="docs/contracts/build_master_toolkit_${v}.md"
  else
    DEST="docs/contracts/build_master_toolkit.md"
  fi
  SYMLINK_UPDATE="docs/contracts/build_master_toolkit.md"
else
  # Default: drop into contracts with normalized basename
  norm="$(echo "$base" | tr ' ' '_' )"
  DEST="docs/contracts/${norm}"
fi

PLAN="copy"
if [[ -f "$DEST" ]]; then
  # Compare content hash to decide skip/update
  h_src="$(sha256sum "$SRC" | awk '{print $1}')"
  h_dst="$(sha256sum "$DEST" | awk '{print $1}')" || true
  if [[ "${h_src:-x}" == "${h_dst:-y}" ]]; then
    PLAN="skip"
  else
    PLAN="update"
  fi
fi

echo "== SR Move v0.1 =="
echo " source: $SRC"
echo " target: $DEST"
echo " action: $PLAN"
[[ -n "$SYMLINK_UPDATE" ]] && echo " symlink: $SYMLINK_UPDATE -> $(basename "$DEST")"
echo

if [[ "$MODE" != "--apply" ]]; then
  echo "(plan only; no changes made)"; 
else
  install -m 664 "$SRC" "$DEST"
  if [[ -n "$SYMLINK_UPDATE" ]]; then
    ln -sfn "$(basename "$DEST")" "$SYMLINK_UPDATE"
  fi
fi

# --- receipt ---
TS="$(ts)"
RCP="receipts/sr_move_${TS}.json"
SCHEMA="sr.move_v0_1"
RESULT=$([[ "$MODE" == "--apply" ]] && echo "applied" || echo "planned")
ACTION="$PLAN"

cat > "$RCP" <<JSON
{
  "schema": "$SCHEMA",
  "generated_at": "$TS",
  "result": "$RESULT",
  "action": "$ACTION",
  "source": $(json_escape "$SRC"),
  "target": $(json_escape "$DEST"),
  "symlink_updated": $(json_escape "${SYMLINK_UPDATE:-}"),
  "host": "$(hostname)"
}
JSON

chmod 664 "$RCP"
echo "receipt: $RCP"

# optional: nudge the emitter to see it fast (non-fatal)
systemctl --user try-restart sr-emit.service >/dev/null 2>&1 || true

