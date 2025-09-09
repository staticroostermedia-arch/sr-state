#!/usr/bin/env bash
set -euo pipefail
systemctl --user list-timers | grep -E 'sr-ticktock'
ls -1t "$HOME/static-rooster/receipts"/sr_watch_checkpoint_*_v0_1.json 2>/dev/null | head -n 3
