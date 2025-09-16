#!/usr/bin/env sh
# sr_register_v0_1.sh — register tool into DecisionHub config
set -eu
HTML="$1"
ROOT="${HOME}/static-rooster"
CFG="${ROOT}/config/decisionhub_config.json"
ROUTE="${HTML#${ROOT}}"
ROUTE="${ROUTE#}" # ensure absolute
ROUTE="${ROUTE#"${ROOT}"}"
ROUTE="/${ROUTE#/}" # route under server root

# Extract name/badge from HTML
NAME="$(awk -F'[<>]' '/<title>/ {print $3; exit}' "$HTML")"
BADGE="$(awk -F'[<>]' '/class="badge"/ {gsub(/^v/,"",$3); print $3; exit}' "$HTML")"
KEY="$(basename "$HTML" | sed 's/_v[0-9_]*\.html$//' )"

mkdir -p "$(dirname "$CFG")"
if command -v jq >/dev/null 2>&1 && [ -f "$CFG" ]; then
  tmp="$(mktemp)"
  jq --arg key "$KEY" --arg name "$NAME" --arg badge "$BADGE" --arg route "$ROUTE" '
    .items |= (
      if . == null then [] else . end |
      ( map( if .key==$key then .badge=$badge | .route=$route | .name=$name else . end ) ) |
      ( if any(.key==$key; .) then . else . + [{{"key":$key,"name":$name,"badge":$badge,"route":$route}}] end )
    )
  ' "$CFG" > "$tmp" || { echo "WARN: jq update failed; creating fresh config"; :; }
  mv "$tmp" "$CFG"
else
  if [ ! -f "$CFG" ]; then
    cat > "$CFG" <<EOF
{ "title":"DecisionHub - Start Here", "items":[{"key":"$KEY","name":"$NAME","badge":"$BADGE","route":"$ROUTE"}] }
EOF
  else
    # naive append (may duplicate, but keeps you moving)
    echo "" >> "$CFG"
    echo "{\"key\":\"$KEY\",\"name\":\"$NAME\",\"badge\":\"$BADGE\",\"route\":\"$ROUTE\"}" >> "$CFG"
  fi
fi

echo "REGISTERED: $KEY -> $ROUTE"
