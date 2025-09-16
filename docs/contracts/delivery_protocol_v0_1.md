# Delivery Protocol (v0.1)

**Purpose**  
Define how assets (docs, configs, code) are delivered so they are auditable, portable, and receipt-driven.

**Placement**  
`static-rooster/docs/contracts/delivery_protocol_v0_1.md`

## Rules

1. **Packaging**
   - Every drop is delivered as a `.tgz` bundle plus an installer script.
   - The bundle contains files under `docs/`, `config/`, etc. in canonical layout.

2. **Installer**
   - Must be idempotent.
   - Must support `SR_APPLY=0` (dry-run) and `SR_APPLY=1` (apply).
   - Must always write a receipt in `~/static-rooster/receipts/`.
   - Never destructive: only copies versioned files, appends changelog.

3. **Receipts**
   - Receipt schema: `sr.receipt.v0_1`.
   - Fields: `generated_at_utc`, `tool_name`, `status`, `summary`, `files`.
   - Receipts or it didn’t happen.

4. **Index Rebuild**
   - Installer does **not** rebuild receipt index.
   - A separate tool `sr_rebuild_receipts_index.sh` handles that.

5. **Changelog**
   - Installer appends to `99_SR_Change_Log.md` with timestamp + files.

6. **Versioning**
   - New delivery bumps bundle version (v0_3 here).
   - Old bundles are kept; pruning handled separately.
