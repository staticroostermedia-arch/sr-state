# Static Rooster — Dossier Spec v0.1.1

A **Dossier** is a two-hour work product packet with context + attachments. Hand it to the Assistant for stitching.

## Files
- `dossier.json` — machine-readable summary (may include `"por_ref": "por.json"`)
- `dossier.md` — human summary
- `manifest.json` — (optional) hashes for `/attachments/*`
- `por.json` — **optional Plan of Record snapshot**, if provided
- `attachments/` — (optional) included files (drops, patches, tools)

## JSON schema (minimal additions)
```json
{{
  "schema": "sr.dossier.v0_1",
  "generatedAt": "ISO-8601",
  "window": {{ "span_minutes": 120 }},
  "parcelId": "EH1003006",
  "site": "parcel|canby",
  "seal": "foedus intactum | penitential required | (no checkpoint found)",
  "captures": 0,
  "diffs": {{ "added": 0, "removed": 0, "changed": 0 }},
  "filename_issues": 0,
  "operator_note": "…",
  "por_ref": "por.json",
  "includes": [ {{ "path": "attachments/…", "sha256": "…", "size": 123 }} ],
  "next_steps": [ {{ "kind": "plan", "ref": "plan_build_4h_v0_1.json" }} ]
}}
```

## Naming
`sr_dossier_YYYYMMDD_HHMM_v0_1.zip`

## Handoff contract
- Assistant validates `manifest.json` and uses `dossier.json` + `por.json` to drive integration order.  
- Assistant returns a **Return Dossier** with a `return.md`, `return.json`, fixed files, and a `next_plan.json`.
