# Cleanup Quarantine Contract v0.2

Purpose: normalize repo state by handling offender files (uppercase, spaces, bad extensions, large files).

Rules:
- Input: latest inventory JSON at `receipts/inventory/sr_inventory_*.json`.
- Non-destructive by default: offenders are moved to `quarantine/<ts>/` preserving relative paths.
- Destructive only if steward sets `SR_PURGE=1` in environment; then files are deleted.
- Always write a receipt in `receipts/` documenting what was moved or purged.
- Offender categories: uppercase, spaces, bad_ext, large_files.
- Quarantined files should maintain directory structure relative to repo root.
- Script idempotent: can be rerun safely; already moved files are skipped.
