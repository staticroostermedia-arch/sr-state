#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
BIN="${ROOT}/bin"
RECEIPTS="${ROOT}/receipts"

echo "[order] start: $(date -u +'%Y-%m-%dT%H:%M:%SZ')" | tee -a "${RECEIPTS}/order.log"

# 1) Apply build plan if present (no-op if missing)
if [ -s "${ROOT}/build/plan_v0_1.txt" ] && [ -x "${BIN}/sr_build_plan_run_v0_1.sh" ]; then
  "${BIN}/sr_build_plan_run_v0_1.sh" "${ROOT}/build/plan_v0_1.txt" 2>&1 | tee -a "${RECEIPTS}/order.log"
else
  echo "[order] build plan skipped (missing plan or tool)" | tee -a "${RECEIPTS}/order.log"
fi

# 2) Watch Checkpoint
if [ -x "${BIN}/sr_watch_checkpoint_v0_1.sh" ]; then
  "${BIN}/sr_watch_checkpoint_v0_1.sh" 2>&1 | tee -a "${RECEIPTS}/order.log"
fi

# 3) Snapshot (Ark)
if [ -x "${BIN}/sr_snapshot_v0_1.sh" ]; then
  "${BIN}/sr_snapshot_v0_1.sh" 2>&1 | tee -a "${RECEIPTS}/order.log"
fi

# 4) Status dump for dashboard cards
if [ -x "${BIN}/sr_status_dump_v0_3.sh" ]; then
  "${BIN}/sr_status_dump_v0_3.sh" 2>&1 | tee -a "${RECEIPTS}/order.log"
fi

echo "[order] done: $(date -u +'%Y-%m-%dT%H:%M:%SZ')" | tee -a "${RECEIPTS}/order.log"
