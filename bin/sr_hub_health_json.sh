#!/usr/bin/env bash
set -euo pipefail
CFG="$HOME/static-rooster/config/decisionhub.config.json"
jq -r '.tools[].href // .tools[].route' "$CFG" |
while read -r u; do
  [ -z "$u" ] && continue
  echo "--- $u"
  base="http://localhost:8888"
  code_html=$(curl -s -o /dev/null -w '%{http_code}' "$u")
  echo "page -> $code_html"
  qp=$(sed -n 's/.*[?&]\(index\|src\)=\([^&#]*\).*/\2/p' <<<"$u")
  if [ -n "$qp" ]; then
    code_json=$(curl -s -o /dev/null -w '%{http_code}' "$base$qp")
    echo "json -> $code_json ($qp)"
  fi
done
