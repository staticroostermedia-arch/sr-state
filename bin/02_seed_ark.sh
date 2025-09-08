#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
ARKZIP="${1:-$HOME/Downloads/sr_ark_core_v2_1_1_*.zip}"
ARKDIR="$ROOT/ark/current"
mkdir -p "$ARKDIR"
unzip -o $ARKZIP -d "$ARKDIR"

stage_dir() {  # src, dest
  local SRC="$ARKDIR/$1"; local DST="$ROOT/$2"
  if [ -d "$SRC" ]; then mkdir -p "$DST"; rsync -a "$SRC/" "$DST/"; else echo "skip: $1"; fi
}

# stage what exists (some dirs may not be present in this Ark)
stage_dir decisionhub     decisionhub
stage_dir hub_registry    hub_registry
stage_dir tools           tools
stage_dir receipts        receipts
stage_dir forge           forge
stage_dir canon           canon
stage_dir indices         indices
stage_dir docs            docs
stage_dir attachments     attachments
stage_dir cognition       cognition
stage_dir entropy         entropy

# pin Ark
sha256sum $ARKZIP | awk '{print $1}' > "$ROOT/config/ark.sha256"
printf '{"schema":"sr.attachments_refs.v0","ark":{"name":"%s","sha256":"%s"}}\n' \
  "$(basename $ARKZIP)" "$(cat "$ROOT/config/ark.sha256")" > "$ROOT/config/attachments_refs.json"
echo "Ark staged + pinned."
