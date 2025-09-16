# Runner Loop Contract (v0.1)

**Purpose**  
Define how the Runner consumes tool specs, builds tools, verifies them, and maintains the ledger.

**Placement**  
`static-rooster/docs/contracts/runner_loop_contract_v0_1.md`

**Cycle (Tick → Tock)**

1. **Intake**
   - Read new tool specs from `specs/` folder.
   - Specs must validate against `tool_spec_schema_v0_1.md`.

2. **Build**
   - Compose HTML+JS using Component Catalog.
   - Apply StaticRooster UI Kit tokens.
   - Stamp filename with `_vX_Y_Z`.

3. **Acceptance**
   - Run checks from `tool_acceptance_checklist_v0_1.md`.
   - Reject if any failure.

4. **Register**
   - Add/Update tile in `config/decisionhub_config.json`.
   - Tile `key` remains stable; badge/version updates.

5. **Probe**
   - Request route on localhost.
   - Log HTTP code + ms latency.

6. **Ledger**
   - Write snapshot into `snapshots/<UTC>/`.
   - Write receipt: `sr_done_receipt_runner_cycle_*.json`.
   - Update receipts index.

7. **Prune**
   - Deduplicate by hash.
   - Keep newest valid version per tile key.
   - Quarantine or delete older copies.

**Verdict**
- If all probes succeed: `foedus intactum`.
- On failure: `penitential_rite` + remedial log.
