# Cloud Heartbeat Puller (Static Rooster)

This installs:
- `bin/sr_pull_cloud_heartbeat_v0_1.sh` (downloads the latest `cloud_latest` artifact from GitHub Actions)
- systemd user unit `sr-cloud-heartbeat.service` + timer `sr-cloud-heartbeat.timer` (runs every 10 minutes)

## One-time setup

1. Export these env vars in your shell profile (e.g., `~/.bashrc`):
   ```bash
   export GH_OWNER=staticroostermedia-arch
   export GH_REPO=decisionhub
   # If you don't use gh CLI, also set a PAT (repo read permissions):
   # export GH_TOKEN=ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```

2. Enable and start the timer:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now sr-cloud-heartbeat.timer
   systemctl --user list-timers | grep -E 'cloud-heartbeat'
   ```

3. Manual test pull:
   ```bash
   $HOME/static-rooster/bin/sr_pull_cloud_heartbeat_v0_1.sh
   # Expected:
   # Pulled cloud heartbeat to: .../receipts/heartbeats/cloud_latest.json (verdict: match|mismatch|unknown)
   ```

Artifacts will appear in:
`$HOME/static-rooster/receipts/heartbeats/cloud_latest.json`
and a small receipt: `last_pull.json`.
