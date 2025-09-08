#!/usr/bin/env bash
set -euo pipefail
ENVF="$HOME/static-rooster/secrets/.env"
[ -f "$ENVF" ] && set -a && . "$ENVF" && set +a || echo "note: $ENVF missing"
