#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"; SH="$ROOT/share"
HOST="$(cat "$ROOT/QUICKTUNNEL_HOST" 2>/dev/null || true)"
[ -n "$HOST" ] || { echo "No tunnel host. Run sr_quicktunnel_enable_v0_1.sh first."; exit 1; }
PAGE="$(ls -1t "$SH"/ctx_*.html 2>/dev/null | head -1 || true)"
[ -n "$PAGE" ] || { echo "No context pages found under $SH"; exit 1; }
REL="/share/$(basename "$PAGE")"
echo "$HOST$REL"
