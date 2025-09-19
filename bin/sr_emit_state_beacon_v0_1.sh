#!/usr/bin/env bash
# sr_emit_state_beacon_v0_1.sh
set -euo pipefail
ROOT="${SR_ROOT:-$HOME/static-rooster}"
OUT_REL="public/state/state_beacon_v0_1.json"
OUT="${ROOT}/${OUT_REL}"
PROJECT="${SR_PROJECT:-EH1003006}"
HOSTNAME="$(hostname)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SEQ_FILE="${ROOT}/public/state/.beacon_seq"
mkdir -p "$(dirname "$OUT")"
seq=0
if [[ -f "$SEQ_FILE" ]]; then seq=$(cat "$SEQ_FILE"); fi
seq=$((seq+1)); echo -n "$seq" > "$SEQ_FILE"
sha_file() { test -f "$1" && sha256sum "$1" | awk '{print $1}' || echo "null"; }
size_file() { test -f "$1" && stat -c%s "$1" || echo 0; }
mtime_file(){ test -f "$1" && date -u -d @"$(stat -c %Y "$1")" +%Y-%m-%dT%H:%M:%SZ || echo "1970-01-01T00:00:00Z"; }
mapfile -t RECEIPTS < <(ls -t "${ROOT}/receipts"/sr_done_receipt_*.json 2>/dev/null | head -n 8)
latest_json="[]"
if [[ ${#RECEIPTS[@]} -gt 0 ]]; then
  tmp=$(mktemp)
  for f in "${RECEIPTS[@]}"; do
    b="$(basename "$f" .json)"
    kind="$(echo "$b" | sed -E 's/^sr_done_receipt_([^_]+)_.+$/\1/')"
    sha="$(sha_file "$f")"; rel="${f#$ROOT/}"
    printf '{"id":"%s","kind":"%s","path":"%s","sha256":"%s"}\n' "$b" "$kind" "$rel" "$sha" >> "$tmp"
  done
  latest_json="$(jq -s '.' "$tmp")"; rm -f "$tmp"
fi
WC_PATH="${ROOT}/receipts/sr_watch_checkpoint_v0_1.json"
WC_SHA="$(sha_file "$WC_PATH")"
WC_VERDICT="$(test -f "$WC_PATH" && jq -r '.verdict // "unknown"' "$WC_PATH" || echo "unknown")"
CFG_PATH="${ROOT}/config/decisionhub_config.json"; CFG_SHA="$(sha_file "$CFG_PATH")"
CANON_PATH="${ROOT}/docs/identity/01_SR_Canon.md"; CANON_SHA="$(sha_file "$CANON_PATH")"
WATCH_LIST=( "config/decisionhub_config.json" "receipts/sr_watch_checkpoint_v0_1.json" )
watched_tmp=$(mktemp); echo "{}" > "$watched_tmp"
for rel in "${WATCH_LIST[@]}"; do
  abs="${ROOT}/${rel}"; sha="$(sha_file "$abs")"; sz="$(size_file "$abs")"; mt="$(mtime_file "$abs")"
  watched_tmp2=$(mktemp)
  jq --arg k "$rel" --arg sha "$sha" --argjson sz $sz --arg mt "$mt" '.[$k] = {sha256:$sha, size:$sz, mtime:$mt}' "$watched_tmp" > "$watched_tmp2"
  mv "$watched_tmp2" "$watched_tmp"
done
merkle_tmp=$(mktemp)
for rel in "${WATCH_LIST[@]}"; do abs="${ROOT}/${rel}"; sha="$(sha_file "$abs")"; echo "${sha}  ${rel}" >> "$merkle_tmp"; done
MERKLE_ROOT="$(sha256sum "$merkle_tmp" | awk '{print $1}')"; rm -f "$merkle_tmp"
SNAP_ID_FILE="${ROOT}/snapshots/.last_id"; SNAP_ID="$(test -f "$SNAP_ID_FILE" && cat "$SNAP_ID_FILE" || echo "unknown")"
SNAP_SHA_FILE="${ROOT}/snapshots/.last_sha"; SNAP_SHA="$(test -f "$SNAP_SHA_FILE" && cat "$SNAP_SHA_FILE" || echo "unknown")"
jq -n --arg schema "sr.state_beacon.v0_1" --argjson seq "$seq" --arg ts "$TS" --arg project "$PROJECT" --arg host "$HOSTNAME"  --arg wcpath "$WC_PATH" --arg wcsha "$WC_SHA" --arg wcver "$WC_VERDICT"  --arg cfg "$CFG_PATH" --arg cfgsha "$CFG_SHA" --arg canon "$CANON_PATH" --arg canosha "$CANON_SHA"  --arg merkle "$MERKLE_ROOT" --arg snapid "$SNAP_ID" --arg snapsha "$SNAP_SHA" --argjson latest "$latest_json" --slurpfile watched "$watched_tmp" '{
  schema:$schema, seq:$seq, generated_at_utc:$ts, project:$project, host:$host,
  snapshot:{id:$snapid, sha256:$snapsha},
  latest_receipts:$latest,
  watch_checkpoint:{path:$wcpath, sha256:$wcsha, verdict:$wcver},
  configs:{decisionhub_config:{path:$cfg, sha256:$cfgsha}},
  anchors:{canon:{path:$canon, sha256:$canosha}},
  watched_files: $watched[0], merkle_root:$merkle
}' | tee "$OUT" >/dev/null
echo "WROTE $OUT"
