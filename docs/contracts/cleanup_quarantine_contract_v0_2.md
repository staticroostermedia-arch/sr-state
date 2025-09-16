# Cleanup & Quarantine Contract v0.2

**Goal:** Normalize the Static Rooster workspace without destructive surprises.

- **Default mode:** DRY-RUN. Reports offenders and writes a receipt. No changes.
- **Apply changes:** `SR_APPLY=1` — move offenders into `quarantine/<ts>/forge/` (mirrors original paths).
- **Purge:** `SR_PURGE=1` — permanently delete the *current* quarantine batch after a separate receipt.
- **Scope:** filenames only. Targets:
  - Paths containing uppercase letters.
  - Paths containing whitespace.
  - Paths with characters outside `^[a-z0-9._/-]+$`.
- **Excludes:** `.git`, `.venv`, `receipts/`, `snapshots/`, `quarantine/`, `archives/`, `failures/`, `forge/`, `support/logs/`.
- **Receipts:** `receipts/sr_done_receipt_cleanup_v0_2.json` with counts, truncated lists, and ts.
- **Idempotent:** multiple runs safe. Moves preserve relative structure under `forge/`.
