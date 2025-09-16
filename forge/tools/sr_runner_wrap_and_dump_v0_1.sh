#!/bin/sh
# Chain the existing runner snapshot wrap, then emit a status dump.
# Never crash the service if the dumper fails.
set -eu
ROOT="${HOME}/static-rooster"
cd "$ROOT" || exit 2

# Prefer the known wrap v0_1; if you later bump, symlink this path.
WRAP="forge/tools/sr_runner_snapshot_wrap_v0_1.sh"
if [ ! -x "$WRAP" ]; then
  echo "WARN: $WRAP not executable or missing; attempting anyway..." >&2
fi

# 1) Do the usual runner work (snapshot + checkpoint, etc.)
bash "$WRAP" || true

# 2) Emit a status dump receipt the dashboard can read
support/tools/sr_status_dump_v0_3.sh || true

exit 0
