#!/usr/bin/env bash
set -euo pipefail
BASE="$(cat "$HOME/static-rooster/share/public_url.txt" 2>/dev/null || true)"
ARKNAME="$(jq -r .name "$HOME/static-rooster/share/ark/latest.json" 2>/dev/null || true)"
[ -n "${BASE:-}" ] && [ -n "${ARKNAME:-}" ] || { echo "[ERR] missing public_url or latest.json"; exit 1; }
ARKURL="${BASE%/}/ark/$ARKNAME"
CTXURL="${BASE%/}/context/latest.json"
MSG=$(jq -n --arg ark "$ARKURL" --arg ctx "$CTXURL" \
  '{schema:"sr.share.message.v0_1", kind:"ark_push", ark:$ark, context:$ctx}')
curl -s -m 5 -X POST "http://127.0.0.1:8891/chat" -H 'content-type: application/json' -d "$MSG" >/dev/null || true
echo "[push] $ARKURL"
