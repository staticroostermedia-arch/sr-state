#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
DOS="$ROOT/dossiers"
OUTDIR="$ROOT/forge/gate_reports"; mkdir -p "$OUTDIR"
ZIP="${1:-$(ls -1t "$DOS"/sr_dossier_*.zip 2>/dev/null | head -n1)}"
[ -f "$ZIP" ] || { echo "no dossier zip"; exit 2; }
python3 - <<'PY' "$ZIP" "$OUTDIR"
import sys,zipfile,re,json,os,time
zip_path,outdir=sys.argv[1],sys.argv[2]
with zipfile.ZipFile(zip_path,'r') as z:
    names=[n for n in z.namelist() if not n.endswith('/')]
def badname(b): 
    return (' ' in b) or '(' in b or ')' in b or re.search(r'[A-Z]', b)
off=[n for n in names if badname(n.split('/')[-1])]
treaty="unknown"
try:
    import json
    with zipfile.ZipFile(zip_path,'r') as z:
        if "state/last_checkpoint.json" in z.namelist():
            treaty=json.loads(z.read("state/last_checkpoint.json").decode('utf-8','ignore')).get("foedus","unknown")
except: pass
gate={
  "schema":"sr.gate.v0_1",
  "generated_at":time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
  "dossier":os.path.basename(zip_path),
  "files_total": len(names),
  "filename_rule": {"ok": len(off)==0, "offenders": off},
  "treaty_in_bundle": treaty
}
gate["verdict"]="intactum" if gate["filename_rule"]["ok"] else "ruptum"
out=os.path.join(outdir,f"sr_gate_report_{int(time.time())}_v0_1.json")
open(out,'w').write(json.dumps(gate,indent=2))
print(out)
PY
