#!/usr/bin/env bash
set -euo pipefail
ROOT="${SR_ROOT:-$HOME/static-rooster}"
LOG="$ROOT/logs/cycle_$(date -u +%Y%m%dT%H%M%SZ).log"
mkdir -p "$ROOT/logs" "$ROOT/receipts"

say() { printf "[%s] %s\n" "$(date -u +%H:%M:%SZ)" "$*" | tee -a "$LOG" ; }

say "=== Tick→Tock cycle begin ==="

# 1) Aqueduct up (serves ./public)
say "Aqueduct: start & health-check"
"$ROOT/bin/sr_aqueduct_up.sh" | tee -a "$LOG"

# 2) Observe probe (read-only status; emits receipt)
say "Probe: observe"
"$ROOT/bin/sr_probe_observe_v0_1.sh" | tee -a "$LOG"

# 3) Crystallize Watch Checkpoint (auto-verdict based on aqueduct probe)
say "Checkpoint: crystallize"
"$ROOT/bin/sr_watch_checkpoint_emit_v0_1.sh" | tee -a "$LOG"

# 4) Optional: publish beacon to Git (no-op if nothing changed)
if [ -x "$ROOT/bin/sr_publish_git.sh" ]; then
  say "Publish: git push (if changes)"
  "$ROOT/bin/sr_publish_git.sh" | tee -a "$LOG"
else
  say "Publish: skipped (no sr_publish_git.sh)"
fi

# 5) Summary: show newest receipts & beacon seq
say "Summary:"
ls -lt "$ROOT/receipts" | head -n 6 | tee -a "$LOG" || true
printf "beacon seq: " | tee -a "$LOG"
jq -r .seq "$ROOT/public/state/state_beacon_v0_1.json" | tee -a "$LOG"

say "=== Tick→Tock cycle end ==="
