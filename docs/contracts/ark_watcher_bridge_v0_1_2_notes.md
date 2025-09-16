# Ark Watcher Bridge v0.1.2 — Heartbeat commits

- If no new bundles are produced under `ark/exports/`, the workflow now creates
  `ark/exports/heartbeat_YYYY_MM_DDtHH_MM_SSz.json` and commits it.
- This guarantees a visible commit per run, improving traceability.
- Heartbeats use lowercase snake_case timestamps with `t/z`.
