# Git Hygiene Probe Contract v0.1

Purpose: produce a machine-readable receipt proving the repository's cleanliness and whether the Ark Watcher is active (as inferred from branches/files).

Outputs
- `receipts/probes/sr_git_hygiene_probe_v0_1_<ts>.json`
  - `schema`: "sr.git.hygiene.v0_1"
  - `generated_at_utc`
  - `root`
  - `branch`
  - `dirty` (count of modified/untracked)
  - `ahead`, `behind`
  - `remote_origin`
  - `has_workflow` (ark watcher workflow file present on main)
  - `heartbeat_branches` (array of origin heads matching `chore/heartbeat*`)
  - `cloud_latest_path` (if file `receipts/heartbeats/cloud_latest.json` exists on origin/main tree)
  - `verdict`: one of ["clean-ready", "dirty", "needs-workflow", "no-heartbeat"]

The probe is *read-only* and idempotent.
