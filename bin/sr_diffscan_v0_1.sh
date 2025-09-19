#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
RE="$ROOT/receipts"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
MAN_CUR="$RE/manifest_${TS}.json"
MAN_LAST="$(ls -1t "$RE"/manifest_*.json 2>/dev/null | head -1 || true)"

shopt -s globstar nullglob
# Build current manifest (path, size, mtime, sha256 for small files only)
{
  echo '{ "generated_at":"'"$TS"'", "schema":"sr.manifest.v0_1", "files":['
  first=true
  while IFS= read -r -d '' f; do
    # Ignore receipts & share blobs here to reduce churn
    case "$f" in
      *"/receipts/"*|*"/share/"*|*"/queue/"* ) continue ;;
    esac
    size=$(stat -c%s "$f" 2>/dev/null || echo 0)
    mtime=$(stat -c%Y "$f" 2>/dev/null || echo 0)
    # Only hash <=128KB to stay snappy
    if [ "$size" -le 131072 ]; then
      sha=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    else
      sha=""
    fi
    rel="${f#"$ROOT/"}"
    $first || echo ','
    first=false
    printf '{"path":%q,"size":%s,"mtime":%s,"sha256":%q}' "$rel" "$size" "$mtime" "$sha"
  done < <(find "$ROOT" -type f -print0)
  echo '] }'
} > "$MAN_CUR"

# Compute diff vs last manifest
if [ -n "$MAN_LAST" ] && [ -f "$MAN_LAST" ]; then
  python3 - "$MAN_LAST" "$MAN_CUR" <<'PY' > "$RE/sr_diff_'"$TS"'.json"
import json, sys
a=json.load(open(sys.argv[1])); b=json.load(open(sys.argv[2]))
ai={f["path"]:f for f in a.get("files",[])}; bi={f["path"]:f for f in b.get("files",[])}
added=[p for p in bi if p not in ai]
deleted=[p for p in ai if p not in bi]
modified=[p for p in bi if p in ai and (bi[p].get("sha256")!=ai[p].get("sha256") or bi[p]["mtime"]!=ai[p]["mtime"] or bi[p]["size"]!=ai[p]["size"])]
out={"schema":"sr.diff.v0_1","generated_at":sys.argv[2].split("manifest_")[-1].split(".json")[0],
     "base_manifest":sys.argv[1].split("/")[-1],"added":added,"modified":modified,"deleted":deleted,
     "stats":{"files":len(added)+len(modified)+len(deleted)}}
print(json.dumps(out))
PY
else
  cp "$MAN_CUR" "$RE/sr_diff_${TS}_bootstrap.json"
fi

printf '{"generated_at":"%s","tool":"sr_diffscan_v0_1","status":"ok","manifest":"%s"}\n' "$TS" "$(basename "$MAN_CUR")" \
  > "$RE/sr_diffscan_receipt_${TS}.json"
