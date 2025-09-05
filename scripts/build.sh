#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
DIST="$ROOT/dist"
rm -rf "$DIST"
mkdir -p "$DIST"
# copy core dirs
for d in apps data docs config ui; do
  if [[ -d "$ROOT/$d" ]]; then
    cp -R "$ROOT/$d" "$DIST/"
  fi
done
cp "$ROOT/index.html" "$DIST/index.html"

# generate a simple apps index
APPS_INDEX="$DIST/apps_index.html"
{
  echo "<!doctype html><meta charset='utf-8'><title>Apps Index</title>"
  echo "<h1>Apps</h1><ul>"
  for f in "$DIST/apps"/*.html; do
    base="$(basename "$f")"
    echo "<li><a href='/apps/$base'>$base</a></li>"
  done
  echo "</ul>"
} > "$APPS_INDEX"

echo "Built to $DIST"
