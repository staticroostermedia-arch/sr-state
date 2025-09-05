#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST/apps" "$DIST/docs" "$DIST/config"

# copy payloads if present
cp -f "$ROOT"/apps/*.html   "$DIST/apps/"   2>/dev/null || true
cp -f "$ROOT"/docs/*        "$DIST/docs/"   2>/dev/null || true
cp -f "$ROOT"/config/*      "$DIST/config/" 2>/dev/null || true

# build landing page
{
  printf '%s\n' '<!doctype html><meta charset="utf-8"><title>Static Rooster — Beta</title>'
  printf '%s\n' '<body style="font-family:ui-monospace,Consolas,monospace;background:#0b0c06;color:#b4ffb4"><h1>Static Rooster — Beta</h1><ul>'
} > "$DIST/index.html"

for f in "$DIST"/apps/*.html; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  printf '<li><a href="apps/%s">%s</a></li>\n' "$b" "$b" >> "$DIST/index.html"
done

printf '%s\n' '</ul></body>' >> "$DIST/index.html"
echo "Build complete → $DIST"
