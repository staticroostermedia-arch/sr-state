#!/usr/bin/env bash
set -euo pipefail
R="$HOME/static-rooster"
CFG="$R/config/decisionhub.config.json"

echo "— server check —"
curl -sI http://localhost:8888/ | head -n1
echo "— config check —"
curl -sI http://localhost:8888/config/decisionhub.config.json | head -n1
jq -r '"title=\(.title // "n/a"), tools=\(.tools|length)"' "$CFG"

echo "— tiles —"
jq -c '.tools[] | {key,href:(.href//""),route:(.route//"")}' "$CFG" |
while read -r line; do
  key=$(jq -r .key <<<"$line")
  url=$(jq -r '.href // ""' <<<"$line"); [ -z "$url" ] && url=$(jq -r '.route // ""' <<<"$line")
  [ -z "$url" ] && { echo "$key: NO URL"; continue; }
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8888${url#http://localhost:8888}")
  echo "$key: $url -> HTTP $code"
done
