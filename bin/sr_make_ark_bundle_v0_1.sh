#!/usr/bin/env sh
# sr_make_ark_bundle_v0_1.sh — package Ark into tgz + self-extracting .run
set -eu

ROOT="${1:-$HOME/static-rooster}"
EXPORTS="${ROOT}/ark/exports"
TS="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
mkdir -p "$EXPORTS"

# Build tarball of key directories (docs, config, receipts index, bin scripts)
WORK="$(mktemp -d 2>/dev/null || mktemp -d -t srwork)"
OUT_TGZ="${EXPORTS}/ark_bundle_${TS}.tgz"
OUT_RUN="${EXPORTS}/ark_bundle_${TS}.run"

# Choose payload (avoid huge dirs like forge/)
tar -czf "$OUT_TGZ" -C "$ROOT" \
  docs \
  config \
  receipts \
  bin \
  2>/dev/null || true

# Build self-extracting .run with a simple installer that drops files into ~/static-rooster
cat > "$WORK/installer.sh" <<'RUN'
#!/usr/bin/env sh
set -eu
APPLY="${SR_APPLY:-1}" # default apply for convenience on rehydration
ROOT="${HOME}/static-rooster"
RCPTS="${ROOT}/receipts"
CHANGELOG="${ROOT}/99_SR_Change_Log.md"
mkdir -p "$ROOT" "$RCPTS"
WORKDIR="$(mktemp -d 2>/dev/null || mktemp -d -t srwork)"
ARCHIVE_LINE=$(awk '/^__ARCHIVE_BELOW__/ {print NR+1; exit 0;}' "$0")
tail -n +$ARCHIVE_LINE "$0" | tar xzf - -C "$WORKDIR"
if [ "$APPLY" = "1" ]; then
  rsync -a "$WORKDIR/static-rooster/" "$ROOT/"
  printf "\n[%s] Ark bundle applied\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$CHANGELOG"
  STATUS="ok"; SUMMARY="applied"
else
  STATUS="ok"; SUMMARY="dry-run"
fi
R="$RCPTS/sr_done_receipt_ark_apply_$(date -u +"%Y_%m_%dt%H_%M_%Sz").json"
printf '{ "schema":"sr.receipt.v0_1","generated_at_utc":"%s","tool_name":"sr.ark.apply","status":"%s","summary":"%s"}\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$STATUS" "$SUMMARY" > "$R"
exit 0
__ARCHIVE_BELOW__
RUN

# Create payload tar of the whole static-rooster directory (filtered by TGZ we already made)
# For simplicity, reuse the tgz contents under a root folder "static-rooster"
# Extract to temp dir and re-tar with desired root name
TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t srtmp)"
tar -xzf "$OUT_TGZ" -C "$TMPDIR"
( cd "$TMPDIR" && mkdir -p "static-rooster" && mv docs config receipts bin "static-rooster/" 2>/dev/null || true )
PAYLOAD="$WORK/payload.tgz"
tar -czf "$PAYLOAD" -C "$TMPDIR" "static-rooster"

# Stitch installer + payload into .run
cat "$WORK/installer.sh" "$PAYLOAD" > "$OUT_RUN"
chmod +x "$OUT_RUN"

# Checksums
( cd "$EXPORTS" && sha256sum "$(basename "$OUT_TGZ")" "$(basename "$OUT_RUN")" > "ark_bundle_${TS}.sha256" ) 2>/dev/null || true

echo "WROTE: $OUT_TGZ"
echo "WROTE: $OUT_RUN"
