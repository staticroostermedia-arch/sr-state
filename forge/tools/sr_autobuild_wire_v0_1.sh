#!/usr/bin/env bash
# SR Autobuild Wire v0.1
set -u

ROOT="${HOME}/static-rooster"
cd "$ROOT" || exit 2

need(){
  if [[ ! -f "$1" ]]; then
    echo "MISSING: $1"
    MISSING=1
  fi
}

MISSING=0
need "forge/tools/sr_runner_wrap_and_dump_v0_1.sh"
need "forge/tools/sr_emit_snapshot_and_watch_v0_1.sh"
need ".config/systemd/user/sr-runner.service"
need ".config/systemd/user/sr-runner.timer"
need ".config/systemd/user/sr-emit.service"
need ".config/systemd/user/sr-emit.timer"
need ".config/systemd/user/sr-exec.service"
need ".config/systemd/user/sr-exec.timer"

if (( MISSING )); then
  echo "Fix the missing items above, then re-run."
  exit 1
fi

# Reload + enable + start timers/services
systemctl --user daemon-reload || true

for u in \
  sr-runner.timer sr-runner.service \
  sr-emit.timer   sr-emit.service \
  sr-exec.timer   sr-exec.service
do
  systemctl --user enable --now "$u" || true
done

echo "== Timers =="
systemctl --user list-timers --all --no-pager | egrep 'sr-(runner|emit|exec)'

echo "== Quick tail (runner) =="
journalctl --user -u sr-runner.service -n 40 --no-pager || true

TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
OUT="receipts/sr_autobuild_wire_${TS}.json"
cat > "$OUT" <<JSON
{ "schema":"sr.autobuild.wire.v0_1", "generated_at":"$TS", "result":"ok" }
JSON
echo "receipt: $OUT"

echo
echo "Open:  http://127.0.0.1:8888/forge/ops/sr_dashboard_v0_2.html"
echo "Receipts: ~/static-rooster/receipts/"
