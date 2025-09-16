#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
INBOX="${ROOT}/_inbox"
PROCESSED="${INBOX}/processed"
FAILED="${INBOX}/failed"
RCPTS="${ROOT}/receipts"
LOCK="${ROOT}/state/sr_executor.lock"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RID="sr_executor_${TS}.json"

# Simple lock (1 at a time)
[ -f "$LOCK" ] && echo "locked: $(cat "$LOCK")" && exit 0
printf "%s\n" "$TS $$" > "$LOCK"

finish () { rm -f "$LOCK" 2>/dev/null || true; }
trap finish EXIT INT TERM

# Whitelist: only allow .order.sh files that *refer to* known tool roots
WL_A="$ROOT/build/patches"
WL_B="$ROOT/forge/tools"
WL_C="$ROOT/bin"

order="$(ls -1t "$INBOX"/*.order.sh 2>/dev/null | head -n1 || true)"
[ -z "${order}" ] && printf '{ "schema":"sr.executor.v0_1","generated_at":"%s","status":"idle" }\n' "$TS" > "$RCPTS/$RID" && exit 0

LOG="$(mktemp)"
USED_SUDO=false
STATUS=ok
NOTE="executed"

# quick static checks
grep -qE "(^|/)(rm -rf|mkfs|dd if=|:>|&>|/dev/[sn]d[a-z])" "$order" && { STATUS=blocked; NOTE="dangerous primitives"; }

# ensure order body only calls within whitelist dirs
if [ "$STATUS" = "ok" ]; then
  # crude allow-list: must reference at least one of our roots
  if ! grep -qE "$(printf '%s|%s|%s' "$WL_A" "$WL_B" "$WL_C" | sed 's/\//\\\//g')" "$order"; then
    STATUS=blocked; NOTE="order not referencing whitelisted paths";
  fi
fi

if [ "$STATUS" = "ok" ]; then
  # exec in a subshell; capture sudo usage heuristically
  ( sh "$order" ) >"$LOG" 2>&1 || STATUS=failed
  grep -qi '^sudo ' "$order" && USED_SUDO=true
  grep -qi 'used_sudo:true' "$LOG" && USED_SUDO=true
fi

# move the order and emit receipt
dest="$PROCESSED"
[ "$STATUS" = "failed" ] && dest="$FAILED"
mv -f "$order" "$dest"/ 2>/dev/null || true

cat > "$RCPTS/$RID" <<JSON
{
  "schema": "sr.executor.v0_1",
  "generated_at": "$TS",
  "order_file": "$(basename "$order")",
  "status": "$STATUS",
  "note": "$NOTE",
  "used_sudo": $USED_SUDO,
  "log_path": "$(basename "$LOG")"
}
JSON

# leave the log alongside receipts for the dashboard to link
mv -f "$LOG" "$RCPTS/$(basename "$LOG")" 2>/dev/null || true

# Friendly line for humans
printf "executor: %s (%s) -> %s\n" "$STATUS" "$NOTE" "$RCPTS/$RID"
