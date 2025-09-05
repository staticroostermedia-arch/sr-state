# DecisionHub (Pip‑Boy Shell) — Feature Contract v1.0
Date: 2025-08-29
Status: Stable

## 0. Purpose
This contract defines how tools plug into the **DecisionHub** Pip‑Boy shell without breaking existing systems. It standardizes: theming, config, routing, messaging, diagnostics, and regression rules.

## 1. Versioning & Labels
- Every artifact shows a visible version label in UI.
- Semantic bump rules:
  - PATCH: copy, text, or non‑breaking CSS.
  - MINOR: new tiles or new message fields.
  - MAJOR: any removal or rename — must include **DEPRECATION** + migration notes.

## 2. Config: Single Source of Truth
DecisionHub reads `DecisionHubConfig` (JSON or embedded). Tools **must** read from the same object — no hardcoded parcel paths.

Required keys (see schema file):
- `version`, `parcelId`, `sites` (e.g., `parcel`, `canby`), `rasters` (dtm, aspect, slope, chm, combined), `tools` (tile registry).

## 3. Theme Tokens (Pip‑Boy)
The shell and tools use shared CSS variables:
```
--bg, --grid, --text, --glow, --accent, --warn, --danger
```
Do not override token names; extend with new tokens if needed.

## 4. Tool Registry (Tiles)
Tiles are data‑driven from `DecisionHubConfig.tools` where each entry is:
```json
{
  "key": "planner_527",
  "name": "Online Planner",
  "href": "eh1003006_online_planner_v5_2_7.html",
  "badge": "v5.2.7",
  "category": "planning",
  "enabled": true
}
```
- **No spaces** or parentheses in filenames. Use `snake_case`.
- Turning a tool on/off is a config change only.

## 5. Iframe Contract (postMessage API)
Every tool loaded in the shell iframe **should** post the following on ready and on significant state changes.

### 5.1 Message Envelope
```js
window.parent.postMessage({
  type: "DH_TOOL_EVENT",
  toolKey: "planner_527",
  event: "ready|status|error|capture",
  payload: { /* event-specific */ },
  version: "x.y.z"
}, "*");
```

### 5.2 Standard Events
- `ready`: tool is initialized.
  - payload: `{ versionLabel, needsSensors?: boolean }`
- `status`: heartbeat / health.
  - payload: `{ ok: boolean, notes?: string }`
- `error`: surfaced error.
  - payload: `{ code, message, details? }`
- `capture`: tool reports a capture record (see §7).
  - payload: `CaptureRecord`

The shell listens and may display badges, toasts, or push captures to the backend.

## 6. Diagnostics & Bug Reports
The shell renders a **QuickCheck** and **Generate Report** button.
Generated JSON (v1) includes: versions, environment, dataset presence, link checks, permission state, filename warnings, and site context.

`schema: "eh1003006.dh.health.v1"`

## 7. Capture Record Schema (v1)
All capture UIs (your integrated app or Safe‑Mode Tricorder) **emit the same structure**:
```json
{
  "schema": "eh1003006.capture.v1",
  "when": "ISO-8601",
  "site": "parcel|canby",
  "parcelId": "EH1003006",
  "tag": "string|null",
  "geo": {
    "lat": 0, "lon": 0, "acc_m": 0,
    "alt_m": null, "heading_deg": null, "speed_mps": null
  },
  "sensors": {
    "orientation": {"alpha":null,"beta":null,"gamma":null},
    "motion": {"acc":{}, "accG": {}, "rot": {}, "interval": null},
    "wifiSurvey": null
  },
  "media": [{"kind":"photo","uri":"file-or-dataUrl","mime":"image/jpeg"}],
  "device": {"ua":"...", "platform":"...", "vendor":"..."},
  "app": {"name":"...", "version":"..."}
}
```

## 8. Datasets (Adapters)
Config keys map to local files/URLs; tools must request by **key**, not path:
- `rasters`: `dtm`, `aspect`, `slope`, `chm`, `combined`
- `sites.canby.imagery`: orthophoto/tiles for 1736 Canby

## 9. Serving & Security
- Serve over **http(s)** or `localhost` for sensors (camera/geolocation/motion).
- Avoid `file://` usage on phones; it breaks navigation and permissions.

## 10. Regression Protocol
- Visible version label on shell + tools.
- Parity gate: no lost tile IDs; existing config keys remain valid.
- Changelog per release; deprecations must include migration notes.

## 11. Accessibility & Mobile
- Tap targets ≥ 44px.
- High‑contrast Pip‑Boy defaults, prefers‑reduced‑motion respected.
- Offline‑tolerant capture: queue in localStorage and export.

## 12. Backend Ingest (v0)
- `POST /ingest` (multipart): `record.json` + media.
- Store at `captures/YYYY-MM-DD/<timestamp>_<site>_<tag>.json` (+ media).
- Append GeoJSON Feature to `captures.geojson`.
- Optional: ACK with `{ok:true, id}`.
