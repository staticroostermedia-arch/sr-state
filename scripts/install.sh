#!/usr/bin/env bash
set -euo pipefail

APP_NAME="static-rooster"
INSTALL_DIR="${HOME}/${APP_NAME}"
PORT="${PORT:-8000}"
REPO_URL="${REPO_URL:-}"

echo "[*] Installing Static Rooster Pip‑Boy to ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
# Copy payload directory next to this script into INSTALL_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
rsync -a --exclude 'dist' --exclude '.git' "${SCRIPT_DIR}/" "${INSTALL_DIR}/"

cd "${INSTALL_DIR}"

# Build dist (static site)
if [ -f scripts/build.sh ]; then
  bash scripts/build.sh
fi

# Create venv only if you want a richer server; for static files we can use Python http.server
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

# Create a simple systemd service if systemd exists
if pidof systemd >/dev/null 2>&1 && [ -d /etc/systemd/system ]; then
  SERVICE_FILE="${HOME}/.config/systemd/user/${APP_NAME}.service"
  mkdir -p "$(dirname "${SERVICE_FILE}")"
  cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Static Rooster Pip‑Boy Server
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/${APP_NAME}/dist
ExecStart=/usr/bin/env python3 -m http.server ${PORT}
Restart=on-failure

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now ${APP_NAME}.service || true
  echo "[*] Started user service: ${APP_NAME}.service on port ${PORT}"
else
  echo "[*] Launching local server on port ${PORT} (no systemd detected)"
  (cd dist && python3 -m http.server "${PORT}") &
  echo $! > "${INSTALL_DIR}/server.pid"
fi

# Initialize Git repo and push if REPO_URL given
if [ ! -d .git ]; then
  git init
  git branch -M main || git checkout -b main
fi
git add -A
git commit -m "Initial import via installer" || true

if [ -n "${REPO_URL}" ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "${REPO_URL}"
  else
    git remote add origin "${REPO_URL}"
  fi
  git push -u origin main || true
  echo "[*] Pushed to ${REPO_URL}"
else
  echo "[*] No REPO_URL provided; repository initialized locally."
fi

echo
echo "=== Installation Complete ==="
echo "Open: http://localhost:${PORT}/"
echo "Apps index: http://localhost:${PORT}/apps/EH1003006_DecisionHub_index_v3_2_1.html"
