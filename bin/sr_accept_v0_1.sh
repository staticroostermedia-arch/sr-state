#!/usr/bin/env sh
# sr_accept_v0_1.sh — acceptance checks for generated tools
set -eu
HTML="$1"
MIN_KB="${SR_MIN_KB:-6}"

fail(){ echo "FAIL: $1" >&2; exit 64; }

# size floor
sz=$(wc -c < "$HTML" | tr -d ' ')
[ "$sz" -ge $((MIN_KB*1024)) ] || fail "size ${sz} < ${MIN_KB}KB"

# filename rules
base="$(basename "$HTML")"
printf "%s" "$base" | grep -Eq '_v[0-9]+_[0-9]+(_[0-9]+)?\.html$' || fail "filename missing _vX_Y_Z suffix"
printf "%s" "$base" | grep -q '[ ()]' && fail "filename contains space or parentheses"

# DOM markers
grep -q "QuickCheck" "$HTML" || fail "missing QuickCheck block"
grep -q "postMessage" "$HTML" || fail "missing event envelope"
grep -q "badge" "$HTML" || fail "missing version badge"

echo "ACCEPT: $HTML"
