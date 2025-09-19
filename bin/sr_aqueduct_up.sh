#!/usr/bin/env bash
set -euo pipefail
ROOT="${SR_ROOT:-$HOME/static-rooster}"
LOG="$ROOT/logs/aqueduct.log"
BEACON="$ROOT/public/state/state_beacon_v0_1.json"
cd "$ROOT"

# ensure beacon exists
if [ ! -f "$BEACON" ]; then
  if [ -x "$ROOT/bin/sr_emit_state_beacon_v0_1.sh" ]; then
    "$ROOT/bin/sr_emit_state_beacon_v0_1.sh"
  else
    echo "[ERR] beacon emitter missing: $ROOT/bin/sr_emit_state_beacon_v0_1.sh" >&2
    exit 2
  fi
fi

# kill any previous server
pkill -f "python3 -m http.server 8000" 2>/dev/null || true

# start fresh
python3 -m http.server 8000 >"$LOG" 2>&1 &
sleep 2

# health check
if curl -fsS -I "http://127.0.0.1:8000/public/state/state_beacon_v0_1.json" | head -1 | grep -q "200"; then
  echo "[OK] aqueduct up; beacon reachable"
  exit 0
else
  echo "[FAIL] aqueduct not serving beacon; see $LOG" >&2
  exit 1
fi
