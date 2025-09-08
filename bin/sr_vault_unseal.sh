#!/usr/bin/env bash
set -euo pipefail
gpg --decrypt "$HOME/static-rooster/ark/secrets/secrets.env.gpg" > "$HOME/static-rooster/secrets/.env"
chmod 600 "$HOME/static-rooster/secrets/.env"
echo "unsealed → secrets/.env"
