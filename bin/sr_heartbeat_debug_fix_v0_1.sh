#!/usr/bin/env sh
# sr_heartbeat_debug_fix_v0_1.sh — common fixes for user timers and cron
set -eu
USER_NAME="$(id -un)"
echo "== Debug & Fix =="
if command -v systemctl >/dev/null 2>&1; then
  echo "-- Enabling user lingering (allows timers when you log out)"
  if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$USER_NAME" || true
  fi
  echo "-- Reloading and restarting timer"
  systemctl --user daemon-reload || true
  systemctl --user enable --now sr-heartbeat.timer || true
  systemctl --user status sr-heartbeat.timer | sed -n '1,12p' || true
else
  echo "-- Ensuring cron entry exists (every 10 min)"
  ROOT="${HOME}/static-rooster"
  (crontab -l 2>/dev/null | grep -v 'sr_heartbeat_v0_1.sh' || true; echo "*/10 * * * * HEARTBEAT_WEBHOOK=${HEARTBEAT_WEBHOOK:-} ${ROOT}/bin/sr_heartbeat_v0_1.sh >/dev/null 2>&1") | crontab -
  crontab -l | grep 'sr_heartbeat_v0_1.sh' || echo "(cron not installed?)"
fi
echo "Done."
