#!/usr/bin/env bash
set -euo pipefail

OWNER="${GH_OWNER:-staticroostermedia-arch}"
REPO="${GH_REPO:-decisionhub}"
WORKFLOW_NAME="Ark Watcher"
ART_NAME="cloud_latest"
CACHE_DIR="${HOME}/.cache/sr"
OUT_JSON="${CACHE_DIR}/cloud_latest.json"
RCPTS="${HOME}/static-rooster/receipts/heartbeats"
mkdir -p "${CACHE_DIR}" "${RCPTS}"

# Find latest successful run of the Ark Watcher on main
run_id="$(gh run list \
  --repo "${OWNER}/${REPO}" \
  --workflow "${WORKFLOW_NAME}" \
  --branch main \
  --limit 1 \
  --json databaseId,status,conclusion \
  --jq '.[0].databaseId')"

if [[ -z "${run_id}" || "${run_id}" == "null" ]]; then
  echo "No Ark Watcher runs found on main."
  exit 2
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# Download artifact named cloud_latest from that run
gh run download "${run_id}" \
  --repo "${OWNER}/${REPO}" \
  --name "${ART_NAME}" \
  --dir "${tmp_dir}"

# Expect a single JSON file in the artifact
artifact_json="$(ls -1 "${tmp_dir}"/*.json 2>/dev/null | head -n1 || true)"
if [[ -z "${artifact_json}" ]]; then
  echo "Artifact ${ART_NAME} did not contain a JSON file."
  exit 3
fi

# Move it into cache as cloud_latest.json
mv -f "${artifact_json}" "${OUT_JSON}"

# Compare sha from cloud vs local HEAD
cloud_sha="$(jq -r '.sha // empty' "${OUT_JSON}" || true)"
local_sha="$(git rev-parse HEAD || echo '')"

verdict="unknown"
if [[ -n "${cloud_sha}" && -n "${local_sha}" ]]; then
  if [[ "${cloud_sha}" == "${local_sha}" ]]; then
    verdict="match"
  else
    verdict="mismatch"
  fi
else
  verdict="incomplete"
fi

# Receipt
ts_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
rcpt="${RCPTS}/cloud_heartbeat_${ts_utc}.json"
jq -n --arg schema "sr.cloud_heartbeat.v0_1" \
      --arg generated_at_utc "${ts_utc}" \
      --arg sha "${cloud_sha}" \
      --arg local_sha "${local_sha}" \
      --arg verdict "${verdict}" \
      '{schema:$schema, generated_at_utc:$generated_at_utc, sha:$sha, local_sha:$local_sha, verdict:$verdict}' \
  > "${rcpt}"

echo "Pulled cloud heartbeat -> ${OUT_JSON}"
echo "VERDICT: ${verdict} (cloud:${cloud_sha} vs local:${local_sha})"
