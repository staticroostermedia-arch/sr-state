# Pip‑Boy UI Kit & Design Philosophy — Static Rooster (v1.0)
**Date:** 2025-08-29 • **Maintainers:** Static Rooster (Parcel EH1003006 & Canby)  
**Scope:** One source of truth for look/feel, interaction patterns, diagnostics, and tool contracts across the Pip‑Boy ecosystem.

---

## 1) Principles
- **Unified shell, modular tools.** The hub owns layout and navigation; each tool is an independent page (iframe-capable) that plugs in.
- **Mobile first.** Design for ~360px width, then scale up. Large touch targets, minimal chrome, single primary viewport.
- **Immutable versions.** New builds append a version suffix (e.g., `v3_2_1`), never overwrite; old ones are prunable.
- **Two-site awareness.** Everything must operate for **Parcel (EH1003006)** and **Canby**, with the ability to add sites later.
- **Data pipeline friendly.** Tools emit structured events (captures, status) and expose a JSON health report on demand.
- **Theme continuity.** The Pip‑Boy vibe stays consistent via shared tokens.

---

## 2) Theme Tokens (drop-in CSS)
```css
:root{{
  --bg:#0b0c06;         /* base background */
  --grid:#1a2b1a;       /* lines/borders */
  --text:#b4ffb4;       /* body text */
  --glow:#39ff14;       /* primary highlight */
  --accent:#9ae89a;     /* secondary accent */
  --warn:#ffd166;       /* caution */
  --danger:#ff6b6b;     /* error */
  --rooster:#ff504a;    /* brand red */

  /* Typography & spacing (use clamp for responsive sizing) */
  --fs-title: clamp(15px, 1.9vw, 18px);
  --fs-small: clamp(10px, 1.7vw, 13px);
  --fs-chip:  clamp(11px, 2vw, 15px);
  --fs-tile:  clamp(13px, 2.1vw, 16px);
  --pad-tiles: clamp(8px, 1.6vw, 12px);
}}
html,body{{background:var(--bg);color:var(--text);font-family:ui-monospace,Consolas,monospace}}
/* Utility */
.pip-chip{{border:1px solid var(--grid);background:#0f140f;color:var(--text);padding:6px 10px;border-radius:999px;font-size:var(--fs-small)}}
.pip-tile{{border:1px solid var(--grid);border-radius:12px;background:#0f130f;padding:var(--pad-tiles)}}
.pip-title{{color:var(--glow);font-size:var(--fs-title);margin:0}}
.pip-danger{{color:var(--danger)}}
.pip-warn{{color:var(--warn)}}
```

**Rule:** Tools must **not** redefine the variables above; extend with local classes if needed.

---

## 3) Layout Model (shell → tools)
- **Header (single line):** `Pip‑Boy • Static Rooster • Day Date • vX.Y.Z` (never wraps).  
  Live clock appears as a chip **inside the main viewer** (bottom-left).
- **Site Pill:** Top-left over the main viewer; shows active site + LED (green=ok, red=err).
- **Viewer Controls (top-right over viewer):**
  - **View** chip cycles **Min → Max → Fullscreen**.
- **Context Overlay:** Top-center over viewer: `Site • Tool Name`.
- **Tools Section:** Collapsible list of tiles with `name`, `badge`, `href`, and “Open” (new tab).  
- **Diagnostics Section:** Present on every shell and should exist for tools.

**Fullscreen:** In FS, header/sitebar/tools are hidden; viewer occupies `100svh`. The View chip remains to exit.

---

## 4) Interaction Patterns
- **View States:**  
  - **Min**: Viewer shares space with lists.  
  - **Max**: Viewer prioritized; header stays.  
  - **FS**: Viewer only; immersive capture/explore.
- **Gestures:** Horizontal swipe across viewer → previous/next tool.
- **Site switching:** Primary controls live in the hub (no duplicate site toggles inside tools).

---

## 5) Tool Contract (JS)
Each tool should:
1. Read the active site:
```js
const activeSite = localStorage.getItem('dh_active_site') || 'parcel'; // 'parcel' | 'canby'
```
2. Notify the shell it’s alive:
```js
window.parent?.postMessage({{type:'tool:ready', tool: 'my_tool_key', version:'v1.2.3'}}, '*');
```
3. Report status & errors:
```js
window.parent?.postMessage({{type:'tool:status', level:'ok', detail:'loaded-layers'}}, '*');
window.parent?.postMessage({{type:'tool:error', code:'E_LAYER', detail:'raster failed'}}, '*');
```
4. Emit captures (GPS/photo/sensor):
```js
window.parent?.postMessage({{
  type:'capture',
  schema:'eh1003006.capture.v1',
  site: activeSite,
  tool:'my_tool_key',
  ts: new Date().toISOString(),
  payload:{{}} /* e.g., geojson, photo path, readings */
}}, '*');
```

**Health report (downloadable JSON):**
```json
{{
  "schema": "eh1003006.tool.health.v1",
  "generatedAt": "2025-08-29T19:10:00Z",
  "tool": {{"name": "My Tool", "version": "v1.2.3"}},
  "environment": {{"ua": "…" }},
  "status": "ok",
  "checks": [{{"name":"raster","ok":true}}, {{"name":"sensors","ok":false,"note":"no-permission"}}]
}}
```

