#!/usr/bin/env bash
set -euo pipefail
ROOT="${SR_ROOT:-$HOME/static-rooster}"
OUT="$ROOT/receipts/sr_watch_checkpoint_$(date -u +%Y%m%dT%H%M%SZ)_v0_1.json"
BEACON="$ROOT/public/state/state_beacon_v0_1.json"

seq=$(jq -r .seq "$BEACON" 2>/dev/null || echo 0)
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# probe aqueduct -> 200?
if curl -fsS -I "http://127.0.0.1:8000/public/state/state_beacon_v0_1.json" | head -1 | grep -q "200"; then
  verdict="foedus intactum"
  note="aqueduct 200; beacon present"
else
  verdict="foedus fractum"
  note="aqueduct probe failed or no beacon"
fi

jq -n --arg ts "$ts" --arg v "$verdict" --arg note "$note" --argjson seq "$seq" '{
  schema:"sr.watch_checkpoint.v0_1",
  id: ("watch_checkpoint_"+($ts|gsub("[-:T]";"")|.[0:15])+"_v0_1"),
  issued_at_utc:$ts,
  beacon_seq:$seq,
  verdict:$v,
  notes:$note
}' | tee "$OUT" >/dev/null

echo "[OK] wrote $OUT"
