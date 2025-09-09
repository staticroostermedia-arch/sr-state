#!/usr/bin/env bash
set -euo pipefail

ROOT="${HOME}/static-rooster"
OUTDIR="${ROOT}/snapshots"
TS="$(date +%Y%m%d_%H%M%S)"
TGZ="${OUTDIR}/sr_theme_bundle_${TS}.tgz"

# Files I need to inspect (add more if you want)
FILES=(
  "config/decisionhub.config.json"

  # Start Here shell + the 4 tools
  "decisionhub/start_here_v0_2.html"
  "forge/reply_builder_v0_1.html"
  "receipts/receipts_timeline_viewer_v0_1.html"
  "forge/gate_reports/index_v0_1.html"
  "decisionhub/watch_checkpoint_viewer_v0_1.html"

  # Theme CSS (shared + any local overrides if present)
  "docs/staticrooster_uikit_v1_0.css"
  "docs/ui_overrides_v1.css"

  # Small helpers (so I can reproduce locally)
  "bin/sr_cfg_rebuild.py"
  "bin/sr_theme_fix.sh"
)

mkdir -p "${OUTDIR}"

# Keep only files that exist; warn about any that don't
HAVE=(); MISSING=()
for f in "${FILES[@]}"; do
  if [[ -e "${ROOT}/${f}" ]]; then
    HAVE+=("${f}")
  else
    MISSING+=("${f}")
  fi
done

if ((${#MISSING[@]})); then
  echo "WARN: missing files:" >&2
  printf '  - %s\n' "${MISSING[@]}" >&2
fi

# Create .tgz
tar -C "${ROOT}" -czf "${TGZ}" "${HAVE[@]}"
echo "Wrote ${TGZ}"
sha256sum "${TGZ}" | tee "${TGZ}.sha256"

# Also make a .zip copy if 'zip' exists
if command -v zip >/dev/null 2>&1; then
  ZIP="${TGZ%.tgz}.zip"
  (cd "${ROOT}" && zip -9r "${ZIP}" "${HAVE[@]}")
  echo "Wrote ${ZIP}"
  sha256sum "${ZIP}" | tee "${ZIP}.sha256"
fi
