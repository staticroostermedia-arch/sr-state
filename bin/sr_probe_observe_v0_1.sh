#!/usr/bin/env bash
set -euo pipefail
ROOT="${SR_ROOT:-$HOME/static-rooster}"
BEACON="$ROOT/public/state/state_beacon_v0_1.json"
OUT="$ROOT/receipts/sr_done_receipt_observe_$(date -u +%Y%m%dT%H%M%SZ)_v0_1.json"

# facts
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
seq="$(jq -r .seq "$BEACON" 2>/dev/null || echo null)"
aqueduct_200="no"
git_ok="no"
remote_url="(none)"

# probe aqueduct
if curl -fsS -I "http://127.0.0.1:8000/public/state/state_beacon_v0_1.json" | head -1 | grep -q "200"; then
  aqueduct_200="yes"
fi

# probe git remote
if [ -d "$ROOT/public/state/.git" ]; then
  remote_url="$(git -C "$ROOT/public/state" remote get-url origin 2>/dev/null || echo '(none)')"
  if git -C "$ROOT/public/state" ls-remote origin >/dev/null 2>&1; then
    git_ok="yes"
  fi
fi

# verdict
verdict="foedus intactum"
notes=()
[ -f "$BEACON" ] || { verdict="foedus fractum"; notes+=("no beacon file"); }
[ "$aqueduct_200" = "yes" ] || { verdict="foedus fractum"; notes+=("aqueduct not 200"); }
[ "$git_ok" = "yes" ] || notes+=("git remote not reachable")

# emit receipt
jq -n \
  --arg ts "$ts" \
  --arg v "$verdict" \
  --argjson seq "$seq" \
  --arg aqueduct "$aqueduct_200" \
  --arg remote "$remote_url" \
  --arg notes "$(IFS=';'; echo "${notes[*]-}")" \
  '{
    schema:"sr.observe_probe.v0_1",
    issued_at_utc:$ts,
    beacon_seq:$seq,
    aqueduct_200:$aqueduct,
    git_remote:$remote,
    verdict:$v,
    notes:$notes
  }' | tee "$OUT" >/dev/null

echo "[PROBE] verdict: $verdict"
echo "[PROBE] wrote:   $OUT"
