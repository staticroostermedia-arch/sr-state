#!/usr/bin/env bash
# Canon Ark builder: deterministic tar, versioned filename, receipt, index, latest pointer.
# Usage: bash ~/static-rooster/sr_make_ark_v1_1.sh [lite|full]
set -euo pipefail
trap 'c=$?; echo "[ERR] line $LINENO exited with $c"; exit $c' ERR
echo "[ark] start…"

MODE="${1:-lite}"
ROOT="$HOME/static-rooster"
SHARE="$ROOT/share"; ARKDIR="$SHARE/ark"; SNAPS="$ROOT/snapshots"; REC="$ROOT/receipts"
CTX="$SHARE/context/latest.json"
mkdir -p "$ARKDIR" "$REC" "$SNAPS"

ARK_VER="v0_1"
UI_VER="$(python3 - <<'PY' 2>/dev/null || true
import os,glob,re,json
root=os.path.expanduser('~/static-rooster/decisionhub')
cfg=os.path.join(root,'config','decisionhub_config.json')
v=''
try:
  with open(cfg) as f: v=(json.load(f).get('ui_version') or '')
except: pass
if not v:
  vs=[]
  for p in glob.glob(os.path.join(root,'start_here_v*.html')):
    m=re.search(r'_v(\d+_\d+)', os.path.basename(p))
    if m: vs.append(m.group(1))
  if vs: v='v'+max(vs, key=lambda s: tuple(map(int,s.split('_'))))
print(v,end='')
PY
)"; UI_VER="${UI_VER:-v0_3}"

TS="$(date -u +%Y_%m_%dt%H_%M_%SZ)"
DEST_DIR="$SNAPS/$TS"; mkdir -p "$DEST_DIR"
VER_NAME="sr_ark_${ARK_VER}_${TS}_${MODE}.tgz"
VER="$DEST_DIR/$VER_NAME"; VER_SHARE="$ARKDIR/$VER_NAME"; LATEST="$ARKDIR/latest.tgz"; TMP="$DEST_DIR/.tmp_ark.tgz"

hash256(){ command -v sha256sum >/dev/null && sha256sum "$1" | awk '{print $1}' || openssl dgst -sha256 "$1" | awk '{print $2}'; }

echo "[ark] tar building ($MODE)… (progress # every ~50 files)"
cd "$HOME"
EXC_COMMON=( '--exclude=static-rooster/share/ark/*' '--exclude=static-rooster/.git/*' '--exclude=static-rooster/**/__pycache__/*' '--exclude=static-rooster/**/node_modules/*' '--exclude=static-rooster/**/.cache/*' '--exclude=static-rooster/**/.venv/*' )
if [ "$MODE" = "lite" ]; then EXCLUDES=( "${EXC_COMMON[@]}" '--exclude=static-rooster/receipts/*' ); else EXCLUDES=( "${EXC_COMMON[@]}" ); fi

# print a '#' every 50 files so we know it's alive
tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
    --checkpoint=50 --checkpoint-action=echo='#' \
    "${EXCLUDES[@]}" -czf "$TMP" "static-rooster"

SIZE=$(stat -c %s "$TMP" 2>/dev/null || wc -c <"$TMP")
SHA=$(hash256 "$TMP")

mv -f "$TMP" "$VER"; cp -f "$VER" "$VER_SHARE"; cp -f "$VER" "$LATEST"
printf '%s  %s\n' "$SHA" "$VER_NAME" > "${VER}.sha256.txt"
printf '%s  latest.tgz\n' "$SHA" > "$ARKDIR/latest.sha256.txt"

cat > "$DEST_DIR/${VER_NAME%.tgz}.json" <<JSON
{ "schema":"sr.ark.manifest.v1","ark_version":"$ARK_VER","ui_version":"$UI_VER",
  "generated_at_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","mode":"$MODE",
  "snapshot_dir":"$DEST_DIR","share_path":"/share/ark/$VER_NAME","latest_path":"/share/ark/latest.tgz",
  "size_bytes":$SIZE,"sha256":"$SHA","context_ref":"$( [ -f "$CTX" ] && echo "/share/context/latest.json" || echo "" )" }
JSON

cat > "$REC/sr_done_receipt_make_ark_${TS}.json" <<JSON
{ "schema":"sr.done_receipt.v0_1","tool_name":"sr_make_ark","status":"ok",
  "generated_at_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "summary":"$MODE • ${SIZE} bytes • ${SHA}",
  "observations":{"version_tgz":"$VER","share_tgz":"$VER_SHARE","latest_tgz":"$LATEST","ark_version":"$ARK_VER","ui_version":"$UI_VER"} }
JSON

python3 - <<'PY'
import os, json, glob
root=os.path.expanduser('~/static-rooster/share/ark')
items=[]
for p in sorted(glob.glob(os.path.join(root,'sr_ark_*.tgz')), reverse=True):
    try:
        st=os.stat(p)
        name=os.path.basename(p)
        shp=p+'.sha256.txt'; sha=''
        if os.path.exists(shp):
            try: sha=open(shp).read().split()[0]
            except: pass
        items.append({"name":name,"size_bytes":st.st_size,"sha256":sha,"path":"/share/ark/"+name})
    except FileNotFoundError:
        pass
items=items[:16]
os.makedirs(root, exist_ok=True)
open(os.path.join(root,'index.json'),'w').write(json.dumps({"schema":"sr.ark.index.v1","items":items}, indent=2))
for group in (glob.glob(os.path.join(root,'sr_ark_*.tgz')), glob.glob(os.path.join(root,'sr_ark_*.sha256.txt'))):
    for p in sorted(group)[:-16]:
        try: os.remove(p)
        except: pass
PY

echo "[ok] Ark $MODE → $VER_NAME (size=$SIZE sha256=$SHA)"
echo "[probe] HEAD /share/ark/latest.tgz"
curl -fsSI -m 5 "http://127.0.0.1:8888/share/ark/latest.tgz" || true
echo "[probe] /share/ark/index.json (first 200B)"
curl -fsS -m 5 "http://127.0.0.1:8888/share/ark/index.json" | head -c 200 || true
