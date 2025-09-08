#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
ARK="$ROOT/ark/current"
stage() { local s="$1"; [ -d "$ARK/$s" ] && rsync -a --delete "$ARK/$s/" "$ROOT/$s/" || echo "skip: $s"; }
stage hub_registry; stage decisionhub; stage forge; stage receipts; stage canon; stage tools; stage docs; stage indices
[ -f "$ARK/decisionhub/decisionhub_config_v0_7.json" ] && \
  cp -f "$ARK/decisionhub/decisionhub_config_v0_7.json" "$ROOT/config/decisionhub.config.json"
echo "Hub/DecisionHub refreshed from Ark."
