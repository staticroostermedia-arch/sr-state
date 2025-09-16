# Component Catalog (v0.1)

**Purpose**  
Define the reusable UI/logic blocks the generator may assemble into tools. Keeps design coherent.

**Placement**  
`static-rooster/docs/contracts/component_catalog_v0_1.md`

**Components**

- **Header Bar**
  - Site badge + version badge.
  - Optional navigation tabs.

- **QuickCheck Block**
  - Button + JSON output area.
  - Standard schema: `eh1003006.dh.health.v1`.

- **Layers Panel**
  - Checkbox list bound to raster keys.
  - Supports toggling visibility.

- **Plan Editor**
  - Polygon draw + erase tools.
  - Export button (GeoJSON).

- **Data Table**
  - Rows/columns, sortable.
  - CSV export option.

- **Diagnostics Pane**
  - Live status logs.
  - Error/warning messages.

- **Capture Form**
  - Structured fields → capture payload.
  - Posts `capture` event.

**Rules**
- Styling: all use StaticRooster UI Kit tokens.
- Events: all components emit via postMessage envelope.
- Extensions: new components require version bump of this catalog.
