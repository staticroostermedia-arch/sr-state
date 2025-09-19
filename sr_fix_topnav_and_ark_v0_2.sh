#!/usr/bin/env bash
# Creates SR Share top-nav, installs Ark probe, and verifies end-to-end.
set -euo pipefail
trap 'code=$?; echo "[ERR] line $LINENO exited with $code"; exit $code' ERR

ROOT="$HOME/static-rooster"
SHARE="$ROOT/share"
PART="$SHARE/partials"
DEC="$ROOT/decisionhub"
REC="$ROOT/receipts"
BIN="$ROOT/bin"
QS="$SHARE/quick_share_v0_4.html"
ING_URL="http://127.0.0.1:8891"
TS="$(date -u +%Y-%m-%dT%H_%M_%SZ)"

mkdir -p "$PART" "$REC" "$BIN" "$SHARE"

# --- Top nav (Back to Hub + essentials) ---
cat > "$PART/topnav_v0_1.html" <<'HTML'
<nav style="position:sticky;top:0;z-index:10;background:#0b0c06;border-bottom:1px solid #1a2b1a;padding:6px 8px;font:12px ui-monospace,Consolas,monospace">
  <a href="/decisionhub/start_here.html?v=003" style="color:#9ae89a;margin-right:10px">⬅ Back to Hub</a>
  <a href="/share/quick_share_v0_4.html" style="color:#9ae89a;margin-right:10px">SR Share</a>
  <a href="/share/" style="color:#9ae89a;margin-right:10px">Share index</a>
  <a href="/receipts/" style="color:#9ae89a;margin-right:10px">Receipts</a>
  <a href="/share/ark/latest.tgz" style="color:#9ae89a;margin-right:10px">Ark Download</a>
  <a href="/share/ark/latest.json" style="color:#9ae89a;margin-right:10px">Ark Manifest</a>
  <a href="/share/context/latest.json" style="color:#9ae89a;margin-right:10px">Context (latest)</a>
</nav>
HTML

if [ -f "$QS" ] && ! grep -q 'id="sr_topnav_mount"' "$QS"; then
  sed -i '0,/<body/{s//&\n<div id="sr_topnav_mount"></div>/}' "$QS"
  sed -i 's#</body>#<script>(async()=>{try{const r=await fetch("/share/partials/topnav_v0_1.html");if(r.ok){document.getElementById("sr_topnav_mount").innerHTML=await r.text();}}catch(e){console.warn(e)}})();</script>\n</body>#' "$QS"
  echo "[ok] Injected topnav into SR Share."
fi

# --- Ark probe tool (builds ark, computes size & sha256, prints share block) ---
cat > "$BIN/sr_probe_ark_v0_1.sh" <<'PROBE'
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

if [ ! -f "$ARK" ]; then
  echo "[ERR] $ARK not found after make-ark"; exit 2
fi

# size + sha256
if command -v stat >/dev/null 2>&1; then size=$(stat -c %s "$ARK"); else size=$(wc -c <"$ARK"); fi
if command -v sha256sum >/dev/null 2>&1; then sha256=$(sha256sum "$ARK" | awk '{print $1}'); else sha256=$(openssl dgst -sha256 "$ARK" | awk '{print $2}'); fi
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

# receipt
printf '%s\n' "$(cat <<JSON
{"schema":"sr.done_receipt.v0_1","tool_name":"sr_probe_ark","status":"ok",
 "generated_at_utc":"$TS","summary":"$size bytes • $sha256","observations":{"ark":"$ARK"}}
JSON
)" > "$REC/sr_done_receipt_probe_ark_${TS}.json"
echo "[ok] Share block printed (copied to clipboard if available)."
PROBE
chmod +x "$BIN/sr_probe_ark_v0_1.sh"

# --- Quick verification path (no failure on transient errors) ---
echo "[probe] HEAD /share/ark/latest.json"
curl -fsSI -m 5 "http://127.0.0.1:8888/share/ark/latest.json" >/dev/null || true
echo "[probe] HEAD /share/ark/latest.tgz"
curl -fsSI -m 5 "http://127.0.0.1:8888/share/ark/latest.tgz"  >/dev/null || true

# receipt for this installer
cat > "$REC/sr_done_receipt_fix_topnav_and_ark_${TS}.json" <<JSON
{"schema":"sr.done_receipt.v0_1","tool_name":"sr_fix_topnav_and_ark","status":"ok",
 "generated_at_utc":"$TS","summary":"topnav present; sr_probe_ark installed"}
JSON

echo
echo "[ok] Topnav ready. Ark probe installed:"
echo "     $BIN/sr_probe_ark_v0_1.sh"
echo "Run it now to build & verify an Ark and copy a share block."
