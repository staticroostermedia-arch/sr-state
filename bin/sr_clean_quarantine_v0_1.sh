#!/usr/bin/env sh
# sr_clean_quarantine_v0_1.sh — non-destructive cleanup with receipts; optional purge.
set -eu

ROOT="${HOME}/static-rooster"
RCPTS="${ROOT}/receipts"
QUAR="${ROOT}/quarantine/$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
ARCH="${ROOT}/archives"
mkdir -p "$RCPTS" "$QUAR" "$ARCH"

# Tunables (can be overridden env)
RECEIPTS_KEEP_DAYS="${RECEIPTS_KEEP_DAYS:-14}"   # keep last N days of receipts
RECEIPTS_COMPRESS="${RECEIPTS_COMPRESS:-1}"      # 1=tar.gz old receipts
FORGE_MIN_KB="${FORGE_MIN_KB:-6}"               # tiny html stubs below this → quarantine
MAX_HTML_DUPES="${MAX_HTML_DUPES:-3}"           # keep at most N duplicates per tool key
PURGE="${SR_PURGE:-0}"                           # 1 = delete instead of move

bytes_total() { find "$1" -type f -printf "%s\n" 2>/dev/null | awk '{s+=$1} END{print s+0}'; }

reclaimed=0
moved=0
deleted=0
compressed=0

log() { printf "%s\n" "$*" ; }

qmove() {
  src="$1"
  rel="${src#$ROOT/}"
  dest="$QUAR/$rel"
  mkdir -p "$(dirname "$dest")"
  mv "$src" "$dest"
  moved=$((moved+1))
}

qdelete() {
  rm -f "$1"
  deleted=$((deleted+1))
}

# 1) Receipts: compress or move anything older than KEEP_DAYS
if [ "$RECEIPTS_KEEP_DAYS" -ge 0 ] && [ -d "$RCPTS" ]; then
  tmpdir="$(mktemp -d)"
  find "$RCPTS" -type f -mtime +"$RECEIPTS_KEEP_DAYS" -name '*.json' 2>/dev/null | while read -r f; do
    if [ "$RECEIPTS_COMPRESS" = "1" ]; then
      base="$(basename "$f")"
      cp "$f" "$tmpdir/$base"
      compressed=$((compressed+1))
      if [ "$PURGE" = "1" ]; then rm -f "$f"; else qmove "$f"; fi
    else
      if [ "$PURGE" = "1" ]; then qdelete "$f"; else qmove "$f"; fi
    fi
  done
  if [ "$RECEIPTS_COMPRESS" = "1" ]; then
    [ "$(ls -1 "$tmpdir" | wc -l)" -gt 0 ] && { tar czf "$ARCH/receipts_$(date -u +"%Y_%m_%dt%H_%M_%Sz").tgz" -C "$tmpdir" . ; }
    rm -rf "$tmpdir"
  fi
fi

# 2) Forge: quarantine tiny html tiles + heavy duplicates
if [ -d "$ROOT/forge" ]; then
  # tiny tiles
  find "$ROOT/forge" -type f -name '*.html' -size -"${FORGE_MIN_KB}"k 2>/dev/null | while read -r f; do
    size=$(wc -c < "$f" | tr -d ' ')
    before=$(bytes_total "$ROOT/forge")
    if [ "$PURGE" = "1" ]; then qdelete "$f"; else qmove "$f"; fi
    after=$(bytes_total "$ROOT/forge")
    [ "$before" -gt "$after" ] && reclaimed=$((reclaimed + (before - after)))
  done

  # duplicates by tool key (prefix before _vX_Y_Z.html)
  # keep the newest MAX_HTML_DUPES, move/purge the rest
  find "$ROOT/forge" -type f -name '*_v*_*.html' 2>/dev/null | sed 's/\.html$//' | \
  awk -F'/|_v[0-9]+' '{print $0 "\t" $NF}' | sort -k2,2 -k1,1r | \
  awk -F'\t' -v n="$MAX_HTML_DUPES" '
    {key=$2; file=$1 ".html"; seen[key]++; if (seen[key] > n) print file;
    }' | while read -r old; do
      if [ -f "$old" ]; then
        before=$(bytes_total "$ROOT/forge")
        if [ "$PURGE" = "1" ]; then qdelete "$old"; else qmove "$old"; fi
        after=$(bytes_total "$ROOT/forge")
        [ "$before" -gt "$after" ] && reclaimed=$((reclaimed + (before - after)))
      fi
    done
fi

# 3) Offenders: move filenames with spaces/uppercase from docs/config/bin
for dir in docs config bin; do
  [ -d "$ROOT/$dir" ] || continue
  find "$ROOT/$dir" -type f 2>/dev/null | while read -r f; do
    base="$(basename "$f")"
    lc="$(printf "%s" "$base" | tr '[:upper:]' '[:lower:]')"
    if printf "%s" "$base" | grep -q ' ' || [ "$base" != "$lc" ]; then
      if [ "$PURGE" = "1" ]; then qdelete "$f"; else qmove "$f"; fi
    fi
  done
done

# 4) Write receipt
ts="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
R="$RCPTS/sr_done_receipt_cleanup_${ts}.json"
{
  printf '{\n'
  printf '  "schema":"sr.receipt.v0_1",\n'
  printf '  "generated_at_utc":"%s",\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '  "tool_name":"sr.clean.quarantine.v0_1",\n'
  printf '  "status":"ok",\n'
  printf '  "summary":"moved:%s deleted:%s compressed:%s reclaimed_bytes:%s",\n' "$moved" "$deleted" "$compressed" "$reclaimed"
  printf '  "used_sudo":false\n'
  printf '}\n'
} > "$R"

echo "Cleanup receipt: $R"
