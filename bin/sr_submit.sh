#!/usr/bin/env bash
set -euo pipefail
URL="${1:-http://localhost:8891/submit}"
kind="${2:-note}"
msg="${3:-hello from client}"
curl -fsS -H 'Content-Type: application/json' -d "{\"kind\":\"$kind\",\"msg\":\"$msg\",\"ts\":\"$(date -u +%F@%H:%MZ)\"}" "$URL"
echo
