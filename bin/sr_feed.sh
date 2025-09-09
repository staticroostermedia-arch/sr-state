#!/usr/bin/env bash
set -euo pipefail
SR_HOME="${SR_HOME:-$HOME/static-rooster}"
cd "$SR_HOME"
mkdir -p snapshots
tmp="$(mktemp)"
printf '{ "generated_at":"%s", "items":[' "$(date -Is)" > "$tmp"
first=1
for f in $(ls -1t snapshots/*.tgz 2>/dev/null | head -40); do
  sha="$(sha256sum "$f" | awk '{print $1}')"
  sz="$(stat -c%s "$f" 2>/dev/null || wc -c < "$f")"
  nm="$(basename "$f")"
  ts="$(echo "$nm" | sed -n 's/^sr_snapshot_\([0-9_]\+\)\.tgz$/\1/p')"
  test "$first" = 1 || printf ',' >> "$tmp"
  first=0
  printf '\n  {"name":"%s","path":"snapshots/%s","size":%s,"sha256":"%s","ts":"%s"}' "$nm" "$nm" "$sz" "$sha" "$ts" >> "$tmp"
done
printf '\n]}\n' >> "$tmp"
mv "$tmp" snapshots/feed_v0_1.json
echo "wrote snapshots/feed_v0_1.json"
