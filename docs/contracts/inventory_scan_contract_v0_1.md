# Inventory Scan Contract v0.1

Purpose: produce a machine-readable snapshot of the Static Rooster workspace so the steward-AI can anchor on *facts* (not vibes) before acting.

Output:
- `receipts/inventory/sr_inventory_<ts>.json` with fields:
  - `schema`: "sr.inventory.v0_1"
  - `generated_at_utc`
  - `root`: absolute path scanned
  - `bytes_total`
  - `counts`: { files, dirs, docs, config, bin, receipts, snapshots }
  - `git`: { branch, dirty, ahead, behind, untracked }
  - `timers`: { heartbeat_timer, core_snapshot_timer }
  - `latest_snapshot`: { path, bytes }
  - `offenders`: { uppercase: [], spaces: [], large_files: [], bad_ext: [] }  // truncated lists
  - `top_heavy`: [ { path, bytes } ]  // biggest top-level dirs
- A human-readable summary is printed to stdout.

Rules:
- Never delete; read-only.
- Truncate offender lists to avoid megabyte receipts (default 50 entries each).
- Lowercase snake_case is preferred (`^[a-z0-9._/-]+$`).

