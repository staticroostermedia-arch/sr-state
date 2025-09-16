# Tool Spec Schema (v0.1)

**Purpose**  
Define the minimal, machine-readable spec the generator consumes to cut a Pip-Boy tool that plugs cleanly into DecisionHub.

**Placement**  
`static-rooster/docs/contracts/tool_spec_schema_v0_1.md` (Markdown authority). Validation mirror (optional) under `docs/schemas/tool_spec_schema_v0_1.json`.

**Definition of Done (DoD) for any generated tool**  
- Visible version badge in UI.
- QuickCheck diagnostics block present (health JSON).
- Emits `ready`, `status`, `error`, `capture` via postMessage envelope.
- Mobile-friendly at 360 px width (uses UI Kit tokens).
- Filename includes `_vX_Y_Z` and avoids spaces/parentheses.

---

## 1) Spec shape (authoring)

Human-authored YAML or JSON with these sections:

```yaml
schema: sr.tool.spec.v0_1
key: planner_527              # stable tile key (not the filename)
name: Online Planner          # human label
version: 5.3.0                # semantic; filename will be _v5_3_0
category: planning            # optional: groups in the hub

purpose: >
  Draw/edit field polygons, toggle rasters (dtm/slope/aspect),
  export GeoJSON. Two sites: parcel (EH1003006) and canby.

inputs:
  datasets:
    rasters: [dtm, slope, aspect]   # by key, not path.
  sites: [parcel, canby]            # must match DecisionHub sites.

ui:
  layout: tabs                       # 'tabs' | 'single'
  blocks:
    - type: layers-panel             # standard component
      title: Layers
      binds:
        rasters: rasters
    - type: plan-editor
      title: Plans
      options:
        draw: [polygon, erase]
        export: geojson

events:
  ready: { versionLabel: "Planner v5.3.0" }  # generator injects automatically
  status: { ok: true, notes: "loaded" }
  capture:
    on: export   # semantic trigger inside this tool
    schema: eh1003006.capture.v1  # envelope.

acceptance:
  requireQuickCheck: true
  requireMobileBreakpoints: [360x640, 412x915]
  minimumBytes: 6000
  forbidFilenames: ["(", ")", " "]
```

**Notes**
- `key` maps to the tile registry; the hub uses this to keep identity stable across versions.
- `datasets` and `sites` must address **keys**, not raw file paths, per the adapter rule.
- `ui.blocks` are assembled from a standard component catalog (separate doc) to keep tools consistent.

---

## 2) Generator contract (what the machine must do)

Given a valid spec, the generator shall:

1. **Compose HTML+JS** using Pip-Boy tokens (no custom CSS variables).
2. **Stamp versioned filename**: `{key or name}_vX_Y_Z.html` (snake_case, no spaces/parentheses).
3. **Wire postMessage envelope** with `ready/status/error/capture`.
4. **Inject QuickCheck** (health JSON emitter).
5. **Register tile** by updating `config/decisionhub_config.json` (key stable, badge/version bumped).
6. **Write receipt** `sr_done_receipt_tool_cut_*.json` and update `receipts/index_v0_1.json`.
7. **Hand to acceptance harness**; refuse to register on failure.

---

## 3) Acceptance harness (summary; full checklist in its own doc)

- **Filename gate**: contains `_vX_Y_Z`; rejects spaces/()`s.
- **Size floor**: `>= minimumBytes` (prevents 3 KB stubs).
- **DOM probes**: finds title, version badge, QuickCheck block, and main action(s).
- **Viewport test**: renders without overflow at 360 px.
- **Event probes**: `ready` and `status` fire within 2s; `capture` fires on declared trigger.
- **HTTP 200**: final route passes the Probe Contract.

---

## 4) Versioning & regression

- **Immutable builds**: new `_vX_Y_Z` files; never overwrite. Prune policy keeps newest per hash weekly.
- **No lost tile keys**: registry must retain existing `key`s; deprecations require notes.

---

## 5) Example: “Parcel Map Planner” (minimal)

```yaml
schema: sr.tool.spec.v0_1
key: planner_parcel
name: Parcel Map Planner
version: 5.3.0
purpose: Draw polygons; export GeoJSON
inputs: { datasets: { rasters: [dtm, slope] }, sites: [parcel] }
ui:
  layout: tabs
  blocks:
    - { type: layers-panel, title: Layers, binds: { rasters: rasters } }
    - { type: plan-editor,  title: Plans,  options: { draw: [polygon], export: geojson } }
events: { capture: { on: export, schema: eh1003006.capture.v1 } }
acceptance: { requireQuickCheck: true, minimumBytes: 6000, forbidFilenames: ["(",")"," "] }
```

## 6) Compliance & receipts

- Every spec addition or change is logged in `99_SR_Change_Log.md` and produces a receipt `sr_done_receipt_contract_add_v0_1.json`.
