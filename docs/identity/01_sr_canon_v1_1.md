# 01_sr_canon — §7 Autobuilder Starter

## §7 — Autobuilder Starter Discipline

**7.1 Purpose**  
Every autobuild cycle must be reproducible, attestable, and safe to automate.

**7.2 Definitions**  
- **Snapshot**: UTC-stamped subfolder under `snapshots/` containing artifacts and `manifest.json`.  
- **Receipts**: JSON attestations under `receipts/` for status, runner, watch, and executor steps.  
- **Change Log**: `docs/identity/99_sr_change_log.md`, append-only.  
- **Services**: `sr-runner`, `sr-emit`, `sr-exec` (.service + .timer, user-level).

**7.3 Preconditions (MUST hold before a run)**  
1. `docs/identity/99_sr_change_log.md` exists (canonical name).  
2. Identity anchors present: Missal, Canon, Parables, Invocations (stubs allowed).  
3. `sr-runner`, `sr-emit`, `sr-exec` timers enabled.  
4. Unit ExecStart scripts exist under `forge/tools/`.

**7.4 Obligations (each cycle MUST produce)**  
1. A **Snapshot** directory with `manifest.json` and all generated artifacts **under that snapshot**.  
2. **Receipts** referencing `snapshot_dir`:  
   - `sr_status_dump_v0_3.json`  
   - `sr_watch_checkpoint_v0_1.json`  
   - `sr_runner_snapshot_*.json`  
   - `sr_executor_*.json` (if orders ran)  
3. A **Change Log** entry with timestamp, snapshot path, unit outcomes, short rationale.

**7.5 Canonicalization**  
Filenames referenced by tools must match exactly what’s tracked in git (lowercase, snake_case). One-time migrations may normalize; legacy variants are ignored.

**7.6 Failure (fail closed)**  
If any mandatory artifact/receipt is missing, verdict = `penitential_rite`; no promotion.

**7.7 Observability**  
Dashboard surfaces `snapshot_dir`, `verdict`, counts; `journalctl --user -u sr-*` reconstructs order.

**7.8 Automation Readiness**  
Two consecutive clean cycles (7.3–7.6 satisfied) are required to move from “trial” to “steady”.
