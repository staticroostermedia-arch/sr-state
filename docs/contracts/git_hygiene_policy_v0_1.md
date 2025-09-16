# Git Hygiene Policy v0.1

- Track: `docs/**`, `config/**`, `bin/**`, `ark/exports/**`, `identity/**`, `*.md` contracts, heartbeats and watch checkpoint.
- Ignore: `receipts/**` (except heartbeats & watch checkpoint), `snapshots/**`, `archives/**`, `quarantine/**`, `forge/**`, `failures/**`, `.venv/**`, `.secrets/**`, `__pycache__/`, `*.log`, `*.tmp`, `*.tgz`.
- Branching: push work onto `stabilize_YYYYMMDD` then PR → `main`.
- Commits: lowercase, present tense, concise; prefix with `chore/feat/fix/docs` as appropriate.
