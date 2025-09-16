#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
PLAN="${1:-$ROOT/build/plan_v0_1.txt}"
[ -f "$PLAN" ] || { echo "no plan at $PLAN — skipping"; exit 0; }
UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; TS="$(printf %s "$UTC" | tr -d ':TZ')"
RCPT="$ROOT/receipts/sr_build_plan_${TS}.json"; LOG="$(mktemp)"; exec 3>"$LOG"
jstr(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
count=0; ok=0; fail=0
while IFS='' read -r line || [ -n "$line" ]; do
  case "$line" in ''|'#'*) continue;; esac
  set -- $line; cmd="$1"; shift || true; count=$((count+1))
  case "$cmd" in
    WRITE)
      path="$1"; tmp="$(mktemp)"; : > "$tmp"
      while IFS='' read -r L; do [ "$L" = "EOF" ] && break; printf '%s\n' "$L" >> "$tmp"; done
      mkdir -p "$(dirname "$path")"; mv -f "$tmp" "$path"; printf '[%s] WRITE %s\n' "$count" "$path" >&3; ok=$((ok+1));;
    MKDIR)  mkdir -p "$1"; printf '[%s] MKDIR %s\n' "$count" "$1" >&3; ok=$((ok+1));;
    MV)     [ -e "$1" ] && mv -f -- "$1" "$2" || true; printf '[%s] MV %s -> %s\n' "$count" "$1" "$2" >&3; ok=$((ok+1));;
    CHMOD)  chmod "$1" "$2"; printf '[%s] CHMOD %s %s\n' "$count" "$1" "$2" >&3; ok=$((ok+1));;
    CMD)    sh -c "$*"; printf '[%s] CMD %s\n' "$count" "$*" >&3; ok=$((ok+1));;
    *)      printf '[%s] UNKNOWN %s\n' "$count" "$cmd" >&3; fail=$((fail+1));;
  esac
done < "$PLAN"
{ printf '{\n  "schema":"sr.build.plan.run.v0_1",\n  "generated_at":"%s",\n' "$UTC"
  printf '  "plan":"%s",\n' "$(jstr "$PLAN")"
  printf '  "counts":{"total":%d,"ok":%d,"fail":%d},\n' "$count" "$ok" "$fail"
  printf '  "log":%s\n}\n' "$(jstr "$(cat "$LOG")")"; } > "$RCPT"
rm -f "$LOG"; echo "[plan] $PLAN → $RCPT (ok=$ok fail=$fail)"
