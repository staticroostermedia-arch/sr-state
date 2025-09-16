#!/bin/sh
set -eu
ROOT="${HOME}/static-rooster"
BIN="$ROOT/bin"
RCPTS="$ROOT/receipts"
SNAPROOT="$ROOT/snapshots"
DOCS="$ROOT/docs"
CHLOG="$DOCS/identity/99_sr_change_log.md"

# Choose the underlying runner (prefer sr-runner-plus, else sr-runner), but never fail hard.
RUNNER=""
[ -x "$BIN/sr-runner-plus" ] && RUNNER="$BIN/sr-runner-plus"
[ -z "$RUNNER" ] && [ -x "$BIN/sr-runner" ] && RUNNER="$BIN/sr-runner"
[ -z "$RUNNER" ] && RUNNER="/bin/true"

# Run the underlying runner, capture its exit (never crash the wrapper)
RUN_START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
("$RUNNER" || true)
RUN_END_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Make a fresh snapshot folder (UTC; filename-safe)
TS_PATH="$(date -u +%Y-%m-%dT%H_%M_%SZ)"
SNAP="$SNAPROOT/$TS_PATH"
mkdir -p "$SNAP"

# Minimal manifest: enumerate important files and their SHA256
# (fast, bounded set—expand later if desired)
LIST_PATHS="
$ROOT/bin
$ROOT/forge/tools
$ROOT/build
$ROOT/decisionhub
$ROOT/docs
$ROOT/receipts
"
MANI="$SNAP/sr_snapshot_${TS_PATH}.manifest.json"
SUMS="$SNAP/sha256sums.txt"

# Create checksum list (ignore huge tgz to keep it snappy)
: > "$SUMS"
for P in $LIST_PATHS; do
  [ -d "$P" ] || continue
  ( cd "$P" && find . -type f ! -name '*.tgz' ! -name '*.zip' -maxdepth 3 -print0 \
    | xargs -0 -r sha256sum ) >> "$SUMS" || true
done

# Basic environment probe
HOST="$(uname -n)"
KERNEL="$(uname -sr)"
IFACE="$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')" || IFACE="unknown"
POWER="unknown"; command -v upower >/dev/null 2>&1 && POWER="$(upower -i $(upower -e | head -n1) 2>/dev/null | awk -F: '/state/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')"

# Pick latest status receipt if present
LATEST_STATUS="$(ls -1t "$RCPTS"/sr_status_dump_*.json 2>/dev/null | head -n1 || true)"

# Write manifest (lightweight)
printf '%s\n' "{
  \"schema\": \"sr.snapshot.v0_3\",
  \"generated_at\": \"${RUN_END_UTC}\",
  \"host\": {\"name\": \"${HOST}\", \"kernel\": \"${KERNEL}\", \"iface\": \"${IFACE}\", \"power\": \"${POWER}\"},
  \"paths\": [\"bin\",\"forge/tools\",\"build\",\"decisionhub\",\"docs\",\"receipts\"],
  \"sha256_list\": \"sha256sums.txt\",
  \"runner\": {\"invoked\": \"${RUNNER}\", \"started\": \"${RUN_START_UTC}\", \"finished\": \"${RUN_END_UTC}\"},
  \"status_receipt\": \"${LATEST_STATUS}\"
}" > "$MANI"

# Emit a snapshot receipt
RECEIPT="$RCPTS/sr_runner_snapshot_${TS_PATH}.json"
printf '%s\n' "{
  \"schema\": \"sr.runner.snapshot.receipt.v0_1\",
  \"generated_at\": \"${RUN_END_UTC}\",
  \"snapshot_dir\": \"${SNAP}\",
  \"manifest\": \"${MANI}\",
  \"sha256s\": \"${SUMS}\",
  \"host\": {\"name\": \"${HOST}\", \"kernel\": \"${KERNEL}\", \"iface\": \"${IFACE}\", \"power\": \"${POWER}\"}
}" > "$RECEIPT"

# Append a compact Change Log line (idempotent append)
mkdir -p \"${DOCS}/identity\"
if [ ! -f \"$CHLOG\" ]; then
  printf '## 99_SR_Change_Log (rolling)\n\n' > \"$CHLOG\"
fi
printf '%s\n' "- ${RUN_END_UTC} | runner→snapshot wrap v0.1 | ${SNAP} | status: $(basename \"${LATEST_STATUS}\")" >> \"$CHLOG\"

# Friendly tail lines
echo "[snapshot] → $SNAP"
echo "[receipt ] → $RECEIPT"
exit 0

# status pulse (v0.2)
"/home/a/static-rooster/forge/tools/sr_status_dump_v0_2.sh" || true

# SR:STATUS_DUMP (idempotent)
if [ -x "${HOME}/static-rooster/bin/sr_status_dump.sh" ]; then
  "${HOME}/static-rooster/bin/sr_status_dump.sh" || true
fi

# status dump (non-fatal)
"${HOME}/static-rooster/bin/sr_status_dump_v0_3.sh" || true
