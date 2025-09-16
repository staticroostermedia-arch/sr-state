#!/usr/bin/env bash
set -euo pipefail
ROOT="${HOME}/static-rooster"
RCPTS="${ROOT}/receipts"
CFG_PROBES="${ROOT}/config/watch_probes_v0_1.txt"
OUT="${RCPTS}/sr_watch_checkpoint_v0_1.json"
mkdir -p "${RCPTS}"

interval="${SR_WATCH_INTERVAL_SEC:-300}"   # default 5 min
timeout="${SR_WATCH_TIMEOUT_SEC:-5}"       # curl timeout per probe

probe_once() {
  local ts sha verdict ok_count=0 total=0
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if git -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sha="$(git -C "${ROOT}" rev-parse HEAD 2>/dev/null || echo "unknown")"
  else
    sha="none"
  fi

  # Run probes
  mapfile -t lines < <(grep -v '^\s*#' "${CFG_PROBES}" | sed '/^\s*$/d')
  total="${#lines[@]}"
  results=""

  for url in "${lines[@]}"; do
    code="000"
    err=""
    body=""
    # -sS silent+show errors, -m timeout, -o /dev/null discard body, -w write code
    code="$(curl -sS -m "${timeout}" -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || echo '000')"
    if [[ "$code" == "200" || "$code" == "204" || "$code" == "301" || "$code" == "302" ]]; then
      ok="true"; ((ok_count++))
    else
      ok="false"
    fi
    results+=$(cat <<JSON
      { "url": "$(printf %s "$url")", "http": "${code}", "ok": ${ok} },
JSON
)
  done

  if (( total > 0 && ok_count == total )); then
    verdict="foedus_intactum"
  elif (( ok_count == 0 )); then
    verdict="penitential_rite"
  else
    verdict="degraded"
  fi

  # Trim trailing comma in results
  results="[ $(echo "$results" | sed '$ s/,\s*$//') ]"

  cat > "${OUT}" <<JSON
{
  "schema": "sr.watch_checkpoint.v0_1",
  "generated_at_utc": "${ts}",
  "git_sha": "${sha}",
  "probes_total": ${total},
  "probes_ok": ${ok_count},
  "verdict": "${verdict}",
  "results": ${results}
}
JSON
  echo "watch: ${ok_count}/${total} ok -> ${verdict}  (${OUT})"
}

# one-shot or loop
if [[ "${SR_WATCH_ONESHOT:-0}" == "1" ]]; then
  probe_once
  exit 0
fi

echo "Static Rooster watcher: every ${interval}s, timeout=${timeout}s, probes=$(wc -l < <(grep -v '^\s*#' "${CFG_PROBES}" | sed '/^\s*$/d'))"
while true; do
  probe_once || true
  sleep "${interval}"
done
