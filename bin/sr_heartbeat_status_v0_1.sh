#!/usr/bin/env sh
# sr_heartbeat_status_v0_1.sh — report heartbeat health
set -eu
ROOT="${HOME}/static-rooster"
HB_DIR="${ROOT}/receipts/heartbeats"
latest="$HB_DIR/latest.json"

echo "== Heartbeat Status =="
if [ -f "$latest" ]; then
  echo "Latest: $latest"
  ts="$(jq -r '.generated_at_utc' "$latest" 2>/dev/null || date -u -r "$(stat -c %Y "$latest" 2>/dev/null || stat -f %m "$latest" 2>/dev/null)" +"%Y-%m-%dT%H:%M:%SZ")"
  echo "generated_at_utc: ${ts:-unknown}"
  # age in minutes (POSIX awk date diff fallback)
  now_epoch="$(date -u +%s)"
  file_epoch="$(date -u -d "$ts" +%s 2>/dev/null || date -u +%s)"
  age_min="$(( (now_epoch - file_epoch) / 60 ))"
  echo "age_min: $age_min"
  jq -r '.counts | to_entries[] | "\(.key)=\(.value)"' "$latest" 2>/dev/null || true
  jq -r '.git_branch, .last_bundle, .last_snapshot, .webhook_status' "$latest" 2>/dev/null | sed 's/^/info: /' || true
else
  echo "No latest.json found at $latest"
fi

# systemd user timer state
if command -v systemctl >/dev/null 2>&1; then
  echo "== systemd --user timers =="
  systemctl --user list-timers | grep -E 'sr-heartbeat' || echo "(no sr-heartbeat timer found)"
  systemctl --user status sr-heartbeat.timer 2>/dev/null | sed -n '1,12p' || true
else
  echo "systemd not present; using cron if installed."
  crontab -l 2>/dev/null | grep 'sr_heartbeat_v0_1.sh' || echo "(no heartbeat cron entry found)"
fi
