#!/usr/bin/env bash
set -euo pipefail
# Pull latest 'cloud_latest' artifact from GitHub Actions and store it as a heartbeat receipt.
# Env:
#   GH_OWNER (required)
#   GH_REPO  (required)
#   GH_TOKEN (required if gh CLI is unavailable)
#   SR_HOME  (optional, default ~/static-rooster)

SR_HOME="${SR_HOME:-$HOME/static-rooster}"
OUT_DIR="$SR_HOME/receipts/heartbeats"
TMP_DIR="$SR_HOME/tmp"
mkdir -p "$OUT_DIR" "$TMP_DIR"

repo="${GH_OWNER?Set GH_OWNER}"/"${GH_REPO?Set GH_REPO}"

have_gh=0
if command -v gh >/dev/null 2>&1; then
  have_gh=1
fi

artifact_path="$TMP_DIR/cloud_latest.json"

if [ "$have_gh" -eq 1 ]; then
  # Try to find the newest successful run that produced the artifact 'cloud_latest'
  # and download just that artifact.
  run_id="$(gh run list --repo "$repo" --limit 1 --json databaseId --jq '.[0].databaseId' || true)"
  if [ -n "${run_id:-}" ]; then
    gh run download "$run_id" --repo "$repo" --name cloud_latest -D "$TMP_DIR" >/dev/null 2>&1 || true
  fi
  # Fallback: attempt generic latest artifact download
  if [ ! -s "$artifact_path" ]; then
    gh run download --repo "$repo" --name cloud_latest -D "$TMP_DIR" >/dev/null 2>&1 || true
  fi
fi

# Curl fallback via REST API
if [ ! -s "$artifact_path" ]; then
  : "${GH_TOKEN?Set GH_TOKEN when gh CLI is not available}"
  api="https://api.github.com/repos/${repo}/actions/artifacts?per_page=100"
  json="$(curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/vnd.github+json" "$api")"
  # Pick newest non-expired artifact with name cloud_latest
  zip_url="$(printf '%s\n' "$json" | jq -r '.artifacts | map(select(.name=="cloud_latest" and .expired==false)) | sort_by(.created_at) | reverse | .[0].archive_download_url // empty')"
  if [ -n "$zip_url" ]; then
    zip_file="$TMP_DIR/cloud_latest.zip"
    curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/vnd.github+json" "$zip_url" -o "$zip_file"
    # The zip contains exactly one file (cloud_latest.json). Extract it.
    if command -v unzip >/dev/null 2>&1; then
      unzip -p "$zip_file" > "$artifact_path" || true
    else
      # minimal unzip using python if available
      if command -v python3 >/dev/null 2>&1; then
        python3 - << 'PY'
import sys, zipfile
zf = zipfile.ZipFile(sys.argv[1])
names = zf.namelist()
with zf.open(names[0]) as f:
    sys.stdout.buffer.write(f.read())
PY
        "$zip_file" > "$artifact_path" || true
      fi
    fi
  fi
fi

if [ ! -s "$artifact_path" ]; then
  echo "ERROR: could not obtain cloud_latest artifact for $repo" >&2
  exit 1
fi

ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
mkdir -p "$OUT_DIR"
dest="$OUT_DIR/cloud_latest.json"
cp -f "$artifact_path" "$dest"

# Optional: verify sha matches repo HEAD (best-effort)
sha_cloud="$(jq -r '.sha // empty' "$dest" || true)"
sha_local="$(git -C "$SR_HOME" rev-parse HEAD 2>/dev/null || echo "")"
verdict="unknown"
if [ -n "$sha_cloud" ] && [ -n "$sha_local" ]; then
  if [ "$sha_cloud" = "$sha_local" ]; then verdict="match"; else verdict="mismatch"; fi
fi

# Emit a small receipt
printf '{"schema":"sr.cloud_pull.v0_1","generated_at_utc":"%s","repo":"%s","dest":"%s","sha_cloud":"%s","sha_local":"%s","verdict":"%s"}\n' \
  "$ts" "$repo" "$dest" "$sha_cloud" "$sha_local" "$verdict" > "$OUT_DIR/last_pull.json"

echo "Pulled cloud heartbeat to: $dest (verdict: $verdict)"
