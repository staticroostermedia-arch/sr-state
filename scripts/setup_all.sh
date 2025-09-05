#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT"
bash scripts/build.sh
echo "Build complete. To serve locally:"
echo "  bash scripts/serve.sh 8000"
echo "To initialize a Git repo and push:"
echo "  bash scripts/init_github.sh <git@github.com:USER/REPO.git>"
