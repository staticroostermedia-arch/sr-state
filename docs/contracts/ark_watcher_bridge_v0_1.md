# Ark Watcher Bridge (v0.1)

**Purpose**  
Keep Git (steward's source of truth) and the Assistant (rehydration target) in lockstep by packaging the Ark on every push and committing bundles under `ark/exports/`.

**What this does**
- On push to `main`, GitHub Actions:
  - Runs `bin/sr_make_ark_bundle_v0_1.sh` to create:
    - `ark/exports/ark_bundle_YYYY_MM_DDtHH_MM_SS_z.tgz`
    - `ark/exports/ark_bundle_YYYY_MM_DDtHH_MM_SS_z.run` (self-extracting)
    - `ark/exports/ark_bundle_*.sha256`
  - Commits and pushes these artifacts back to the repo via the `GITHUB_TOKEN`.
- Optional: if `PUSH_WEBHOOK_URL` secret is set, it POSTs a JSON notice containing the filenames and sha256 so other systems can ingest.

**Why commit artifacts to the repo?**  
- Keeps everything audit-friendly and private within your repo permissions.
- Gives you a stable URL path (per commit) to retrieve the latest Ark.

**No destructive behavior**  
- Bundles are append-only; pruning is handled by your weekly deduper.

**Files installed by this bridge**  
- `.github/workflows/ark_watcher_v0_1.yml`
- `bin/sr_make_ark_bundle_v0_1.sh`
- `bin/sr_push_ark_commit_v0_1.sh`
