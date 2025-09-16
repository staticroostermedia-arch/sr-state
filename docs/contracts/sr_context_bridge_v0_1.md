# SR Context Bridge v0.1

**Purpose**
Bind the steward-AI to the *actual* state of `~/static-rooster` before planning/building.

**Rule of Use**
1. Before any feature planning or code delivery, provide a *fresh snapshot* & *inventory receipt*:
   - `~/static-rooster/bin/sr_inventory_scan_v0_1.sh`
   - `~/static-rooster/bin/sr_make_state_snapshot_v0_1.sh` (or Ark `ark/exports/*` bundle)
2. Steward-AI must read the inventory JSON and cite any drift/bloat before proposing changes.
3. Background watchers (GitHub Actions / cron) must produce at least one artifact every 2h (bundle or heartbeat).
4. All filenames follow Canon: lowercase snake_case; versioned tiles: `_vX_Y_Z.html`; timestamps use `YYYY_MM_DDtHH_MM_SSz`.
5. **Non‑destructive by default**: cleanup moves files to `~/static-rooster/quarantine/<ts>/` unless `SR_PURGE=1` is set.
6. Each action writes a receipt `sr_done_receipt_*_YYYY_MM_DDtHH_MM_SSz.json` under `~/static-rooster/receipts/`.

**Inputs**
- Latest Ark bundle or state snapshot
- Inventory receipt (`sr_inventory_*.json`)

**Outputs**
- Cleanup receipts (size reclaimed, offenders, actions)
- Optional archive tarballs for old receipts

**Kill Switches**
- If inventory shows missing Canon files (Missal/Canon/Parables/Invocations), abort with `verdict: penitential_rite`.
- If more than 20% of filenames are offenders, quarantine only; never purge.

**Acceptance**
- Steward-AI cites inventory lines when recommending trims.
- Post-cleanup, a new inventory is emitted showing reduced bloat.
