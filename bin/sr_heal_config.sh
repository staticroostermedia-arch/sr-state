#!/usr/bin/env bash
set -euo pipefail
CFG="$HOME/static-rooster/config/decisionhub.config.json"
BACK="$HOME/static-rooster/config/decisionhub.config.backup_$(date +%s).json"
cp "$CFG" "$BACK" || true
jq '
  .tools = (
    if has("tools") then
      (if (.tools|type=="array") then .tools
       elif (.tools|type=="object") then (.tools|to_entries|map(.value))
       else [] end)
    else [] end
  )
  | .tools = (
      (.tools + [
        { key:"receipts_timeline",
          name:"Receipts Timeline",
          badge:"v0.1.0",
          category:"ops",
          enabled:true,
          href:"/receipts/receipts_timeline_viewer_v0_1.html?index=/receipts/index_v0_1.json",
          route:"/receipts/receipts_timeline_viewer_v0_1.html?index=/receipts/index_v0_1.json"
        }
      ]) | unique_by(.key)
    )
' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
echo "healed $CFG (backup: $BACK)"
