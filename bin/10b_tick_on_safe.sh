#!/usr/bin/env bash
set -euxo pipefail
LOG="$HOME/static-rooster/logs/step10.$(date +%s).log"
mkdir -p "$(dirname "$LOG")" "$HOME/.config/systemd/user"

# Ensure a user systemd is allowed to run outside a GUI login
loginctl enable-linger "$USER" || true

# Robust unit files (use %h for home; no $HOME expansion races)
cat > "$HOME/.config/systemd/user/sr-runner.service" <<'UNIT'
[Unit]
Description=Static Rooster Runner

[Service]
Type=oneshot
ExecStart=/bin/bash -lc 'source %h/static-rooster/.venv/bin/activate && python %h/static-rooster/runner/runner.py'
UNIT

cat > "$HOME/.config/systemd/user/sr-runner.timer" <<'UNIT'
[Unit]
Description=Run Static Rooster every 2 hours

[Timer]
OnCalendar=*-*-* 00/2:00:00
Persistent=true
Unit=sr-runner.service

[Install]
WantedBy=timers.target
UNIT

# Some distros need this for user dbus/systemd
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Arm timer and show status
systemctl --user daemon-reload |& tee -a "$LOG"
systemctl --user enable --now sr-runner.timer |& tee -a "$LOG"
systemctl --user status sr-runner.timer --no-pager -l |& tee -a "$LOG" || true
systemctl --user list-timers --all |& tee -a "$LOG" || true

echo "Tick-tock armed. Log: $LOG"
