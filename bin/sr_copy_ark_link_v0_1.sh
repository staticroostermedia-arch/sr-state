#!/usr/bin/env bash
set -euo pipefail
ARKDIR="$HOME/static-rooster/share/ark"
PUBTXT="$HOME/static-rooster/share/public_url.txt"
LATEST="$(jq -r .name "$ARKDIR/latest.json" 2>/dev/null || true)"
BASE="$(cat "$PUBTXT" 2>/dev/null || true)"
[ -n "${LATEST:-}" ] || { echo "[ERR] no latest.json"; exit 1; }
[ -n "${BASE:-}" ]   || { echo "[ERR] no public_url.txt"; exit 1; }
URL="${BASE%/}/ark/$LATEST"
if command -v xclip >/dev/null 2>&1; then printf "%s" "$URL" | xclip -selection clipboard; fi
if command -v xsel  >/dev/null 2>&1; then printf "%s" "$URL" | xsel --clipboard --input; fi
echo "$URL"
