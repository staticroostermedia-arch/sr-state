#!/usr/bin/env bash
set -euo pipefail
systemctl --user start sr-ticktock.service
journalctl --user -u sr-ticktock.service -n 80 --no-pager || true
