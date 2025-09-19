#!/usr/bin/env bash
# Verifies launcher pin, ingest service, tunnel base, and SR Share wiring.
set -euo pipefail
ROOT="$HOME/static-rooster"; DEC="$ROOT/decisionhub"; REC="$ROOT/receipts"; TS="$(date -u +%Y-%m-%dT%H_%M_%SZ)"
mkdir -p "$REC"

out(){ printf '%-28s %s\n' "$1" "$2"; }

# 1) Launcher pin
ln -sf "start_here_v0_3.html" "$DEC/start_here.html" 2>/dev/null || true
TITLE="$(curl -fsS 'http://127.0.0.1:8888/decisionhub/start_here.html?v=003' 2>/dev/null | sed -n 's:.*<title>\(.*\)</title>.*:\1:p' | head -1 || true)"
out "DecisionHub title:" "${TITLE:-missing}"

# 2) Ingest service status
ING_PID="$(pgrep -af 'sr_ingest_echo_.*\.py' | tail -1 || true)"
out "Ingest process:" "${ING_PID:-not running}"
# Try to wake it
ARK_JSON="$(curl -s -m 10 -X POST http://127.0.0.1:8891/make-ark -H 'content-type: application/json' --data '{}' || true)"
OK=$([ -n "$ARK_JSON" ] && echo ok || echo fail)
out "POST /make-ark:" "$OK"

# 3) Tunnel base
BASE="$(cat "$ROOT/share/public_url.txt" 2>/dev/null || true)"
out "public_url.txt:" "${BASE:-missing}"
# 4) SR Share wiring
QS="$ROOT/share/quick_share_v0_4.html"
NAV=$([ -f "$QS" ] && grep -q 'topnav_v0_1.html' "$QS" && echo yes || echo no)
out "SR Share topnav:" "$NAV"

cat > "$REC/sr_done_receipt_doctor_${TS}.json" <<JSON
{"schema":"sr.done_receipt.v0_1","tool_name":"sr_doctor","status":"ok","generated_at_utc":"$TS",
 "summary":"doctor ran","observations":{"title":"$TITLE","ingest":"$ING_PID","public_url":"$BASE","share_nav":"$NAV"}}
JSON
