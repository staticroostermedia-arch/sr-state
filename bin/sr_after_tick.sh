#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"
bash "$ROOT/bin/sr_receipts_index.sh" || true
NEWEST="$(ls -1t "$ROOT"/dossiers/sr_dossier_*.zip 2>/dev/null | head -n1 || true)"
[ -n "$NEWEST" ] && bash "$ROOT/bin/sr_gate_scan.sh" "$NEWEST" || true
bash "$ROOT/bin/sr_gate_index.sh" || true