---

## 6) DecisionHubConfig (truth source)
Example:
```json
{{
  "version": "3.2.1",
  "sites": {{
    "parcel": {{"coords":[46.0201,-122.5488]}},
    "canby":  {{"address":"1736 N Locust St, Canby, OR"}}
  }},
  "defaultViewerBySite": {{"parcel":"planner_527","canby":"planner_528"}},
  "tools":[
    {{"key":"planner_527","name":"Online Planner","href":"eh1003006_online_planner_v5_2_7.html","badge":"v5.2.7","enabled":true}},
    {{"key":"planner_528","name":"Online Planner (Newer)","href":"eh1003006_online_planner_v5_2_8 (4).html","badge":"v5.2.8","enabled":true}},
    {{"key":"intake_529","name":"Intake","href":"online_planner_v5_2_9_intake.html","badge":"v5.2.9","enabled":true}}
  ]
}}
```
**Convention:** Filenames **must include version** (e.g., `EH1003006_Planner_v5_2_8.html`). This supports your “label new map tools with version numbers” rule for safe pruning.

---

## 7) Diagnostics (QuickCheck & Reports)
All tools should expose a minimal diagnostics block:
- **QuickCheck button** prints environment, secure-context state, and filename warnings (e.g., parentheses in filenames).
- **Download Bug Report** (JSON) with schema above.
- **Export/Load Config** for the hub.

Hub-side QuickCheck (example logic):
```js
const secure = window.isSecureContext === true;
const proto = location.protocol.replace(':','');
const filenameWarnings = DecisionHubConfig.tools.map(t=>t.href).filter(h=>/[()]/.test(h));
console.log({{secure, http: (proto==='http'||proto==='https'), filenameWarnings}});
```

---

## 8) Accessibility & Mobile
- **Touch targets ≥ 44px**, spacing via `--pad-tiles`.
- **No wrap** in the header; use ellipsis if constrained.
- Respect **prefers-reduced-motion**; keep fancy transitions optional.
- Icons/LEDs should have **text equivalents** (e.g., `title` attributes).

---

## 9) Data & Capture (baseline)
- **Sites:** `parcel` (EH1003006), `canby` (“1736 N Locust St, Canby, OR”).
- **Static layers:** LiDAR (DTM/CHM/slope/aspect), satellite basemaps, GPS traces.
- **Sensors:** GPS, accelerometer, Wi‑Fi survey, photo/video, environment readings (when permitted).
- **Output:** GeoJSON/JSON + media URLs, batched per-session; files named with UTC timestamps and site ID.

**Example capture envelope:**
```json
{{
  "schema":"eh1003006.capture.v1",
  "site":"parcel",
  "session":"2025-08-29T19-22-18Z_parcel",
  "events":[
    {{"t":"2025-08-29T19:22:21Z","type":"gps","lat":46.02010,"lon":-122.54880,"acc":3.1}},
    {{"t":"2025-08-29T19:22:35Z","type":"photo","uri":"photos/parcel/2025-08-29T19-22-35Z.jpg"}}
  ]
}}
```

---

## 10) Filenaming & Versioning
- **Prefix by site** when appropriate: `parcel_*` or `canby_*`.
- **Tool name + version**: `ToolName_vX_Y_Z.ext`.
- **Avoid spaces/parentheses** in filenames to prevent iframe/security issues.

---

## 11) PWA/Native Transition (roadmap)
- **PWA:** add `manifest.webmanifest` + service worker for installability, offline cache of hub + core tools.
- **Native shell:** use Capacitor to access background sensors, OBS streaming hooks, and local FS while keeping the same UI.

**Manifest sketch:**
```json
{{
  "name":"Static Rooster Pip‑Boy",
  "short_name":"Pip‑Boy",
  "display":"standalone",
  "start_url":"./EH1003006_DecisionHub_index_v3_2_1.html",
  "icons":[{{"src":"icons/rooster-192.png","sizes":"192x192","type":"image/png"}}],
  "theme_color":"#0b0c06","background_color":"#0b0c06"
}}
```

---

## 12) Implementation Checklist
- [ ] Tool adopts theme tokens; uses `pip-chip`, `pip-tile` helpers.
- [ ] Reads `dh_active_site`; adapts to site defaults.
- [ ] Emits `tool:ready`, `tool:status`, `tool:error`, `capture` events.
- [ ] Provides QuickCheck + Bug Report JSON.
- [ ] Uses versioned filename (`_vX_Y_Z`).
- [ ] Mobile tested at 360×640, 412×915, 768×1024.
- [ ] No header wrap; tiles readable; viewer FS works.

---

## 13) Contract Notes
- The shell controls view states and site switching; tools **must not** replicate those controls.
- Tools are iframe-friendly and avoid breaking out of their container.
- Heavy processing (e.g., OBS, model eval) is offloaded to the Pi/edge server; tools stream events, not massive payloads.

---

**That’s it.** Keep this next to your hub base (v3.2.1) and treat it as the style/API authority for future tools.
