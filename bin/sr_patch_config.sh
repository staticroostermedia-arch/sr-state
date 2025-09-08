#!/usr/bin/env bash
set -euo pipefail
CFG="$HOME/static-rooster/config/decisionhub.config.json"
TMP="$(mktemp)"
jq '
  .features |= (
    if (.[]?|select(.key=="receipts_timeline")) then . else
      . + [{"key":"receipts_timeline","name":"Receipts Timeline","badge":"v0.1.0","route":"../receipts/receipts_timeline_viewer_v0_1_0.html"}]
    end
  )
  | .features |= (
    if (.[]?|select(.key=="gate_reports")) then . else
      . + [{"key":"gate_reports","name":"Gate Reports","badge":"v0.1.0","route":"../forge/forge_autogate_v0_1_0.html"}]
    end
  )
' "$CFG" > "$TMP" && mv "$TMP" "$CFG"
echo "Patched: $CFG"
