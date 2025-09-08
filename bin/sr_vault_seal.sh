#!/usr/bin/env bash
set -euo pipefail
. "$HOME/static-rooster/bin/sr_secrets_load.sh" || true
RECIP="${SR_GPG_RECIPIENT:-}"
[ -z "$RECIP" ] && { echo "Set SR_GPG_RECIPIENT in secrets/.env"; exit 2; }
gpg --yes --encrypt --recipient "$RECIP" \
  --output "$HOME/static-rooster/ark/secrets/secrets.env.gpg" \
  "$HOME/static-rooster/secrets/.env"
echo "sealed → ark/secrets/secrets.env.gpg"
