#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
TK="${ROOT}/docs/contracts/build_master_toolkit_v0_3.md"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RCPT="${ROOT}/receipts/sr_bind_toolkit_v0_1_${TS}.json"

status="ok"
msg="found"
[ -f "$TK" ] || { status="missing"; msg="docs/contracts/build_master_toolkit_v0_3.md not found"; }

# (future: wire symlinks or copy; for now we verify presence & record)
printf '{"schema":"sr.bind_toolkit.v0_1","generated_at":"%s","status":"%s","toolkit":"%s","note":"%s"}\n' \
  "$TS" "$status" "$TK" "$msg" > "$RCPT"

printf "\n== Bind Toolkit ==\nstatus: %s\npath  : %s\nreceipt: %s\n" "$status" "$TK" "$RCPT"
[ "$status" = "ok" ] || exit 1
