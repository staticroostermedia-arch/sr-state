#!/usr/bin/env bash
set -euo pipefail
CFG="$HOME/static-rooster/config/decisionhub.config.json"
mkdir -p "$(dirname "$CFG")"

# If the file is empty or invalid, seed a minimal config
if ! jq . "$CFG" >/dev/null 2>&1; then
  cat > "$CFG" <<'JSON'
{ "version":"v0.7", "title":"DecisionHub", "features":[] }
JSON
fi

TMP="$(mktemp)"
jq '
  .version |= (. // "v0.7") |
  .title   |= (. // "DecisionHub") |
  .features |= (. // []) |
  ( .features[]? | select(.key=="receipts_timeline") ) as $have
  | if $have then
      (.features |= map( if .key=="receipts_timeline"
        then .name = (.name // "Receipts Timeline")
             | .badge = (.badge // "v0.1.0")
             | .route = "../receipts/receipts_timeline_viewer_v0_1_0.html?index=/receipts/index_v0_1.json"
        else . end ))
    else
      (.features += [{
        "key":"receipts_timeline",
        "name":"Receipts Timeline",
        "badge":"v0.1.0",
        "route":"../receipts/receipts_timeline_viewer_v0_1_0.html?index=/receipts/index_v0_1.json"
      }])
    end
' "$CFG" > "$TMP" && mv "$TMP" "$CFG"
echo "Patched: $CFG"
