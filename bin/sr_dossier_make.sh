#!/usr/bin/env bash
set -euo pipefail
SR="$HOME/static-rooster"
TS="$(date +%Y%m%d_%H%M)"
VER="v0_1"
mkdir -p "$SR/receipts" "$SR/snapshots" "$SR/logs"

cfg="$SR/config/decisionhub.config.json"
cfg_sha="$( [ -f "$cfg" ] && sha256sum "$cfg" | awk '{print $1}' || echo "missing" )"

# tool versions
pyv="$(python3 -V 2>&1 || true)"
jqv="$(jq --version 2>/dev/null || echo 'jq n/a')"
nodev="$(node -v 2>/dev/null || echo 'node n/a')"
curlv="$(curl --version 2>/dev/null | head -n1 || echo 'curl n/a')"

# git context (best-effort)
cd "$SR" || exit 1
git_rev="$(git rev-parse --short HEAD 2>/dev/null || echo 'no-git')"
git_dirty="$(git status --porcelain 2>/dev/null | wc -l | awk '{print $1}')"
git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-branch')"
mapfile -t diff_files < <(git diff --name-only 2>/dev/null || true)

# filename-rule compliance (lowercase + timestamped suggested pattern)
# accept typical SR names and common web assets we serve
offenders=()
while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  if ! [[ "$base" =~ ^(sr|eh|decisionhub|forge|receipts|docs|config|bin|static-rooster|index|start_here).* ]]; then
    offenders+=("$f")
  fi
done < <(find "$SR" -maxdepth 2 -type f -not -path "$SR/snapshots/*" -print0)

# service health (ingest)
ing_code="$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8891/health || echo 000)"

foedus="intactum"
[[ "$ing_code" != "200" ]] && foedus="fractum"
((${#offenders[@]})) && foedus="fractum"

# crystallize checkpoint JSON
CHK="$SR/receipts/sr_watch_checkpoint_${TS}_${VER}.json"
jq -n \
  --arg ver "$VER" \
  --arg ts "$TS" \
  --arg cfg_sha "$cfg_sha" \
  --arg py "$pyv" --arg jqv "$jqv" --arg node "$nodev" --arg curl "$curlv" \
  --arg git_rev "$git_rev" --arg git_branch "$git_branch" \
  --argjson git_dirty "${git_dirty:-0}" \
  --arg ingest_code "$ing_code" \
  --arg foedus "$foedus" \
  --argjson diff_files "$(printf '%s\n' "${diff_files[@]}" | jq -R . | jq -s .)" \
  --argjson offenders "$(printf '%s\n' "${offenders[@]}" | jq -R . | jq -s .)" '
{
  kind:"sr_watch_checkpoint", version:$ver, generated_at:$ts,
  cfg_sha256:$cfg_sha,
  tools:{ python:$py, jq:$jqv, node:$node, curl:$curl },
  git:{ rev:$git_rev, branch:$git_branch, dirty:$git_dirty, diff_files:$diff_files },
  services:{ ingest_health:$ingest_code },
  offenders:$offenders,
  foedus:$foedus
}' > "$CHK"
ln -sfn "$(basename "$CHK")" "$SR/receipts/sr_watch_checkpoint_v0_1.json"

# Penitential Rite if needed
if [[ "$foedus" != "intactum" ]]; then
  PR="$SR/receipts/sr_penitential_rite_${TS}_${VER}.md"
  {
    echo "# Penitential Rite · $TS"
    echo ""
    echo "- ingest /health: $ing_code"
    echo "- offenders (${#offenders[@]}):"
    for o in "${offenders[@]}"; do echo "  - [ ] fix name → $o"; done
    echo "- git dirty: $git_dirty file(s)"
    echo ""
    echo "Rite: rename offenders to schema, ensure ingest up (systemctl --user restart sr-ingest.service), commit, re-run checkpoint."
  } > "$PR"
fi

# receipts index
"$SR/bin/sr_receipts_reindex.sh" >/dev/null || true

# Package a dossier
DOS="$SR/snapshots/sr_dossier_${TS}_${VER}.tgz"
tar -czf "$DOS" \
  -C "$SR" \
  config/decisionhub.config.json \
  decisionhub/start_here_v0_2.html \
  forge/reply_builder_v0_1.html \
  receipts/receipts_timeline_viewer_v0_1.html \
  forge/gate_reports/index_v0_1.html \
  decisionhub/watch_checkpoint_viewer_v0_1.html \
  receipts/index_v0_1.json \
  "receipts/$(basename "$CHK")" \
  receipts/sr_watch_checkpoint_v0_1.json \
  logs || true
echo "Dossier: $DOS"
