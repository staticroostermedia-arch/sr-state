#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster/receipts"
mkdir -p "$ROOT"
python3 - <<'PY'
import json,glob,os,time
root=os.path.expanduser('~/static-rooster/receipts')
items=[]
for p in sorted(glob.glob(os.path.join(root,'sr.done_receipt_*_v0_1.json')), reverse=True):
    b=os.path.basename(p)
    items.append({"name":b,"url":"/receipts/"+b})
out=os.path.join(root,'index_v0_1.json')
json.dump({"schema":"sr.receipts.index.v0_1","generated_at":time.strftime('%FT%TZ', time.gmtime()),"items":items}, open(out,'w'), indent=2)
print("wrote", out)
PY
