#!/usr/bin/env bash
set -euo pipefail
ZIP="${1:?zip required}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
unzip -q "$ZIP" -d "$WORK/src"
cd "$WORK/src"
# normalize: lowercase, spaces->_, strip parens and weirds
python3 - <<'PY'
import os,re,shutil
for root,dirs,files in os.walk(".", topdown=False):
  for name in files:
    new=re.sub(r'[^a-z0-9._/-]+','_',re.sub(r'[() ]','_',name.lower()))
    if new!=name:
      os.makedirs(os.path.dirname(os.path.join(root,new)),exist_ok=True)
      shutil.move(os.path.join(root,name),os.path.join(root,new))
  for d in dirs:
    nd=re.sub(r'[^a-z0-9._/-]+','_',re.sub(r'[() ]','_',d.lower()))
    if nd!=d:
      os.makedirs(os.path.join(root,nd),exist_ok=True)
      try: shutil.rmtree(os.path.join(root,nd))
      except: pass
      shutil.move(os.path.join(root,d),os.path.join(root,nd))
PY
# collect offenders snapshot
python3 - <<'PY'
import os,sys,json
bad=[]
for root,_,files in os.walk("."):
  for f in files:
    b=os.path.basename(f)
    if any(c.isupper() for c in b) or ' ' in b or '(' in b or ')' in b:
      bad.append(os.path.join(root,b))
rep={
 "schema":"sr.penitential.v0_1",
 "offenders_before": bad,
}
open("../rite_report.json","w").write(__import__("json").dumps(rep,indent=2))
PY
cd "$WORK/src"
OUT="$(dirname "$ZIP")/$(basename "$ZIP" .zip)_sanitized_v0_1.zip"
zip -qr "$OUT" .
echo "$OUT"
