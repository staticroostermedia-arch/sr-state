# Canonical Rename Contract v0.1

**Goal:** Normalize filenames to Static Rooster canonical form *in-place* using version-control-aware moves.

- Canonical rule (basename only): 
  - Lowercase.
  - Replace whitespace with `_`.
  - Allow only `[a-z0-9._-]` in names (path separators `/` preserved).
  - Collapse repeated `_` and trim leading/trailing `_`.
- Scope: `~/static-rooster` excluding `.git`, `.venv`, `receipts/`, `snapshots/`, `quarantine/`, `archives/`, `failures/`, `forge/`, `support/logs/`.
- DRY-RUN by default. Set `SR_APPLY=1` to perform `git mv` (if tracked) or `mv` (if untracked).
- Receipts:
  - `receipts/renames/sr_rename_plan_v0_1_<ts>.json` (original → canonical pairs).
  - `receipts/renames/sr_done_receipt_rename_v0_1_<ts>.json` (applied results).
- Change log: append human-readable mapping to `99_sr_change_log.md`.
- Idempotent: running again on a clean tree does nothing.
