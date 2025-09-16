#!/usr/bin/env sh
# sr_disable_heartbeat_v0_1.sh — disable scheduled heartbeat
set -eu
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now sr-heartbeat.timer || true
  echo "Disabled systemd user timer."
else
  crontab -l 2>/dev/null | grep -v 'sr_heartbeat_v0_1.sh' | crontab - || true
  echo "Removed cron entry."
fi
