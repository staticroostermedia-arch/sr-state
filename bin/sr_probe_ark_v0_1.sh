#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
REC="$ROOT/receipts"
ARK="$ROOT/share/ark/latest.tgz"
PUB="$ROOT/share/public_url.txt"
ING="http://127.0.0.1:8891"
TS="$(date -u +%Y-%m-%dT%H_%M_%SZ)"
mkdir -p "$REC"

echo "[probe] POST /make-ark (lite)…"
JSON="$(curl -s -m 90 -X POST "$ING/make-ark" -H 'content-type: application/json' --data '{"mode":"lite"}' || true)"
[ -n "$JSON" ] && echo "[ingest] $JSON"

[ -f "$ARK" ] || { echo "[ERR] $ARK not found after make-ark"; exit 2; }

# size + sha256
size=$(command -v stat >/dev/null && stat -c %s "$ARK" || wc -c <"$ARK")
sha256=$( (command -v sha256sum >/dev/null && sha256sum "$ARK" | awk '{print $1}') || (openssl dgst -sha256 "$ARK" | awk '{print $2}') )
printf '%s  %s\n' "$sha256" "latest.tgz" > "$ROOT/share/ark/latest.sha256.txt"

base="$(cat "$PUB" 2>/dev/null || true)"; base="${base%/}"
link="${base}/share/ark/latest.tgz"
manifest="${base}/share/ark/latest.json"

block=$(cat <<TXT
SR Ark
Mode: lite
Link: $link
SHA256: $sha256
Size(bytes): $size
Manifest: $manifest
TXT
)
echo "$block"
command -v xclip >/dev/null && printf '%s' "$block" | xclip -selection clipboard || true
command -v xsel  >/dev/null && printf '%s' "$block" | xsel --clipboard       || true

printf '%s\n' "$(cat <<JSON
{"schema":"sr.done_receipt.v0_1","tool_name":"sr_probe_ark","status":"ok",
 "generated_at_utc":"$TS","summary":"$size bytes • $sha256","observations":{"ark":"$ARK"}}
JSON
)" > "$REC/sr_done_receipt_probe_ark_${TS}.json"
echo "[ok] Share block printed (and copied if clipboard tool present)."
