#!/usr/bin/env bash
set -euo pipefail

R="$HOME/static-rooster"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OUT="$R/receipts/sr_watch_checkpoint_$(date +%s)_v0_1.json"

cfg="$R/config/decisionhub.config.json"
cfg_sha="$(sha256sum "$cfg" 2>/dev/null | awk '{print $1}')"

# list “tool versions” by filename pattern
tools_json="$(find "$R" -maxdepth 3 -type f -regextype posix-extended -regex '.*_v_[0-9][^/]*' -printf '%P\n' \
  | sort | tail -n 200 | jq -R . | jq -s .)"

# last snapshot & diff count
last_snap="$(ls -1t "$R"/snapshots/sr_snapshot_*.tgz 2>/dev/null | head -n1 || true)"
diffstat="$(git -C "$R" diff --name-status 2>/dev/null | wc -l || echo 0)"

# receipts info
rc_count="$(ls -1 "$R"/receipts/*_v0_1.json 2>/dev/null | wc -l || echo 0)"
rc_latest="$(ls -1t "$R"/receipts/*_v0_1.json 2>/dev/null | head -n1 || true)"
rc_latest="$(basename "$rc_latest" 2>/dev/null || true)"

# filename compliance scan (no spaces, parens, uppercase)
offenders_json="$(python3 - <<'PY'
import os, json
root = os.path.expanduser('~/static-rooster')
bad=[]
for dp,_,fs in os.walk(root):
    if any(s in dp for s in ('.git','snapshots','venv','__pycache__')): continue
    for f in fs:
        b=os.path.basename(f)
        if any(c.isupper() for c in b) or ' ' in b or '(' in b or ')' in b:
            bad.append(os.path.join(dp[len(root)+1:], b))
print(json.dumps({"count": len(bad), "sample": bad[:20]}))
PY
)"

# foedus verdict
off_count="$(jq -r '.count' <<<"$offenders_json")"
foedus="intactum"; [ "${off_count:-0}" -gt 0 ] && foedus="penitential_rite_required"

# assemble JSON via jq
jq -n \
  --arg ts "$TS" \
  --arg cfgsha "$cfg_sha" \
  --arg last "$last_snap" \
  --arg latest "$rc_latest" \
  --arg foedus "$foedus" \
  --argjson tools "$tools_json" \
  --argjson offenders "$offenders_json" \
  --argjson diff "$diffstat" \
  --argjson rc "$rc_count" '
{
  schema: "sr.watch_checkpoint.v0_1",
  ts: $ts,
  config_sha256: (if $cfgsha=="" then null else $cfgsha end),
  tool_versions: $tools,
  diff_files_since_last_commit: ($diff|tonumber),
  last_snapshot: (if $last=="" then null else $last end),
  receipts: { count: ($rc|tonumber), latest: (if $latest=="" then null else $latest end) },
  filename_compliance: $offenders,
  report: $foedus
}' > "$OUT"

echo "wrote $OUT"
