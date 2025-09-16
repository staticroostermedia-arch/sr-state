#!/bin/sh
# Simple queue runner: executes *.order.sh under ~/static-rooster only, logs receipts.
set -eu
ROOT="${HOME}/static-rooster"; IN="$ROOT/inbox"; RCPTS="$ROOT/receipts"
LOGDIR="$ROOT/logs"; mkdir -p "$LOGDIR" "$IN" "$RCPTS"
touch "$ROOT/.builderd_ok"

guard() { case "$1" in /*|*"/.."*|*"/../"*|*"../"*) return 1;; esac; return 0; }
while :; do
  f="$(ls -1t "$IN"/order_*.order.sh 2>/dev/null | tail -n1 || true)"
  [ -n "$f" ] || { sleep 3; continue; }
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  base="$(basename "$f")"
  rec="$RCPTS/sr_builderd_${ts}.json"
  log="$LOGDIR/${base%.sh}.log"
  ok=true
  {
    echo "# executing $base @ $ts"
    cd "$ROOT"
    # Hard fences: refuse suspicious tokens
    if grep -Eq '(^|[[:space:]])sudo[[:space:]]' "$f"; then echo "blocked: sudo token"; ok=false; fi
    if grep -Eq '/etc/|/usr/|/bin/|/root/' "$f"; then echo "blocked: absolute sensitive paths"; ok=false; fi
    $ok || exit 12
    # Execute with POSIX sh; enforce ROOT cwd
    /bin/sh "$f"
  } >"$log" 2>&1 || ok=false
  verdict="$( $ok && echo "applied" || echo "failed")"
  printf '%s\n' "{ \"schema\":\"sr.builderd.v0_1\",\"generated_at\":\"${ts}\",\"order\":\"${base}\",\"log\":\"${log}\",\"verdict\":\"${verdict}\" }" > "$rec"
  # Drop fresh status
  "$ROOT/forge/tools/sr_status_dump_v0_2.sh" >/dev/null 2>&1 || true
  rm -f -- "$f" || true
done
