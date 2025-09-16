# State Snapshot Kit v0.1

**Purpose**: give the steward-AI visibility into the *real* state of `~/static-rooster` without manual eyeballing.

- `sr_inventory_scan_v0_1.sh` writes a detailed JSON receipt (sizes, counts, offenders, top 50 files).
- `sr_make_state_snapshot_v0_1.sh` produces a pruned `.tgz` (skips `forge/`, `ark/`, bulky archives).

Run-from-anywhere. Idempotent. All filenames are lowercase snake_case with `t/z` timestamps.
