#!/usr/bin/env bash
set -euo pipefail
SR="$HOME/static-rooster"
OUT="$SR/receipts/index_v0_1.json"
jq -n --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg base "/receipts/" \
  --arg ver "v0_1" \
  --arg title "Static Rooster Receipts Index" '
  { title: $title, version: $ver, generated_at: $now,
    items: [ inputs ] }' \
  < <(find "$SR/receipts" -maxdepth 1 -type f -printf "%f\n" \
      | sort -r \
      | jq -R -c --arg base "/receipts/" '{name:., href:($base+.),
          ts:(. | capture("(?<ts>\\d{8}_\\d{4})") | .ts // ""), badge:"file"}') \
  > "$OUT"
echo "wrote $OUT"
