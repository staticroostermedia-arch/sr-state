#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
IN="${1:?reply zip required}"

# 0) optional sanitation
CLEAN="$IN"
if unzip -l "$IN" | awk '{print $4}' | egrep -q '[A-Z]|\(|\)| '; then
  CLEAN="$(bash "$ROOT/bin/sr_penitential_rite.sh" "$IN" | tail -n1)"
fi

# 1) stage
STG="$ROOT/staging/reply"; rm -rf "$STG"; mkdir -p "$STG"
unzip -q "$CLEAN" -d "$STG"

# 2) minimal validation
MAN="$STG/manifest.json"
CHK="$STG/state/last_checkpoint.json"
test -f "$MAN" -a -f "$CHK" || { echo "invalid: missing manifest or checkpoint"; mv "$IN" "$ROOT/failures/replies/"; exit 2; }

# 3) apply (rsync only safe folders)
rsync -av --delete --exclude='*.tif' --exclude='*.tiff' \
  "$STG/decisionhub/" "$ROOT/decisionhub/" 2>/dev/null || true
rsync -av --exclude='*.tif' --exclude='*.tiff' \
  "$STG/config/" "$ROOT/config/" 2>/dev/null || true
rsync -av --exclude='*.tif' --exclude='*.tiff' \
  "$STG/docs/" "$ROOT/docs/" 2>/dev/null || true

# 4) move input to applied
mkdir -p "$ROOT/applied/replies"
mv -f "$IN" "$ROOT/applied/replies/" 2>/dev/null || true

# 5) emit receipt
mkdir -p "$ROOT/receipts"
RID="sr.done_receipt_$(date +%s)_v0_1.json"
python3 - <<PY
import json,os,sys,time
rec={
 "schema":"sr.receipt.v0_1",
 "kind":"reply_apply",
 "generated_at":time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
 "source_zip": os.path.basename("$IN"),
 "sanitized": os.path.basename("$CLEAN") if "$CLEAN"!="$IN" else None,
 "foedus":"intactum"
}
open(os.path.join("$ROOT","receipts","$RID"),"w").write(json.dumps(rec,indent=2))
print("$RID")
PY

# 6) refresh indexes + gate
bash "$ROOT/bin/sr_after_tick.sh" || true
bash "$HOME/static-rooster/bin/sr_git_save.sh" || true
