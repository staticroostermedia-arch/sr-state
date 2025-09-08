# Static Rooster • Canon v1.0

**Telos**  
Build a self-auditing, offline‑first field ops + planning kit for EH1003006 that keeps working under tight memory, power, and network constraints—and proves its own integrity every few hours.

## Constraints (embraced, not lamented)
- **No background agency**: the model can’t run unattended; the Runner does. We exchange artifacts (drops, zips, patches).  
- **Finite context**: we chunk work into tiny, typed steps and persist state (IndexedDB/localStorage).  
- **Offline‑first**: all tools must run in the browser; Starlink is optional, not required.  
- **Auditability**: every bundle carries `manifest.json` + a recent checkpoint; filename rules are non‑negotiable.

## Architecture (today)
- **Runner (spine)**: sequences small steps → emits drops → pauses on Rite. v0.1.4 (live), v0.1.5 (adds code‑cut + patch emit).  
- **Hub**: export/verify zips; v0.2.3 shows the seal badge.  
- **AI Bridge**: queue of `ask_assistant` (manual now; API later).  
- **Watchlight**: green/red seal from last checkpoint.  
- **Side tools**: Name Forge, Drop Inspector, Plan Composer, Manifest Verify, Drop Zipper, Zip Ticker.

## Invariants
- **Filename rule**: lowercase, no spaces, end with `_vX` or `-vX` before extension.  
- **Seal**: “foedus intactum” = config + filenames unchanged since last checkpoint; else **Penitential Rite**.  
- **Artifacts**: everything is a file (tool HTML, patch JSON, drop JSON, bundle ZIP).  
- **Map tools**: always carry version (e.g., `sr_path_profiler_v0_1_0.html`).

## Step set (core)
- `canon_snapshot` (read config)  
- `tool_skeleton_cut` (mint minimal tool HTML)  
- `config_patch_emit` (register tool; bump config version)  
- `parity_tick` (lightweight consistency)  
- `checkpoint_emit` (seal or rite)  
- `penitential_rite` (pause; corrective actions)  
- `trace_dump`, `bundle_watch`, `verify_manifest`  
- `ask_assistant` (structured ask → artifact return via Bridge)

## Watch Bundle
`manifest.json` → `{ schema, generatedAt, files:[{path,sha256,size}] }`  
Drops → `drop_cNN_sM_kind.json` with `schema:'eh1003006.drop.v1'`.

## Ritual (cadence)
- **Every ~2 hours**: Checkpoint; if amber, perform Rite before continuing.  
- **Nightly**: Export bundle; verify; ledger entry.  
- **Daily**: Merge patches; bump config; run audit plan.

## Sisyphus, Reframed (parable)
The stone is **state**; the hill is **entropy**. We push smarter: a conveyor of tiny steps, a seal that shouts when drift appears, and zips that bottle progress. The gods get bored; we get Rome.

## Parable of the Last Day — *The Stone, the Ladder, and the Rooster*

A worker hauled a stone up a hill each dawn. At dusk it rolled back—entropy laughing. One night the worker stopped hauling and built a **ladder** instead: small rungs, evenly spaced. Each rung had a name burned into it so it could not be forgotten. At the top of every few rungs perched a **rooster** who would crow—*checkpoint!*—and stamp a wax seal: **foedus intactum** if nothing had drifted, or a red ribbon if something had.

When a rung split or a name smudged, the worker didn’t curse the hill. They performed a **Penitential Rite**: pause, replace the rung, carve the name clean, renew the covenant, and continue climbing. The stone still waited, but the ladder grew; the worker began to ascend faster than the hill could erode.

**Moral:** The stone is **state**; the hill is **entropy**. Our ladder is **small, typed steps**. The rooster is our **Checkpoint**. The Rite is our **rapid correction ritual**. We don’t defeat gravity—we outpace it with disciplined increments and auditable seals.

### Release Rite (condensed)
1. **Forge names** (lowercase, versioned).  
2. **Run clusters** (small, resumable).  
3. **Checkpoint**: if green → proceed; if not → **Rite** (halt → correct → re-checkpoint).  
4. **Bundle with manifest** → **Verify** → **Ledger entry**.  
5. **Hand off** bundle to the Assistant for stitching and plan refinement.

## Next 24h plan (after current run finishes)
1. Switch to **Runner v0.1.5** (code‑mint + patch emit).  
2. Apply patches for: Raster Loader, Path Profiler, Canopy Histogram, AI Bridge 0.2.0, Hub 0.2.3.  
3. Run **Build plan (4h)**; Zip Ticker every 30 min; Watchlight pinned.  
4. Hand me the first bundle; I return: merged config, refactors, and a sharper plan.  
5. Repeat: build → checkpoint → export → verify → integrate.

— Canon v1.0
