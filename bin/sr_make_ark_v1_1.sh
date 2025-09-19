#!/usr/bin/env bash
# SR Ark builder v1.1 — deterministic tar + receipt + index + latest pointer
# Usage: bash ~/static-rooster/bin/sr_make_ark_v1_1.sh [lite|full]
set -euo pipefail
trap 'c=$?; echo "[ERR] line $LINENO exited with $c"; exit $c' ERR

MODE="${1:-lite}"

ROOT="$HOME/static-rooster"
SHARE="$ROOT/share"
ARKDIR="$SHARE/ark"
REC="$ROOT/receipts"
CTX="$SHARE/context/latest.json"
SNAPS="$ROOT/snapshots"

mkdir -p "$ARKDIR" "$REC" "$SNAPS" "$SHARE"

ARK_VER="v0_1"
UI_VER="$(python3 - <<'PY' 2>/dev/null || true
import json, os, glob, re
cfg=os.path.expanduser('~/static-rooster/decisionhub/config/decisionhub_config.json')
v=''
try:
  with open(cfg) as f: j=json.load(f); v=j.get('ui_version') or ''
except: pass
if not v:
  vs=[]
  for p in glob.glob(os.path.expanduser('~/static-rooster/decisionhub/start_here_v*.html')):
    m=re.search(r'_v(\d+_\d+)', os.path.basename(p))
    if m: vs.append(m.group(1))
  if vs: v='v'+max(vs,key=lambda s:tuple(map(int,s.split('_'))))
print(v or 'v0_3', end='')
PY
)"

TS="$(date -u +%Y_%m_%dt%H_%M_%SZ)"
DESTDIR="$SNAPS/$TS"; mkdir -p "$DESTDIR"
BASE="sr_ark_${ARK_VER}_${UI_VER}_${TS}_${MODE}"
TMP="$DESTDIR/.tmp.tgz"
OUT="$DESTDIR/${BASE}.tgz"
LATEST="$ARKDIR/latest.tgz"

# liveness heartbeat while tar runs
( while :; do sleep 10; echo "[hb] packing…"; done ) & HB=$!

cd "$HOME"
EXC=( --exclude=static-rooster/share/ark/* --exclude=static-rooster/.git/* --exclude=static-rooster/**/.git/* --exclude=static-rooster/**/__pycache__/* --exclude=static-rooster/**/.cache/* --exclude=static-rooster/**/.venv/* --exclude=static-rooster/**/node_modules/* )
if [ "$MODE" = "lite" ]; then EXC+=( --exclude=static-rooster/receipts/* ); fi
tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
    --checkpoint=50 --checkpoint-action=echo='#' \
    "${EXC[@]}" -czf "$TMP" static-rooster
kill "$HB" 2>/dev/null || true

mv -f "$TMP" "$OUT"
cp -f "$OUT" "$ARKDIR/"
ln -sf "$ARKDIR/$(basename "$OUT")" "$LATEST"

SHA="$(sha256sum "$OUT" | awk '{print $1}')"
SIZE="$(stat -c%s "$OUT")"
printf '%s\n' "$SHA" > "$ARKDIR/latest.sha256.txt"
printf '{ "name": "%s", "size_bytes": %s, "sha256": "%s" }\n' "$(basename "$OUT")" "$SIZE" "$SHA" > "$ARKDIR/latest.json"

# rebuild index (keep newest 16)
python3 - <<'PY'
import os, json, glob, time, pathlib
arkdir=pathlib.Path(os.path.expanduser('~/static-rooster/share/ark'))
items=[]
for p in sorted(glob.glob(str(arkdir/'sr_ark_*.tgz')), reverse=True):
    try:
        st=os.stat(p); name=os.path.basename(p)
        sha=''
        ls=arkdir/'latest.sha256.txt'
        if ls.exists():
            try: sha=ls.read_text().split()[0]
            except: pass
        items.append({"name":name,"size_bytes":st.st_size,"sha256":sha,"ts":time.strftime("%Y-%m-%dT%H_%M_%SZ", time.gmtime(st.st_mtime))})
    except FileNotFoundError:
        pass
items=items[:16]
(arkdir/'index.json').write_text(json.dumps({"schema":"sr.ark.index.v1","items":items}, indent=2))
PY

# merge Ark capsule into context
python3 - <<'PY'
import os, json, time, pathlib
base=pathlib.Path(os.path.expanduser('~/static-rooster/share'))
arkdir=base/'ark'
ctx=base/'context'/'latest.json'
ark_latest=json.loads((arkdir/'latest.json').read_text())
pub_txt=base/'public_url.txt'
pub=None
if pub_txt.exists():
    b=pub_txt.read_text().strip().rstrip('/')
    pub=f"{b}/ark/{ark_latest['name']}"
caps={
 "schema":"sr.ctx.ark_receipt.v0_1",
 "created_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
 "ark": {
   "name": ark_latest["name"],
   "size_bytes": ark_latest["size_bytes"],
   "sha256": ark_latest["sha256"],
   "local_path": f"/share/ark/{ark_latest['name']}",
   "public_url": pub
 },
 "pointers": {
   "index_json": "/share/ark/index.json",
   "latest_json": "/share/ark/latest.json",
   "latest_sha256": "/share/ark/latest.sha256.txt",
   "context_snapshot": "/share/context/latest.json"
 }
}
ctx.parent.mkdir(parents=True, exist_ok=True)
data={}
if ctx.exists():
    try: data=json.loads(ctx.read_text())
    except: data={}
data["ark_receipt"]=caps
ctx.write_text(json.dumps(data, indent=2))
PY

# receipt
REC="$HOME/static-rooster/receipts/sr_done_receipt_make_ark_${TS}.json"
cat > "$REC" <<JSON
{ "schema":"sr.done_receipt.v0_1","tool_name":"sr_make_ark","status":"ok",
  "generated_at_utc":"${TS//_/:}",
  "summary":"$MODE • $SIZE bytes • $SHA",
  "observations":{"ark_version":"$ARK_VER","ui_version":"$UI_VER","latest":"/share/ark/latest.tgz"} }
JSON

echo "[ok] sr_make_ark: $(basename "$OUT") size=$SIZE sha256=$SHA"
