#!/usr/bin/env bash
# sr_git_hygiene_probe_v0_1.sh — emit a JSON receipt of git hygiene & watcher presence
[ -n "$BASH_VERSION" ] || exec /usr/bin/env bash "$0" "$@"

set -euo pipefail
ROOT="${HOME}/static-rooster"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TSAFE="${TS//:/_}"
OUTDIR="${ROOT}/receipts/probes"
OUT="${OUTDIR}/sr_git_hygiene_probe_v0_1_${TSAFE}.json"
mkdir -p "$OUTDIR"

# Basic repo facts
ORIGIN="$(git -C "$ROOT" remote get-url origin 2>/dev/null || echo "")"
BRANCH="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo "")"

# Dirty/untracked counts
PORC="$(git -C "$ROOT" status --porcelain 2>/dev/null || true)"
DIRTY_LINES="$(printf "%s\n" "$PORC" | sed '/^$/d' | wc -l | tr -d ' ')"
UNTRACKED="$(git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"

# remote divergence
git -C "$ROOT" fetch -q --all --prune || true
AHEAD=0; BEHIND=0
if git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  AHEAD="$(git -C "$ROOT" rev-list --left-right --count @{u}...HEAD | awk '{print $2}')"
  BEHIND="$(git -C "$ROOT" rev-list --left-right --count @{u}...HEAD | awk '{print $1}')"
fi

# workflow on main?
HAS_WORKFLOW=0
if git -C "$ROOT" ls-remote --heads origin main >/dev/null 2>&1; then
  # check if the file exists in main tree
  if git -C "$ROOT" ls-tree -r origin/main --name-only | grep -qE '^\.github/workflows/ark_watcher_v0_[0-9]+\.yml$'; then
    HAS_WORKFLOW=1
  fi
fi

# heartbeat branches
mapfile -t HB_BRANCHES < <(git -C "$ROOT" ls-remote --heads origin 'chore/heartbeat*' | awk '{print $2}' | sed 's#refs/heads/##')
HB_JSON="["
for i in "${!HB_BRANCHES[@]}"; do
  b="${HB_BRANCHES[$i]}"
  esc="${b//\\/\\\\}"; esc="${esc//\"/\\\"}"
  HB_JSON="$HB_JSON\"$esc\""
  [[ $i -lt $((${#HB_BRANCHES[@]}-1)) ]] && HB_JSON="$HB_JSON, "
done
HB_JSON="$HB_JSON]"

# cloud_latest presence on main
CLOUD_LATEST_PATH=""
if git -C "$ROOT" ls-tree -r origin/main --name-only | grep -qE '^receipts/heartbeats/cloud_latest\.json$'; then
  CLOUD_LATEST_PATH="receipts/heartbeats/cloud_latest.json"
fi

# verdict
VERDICT="clean-ready"
if [[ "$HAS_WORKFLOW" -ne 1 ]]; then
  VERDICT="needs-workflow"
elif [[ -z "$CLOUD_LATEST_PATH" && "${#HB_BRANCHES[@]}" -eq 0 ]]; then
  VERDICT="no-heartbeat"
elif [[ "$DIRTY_LINES" -gt 0 || "$UNTRACKED" -gt 0 ]]; then
  VERDICT="dirty"
fi

# write JSON
{
  printf '{\n'
  printf '  "schema": "sr.git.hygiene.v0_1",\n'
  printf '  "generated_at_utc": "%s",\n' "$TS"
  printf '  "root": "%s",\n' "$ROOT"
  printf '  "remote_origin": "%s",\n' "$ORIGIN"
  printf '  "branch": "%s",\n' "$BRANCH"
  printf '  "dirty": %s,\n' "$DIRTY_LINES"
  printf '  "untracked": %s,\n' "$UNTRACKED"
  printf '  "ahead": %s,\n' "$AHEAD"
  printf '  "behind": %s,\n' "$BEHIND"
  printf '  "has_workflow": %s,\n' "$HAS_WORKFLOW"
  printf '  "heartbeat_branches": %s,\n' "$HB_JSON"
  printf '  "cloud_latest_path": "%s",\n' "$CLOUD_LATEST_PATH"
  printf '  "verdict": "%s"\n' "$VERDICT"
  printf '}\n'
} > "$OUT"

echo "Probe written: $OUT"
echo "Verdict: $VERDICT | dirty:$DIRTY_LINES untracked:$UNTRACKED ahead:$AHEAD behind:$BEHIND | workflow:$HAS_WORKFLOW heartbeat_branches:${#HB_BRANCHES[@]} cloud_latest:${CLOUD_LATEST_PATH:-none}"
