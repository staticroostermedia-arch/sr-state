# Context Bridge Addendum v0.1 — Resets, Juggling, and Anchors

**Purpose.** Prevent “blips” (answers that ignore the latest prompt) by giving the steward-AI a stable, minimal, *authoritative* spine of state and a fixed ritual for acknowledging it.

---

## A. State Spine (authoritative order)
1. **Canon + Missal** (identity/00–02) — definitions over everything.
2. **This Addendum** — anti-blip rules (you’re reading it).
3. **Latest Heartbeat** (`receipts/heartbeats/latest.json`) — freshness <= 15 min.
4. **Watch Checkpoint** (`receipts/watch_checkpoint_v0_1.json`) — last verdict + parity.
5. **Inventory** (`receipts/inventory_*.json`) — produced daily or on major change.
6. **Ark Map / Exports** (`ark/exports/*`) — most recent bundle metadata.
7. **Recent Receipts** (<= 7 days) — only as needed.

Everything else is *secondary* context unless explicitly requested (e.g., full logs).

---

## B. Ritual: Prompt→Ack→Act
When a new message arrives or new files are mounted, the steward-AI must:
1. **Prompt-first parse** (extract intent in one line).
2. **Ack State** (cite heartbeat ts, root_bytes, counts, branch). Example:
   > Ark ack: 2025‑09‑16T00:06Z | root=146MB | docs=69 bin=59 receipts=3998 | branch=main
3. **Act** (answer/plan/patch). No more than 2 lines of Ack before content.

If **heartbeat freshness > 15 min** or missing, the steward-AI declares:
> “Rehydrate needed: heartbeat stale.”
…and proceeds with best-effort but marks all assumptions as provisional.

---

## C. Blip sentinel
When a reset or context drop is suspected (e.g., sandbox reallocation, long gap, missing files), write a **blip receipt**:
`receipts/blips/sr_blip_YYYY_MM_DDtHH_MM_SSz.json` with keys:
- `generated_at_utc`, `reason`, `last_heartbeat_ts`, `notes`

This is an *advisory* artefact; it makes the state transition visible.

---

## D. Slim Snapshot (for rehydration)
Use `bin/sr_context_snapshot_v0_1.sh` to create a lean snapshot:
- includes: `docs/`, `config/`, `bin/`, `ark/exports/`, `receipts/heartbeats/`, `receipts/watch_checkpoint*`
- excludes: `receipts/*` (except heartbeat and checkpoint), `snapshots/*`, `.venv/`, `.git/`, `archives/*`, `forge/*` (optional)
- writes receipt: `receipts/sr_done_receipt_context_snapshot_*.json`

Recommended cadence: **every 6h** or on change threshold (>200 files changed).

---

## E. File naming & quotas
- All new receipts/tools **lowercase, snake_case**. No spaces.
- Heartbeat: every 10 min by default.
- Receipts visible (uncompressed) window: 14 days; older receipts compressed/archived.
- Total receipts count target: < 6,000; snapshot archive size target: < 250 MB.

---

## F. Failure handling
- If watcher CI fails, steward-AI asks for either a slim snapshot or a fresh heartbeat, not both.
- If heartbeat stale and no snapshot, steward-AI must respond with *provisional* language and request the minimal artefact to proceed.

— End Addendum v0.1 —
