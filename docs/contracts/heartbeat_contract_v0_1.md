# Heartbeat Contract v0.1

**Purpose**: Give the steward-AI a near-real-time pulse of the laptop + project state without manual uploads.

**What a heartbeat is**
A tiny JSON receipt under `~/static-rooster/receipts/heartbeats/` with:
- UTC timestamp
- disk usage of `static-rooster/`
- counts in `docs/`, `config/`, `bin/`, `forge/`, `receipts/`
- current git branch (if inside a repo)
- last Ark bundle or snapshot seen (if present)
- optional webhook POST result (200/other)

**Schedule**
- Default every 10 minutes via a systemd *user* timer (if available).
- If systemd is unavailable, a crontab entry runs the heartbeat every 10 minutes.

**Files**
- `bin/sr_heartbeat_v0_1.sh` — emit one heartbeat + optional webhook + optional git commit
- `bin/sr_enable_heartbeat_v0_1.sh` — install/enable timer or cron
- `bin/sr_disable_heartbeat_v0_1.sh` — disable timer or cron
- `bin/sr_push_heartbeat_commit_v0_1.sh` — commit new heartbeat receipts to repo (if desired)
- `systemd/user/sr-heartbeat.service` & `sr-heartbeat.timer`

**Environment knobs**
- `HEARTBEAT_INTERVAL_MIN=10` (cron only; systemd uses the timer)
- `HEARTBEAT_WEBHOOK=` (URL; if set, POSTs heartbeat JSON)
- `GIT_PUSH=1` to commit `receipts/heartbeats/*` to the current repo

**Receipts & naming**
- `receipts/heartbeats/sr_heartbeat_YYYY_MM_DDtHH_MM_SSz.json`
- Symlink `receipts/heartbeats/latest.json` updated each run
