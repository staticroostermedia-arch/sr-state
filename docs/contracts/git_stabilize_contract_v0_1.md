# Git Stabilize Contract v0.1

Goal: make the Ark repo pushable again without dragging receipts/snapshots noise.

This installer will:
- Create a safety backup `.tgz` of `~/static-rooster`.
- Ensure there is a Git repo; create branch `stabilize/YYYYMMDD`.
- Write `.gitignore` that **keeps** canon, docs, config, bin, ark exports, heartbeats;
  and **ignores** receipts (except heartbeats & watch checkpoints), snapshots, archives,
  .venv, quarantine, failures, and forge outputs.
- `git add -A` (additions + deletions), commit, set SSH origin, push branch.
- Print follow-up commands to make a PR into `main` (or fast-forward if desired).
