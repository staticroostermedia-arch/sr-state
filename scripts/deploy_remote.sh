#!/usr/bin/env bash
set -euo pipefail
REMOTE="${1:-}"
PORT="${2:-8000}"
if [[ -z "$REMOTE" ]]; then
  echo "Usage: bash scripts/deploy_remote.sh user@host [:path] [port]"
  exit 1
fi
APP_DIR="${HOME}/static-rooster"
DIST="${APP_DIR}/dist"
ssh "$REMOTE" "mkdir -p ~/static-rooster"
rsync -avz --delete "$DIST/" "$REMOTE:~/static-rooster/dist/"
ssh "$REMOTE" "cat > ~/.config/systemd/user/static-rooster.service <<EOF
[Unit]
Description=Static Rooster Pip‑Boy Server
After=network.target
[Service]
Type=simple
WorkingDirectory=%h/static-rooster/dist
ExecStart=/usr/bin/env python3 -m http.server ${PORT}
Restart=on-failure
[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload && systemctl --user enable --now static-rooster.service || true
"
echo "[*] Deployed to $REMOTE (port ${PORT})"
