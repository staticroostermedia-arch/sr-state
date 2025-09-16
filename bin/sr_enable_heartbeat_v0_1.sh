#!/usr/bin/env sh
# sr_enable_heartbeat_v0_1.sh — enable scheduled heartbeat (systemd user timer or cron fallback)
set -eu
ROOT="${HOME}/static-rooster"
SYS_UNIT_DIR="${ROOT}/systemd/user"
INTERVAL="${HEARTBEAT_INTERVAL_MIN:-10}"

if command -v systemctl >/dev/null 2>&1; then
  # systemd user timer
  mkdir -p "$HOME/.config/systemd/user"
  cp "$SYS_UNIT_DIR/sr-heartbeat.service" "$HOME/.config/systemd/user/"
  cp "$SYS_UNIT_DIR/sr-heartbeat.timer" "$HOME/.config/systemd/user/"
  systemctl --user daemon-reload
  systemctl --user enable --now sr-heartbeat.timer
  echo "Enabled systemd user timer: sr-heartbeat.timer (every 10min)"
else
  # cron fallback
  (crontab -l 2>/dev/null | grep -v 'sr_heartbeat_v0_1.sh' || true; echo "*/${INTERVAL} * * * * HEARTBEAT_WEBHOOK=${HEARTBEAT_WEBHOOK:-} ${ROOT}/bin/sr_heartbeat_v0_1.sh >/dev/null 2>&1") | crontab -
  echo "Installed crontab entry to run every ${INTERVAL} minutes."
fi
