#!/usr/bin/env sh
# sr_build_from_specs_v0_1.sh — patched v0.1.1 (normalized receipt filenames)
set -eu
ROOT="${HOME}/static-rooster"
SPECS="${ROOT}/specs"
BIN="${ROOT}/bin"
RCPTS="${ROOT}/receipts"
SNAPS="${ROOT}/snapshots"
PORT=${PORT:-8888}

mkdir -p "$SPECS" "$RCPTS" "$SNAPS"

gen="$BIN/sr_toolgen_v0_1.sh"
acc="$BIN/sr_accept_v0_1.sh"
reg="$BIN/sr_register_v0_1.sh"

ts="$(date -u +"%Y_%m_%dt%H_%M_%Sz")"
summary=""

for spec in "$SPECS"/*.yaml; do
  [ -f "$spec" ] || continue
  html="$("$gen" "$spec")" || { echo "GEN FAIL: $spec"; continue; }
  if "$acc" "$html"; then
    "$reg" "$html"
    summary="$summary; ok $(basename "$spec")->$(basename "$html")"
  else
    summary="$summary; fail $(basename "$spec")"
  fi
done

mkdir -p "$RCPTS"
R="$RCPTS/sr_done_receipt_build_from_specs_${ts}.json"
cat > "$R" <<EOF
{
  "schema":"sr.receipt.v0_1",
  "generated_at_utc":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tool_name":"sr.build.from_specs.v0_1",
  "status":"ok",
  "summary":"${summary#; }",
  "used_sudo":false
}
EOF

echo "Receipt: $R"
