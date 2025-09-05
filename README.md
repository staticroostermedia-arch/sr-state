# Static Rooster — Pip‑Boy EH1003006 Bundle v1.0

This is a single‑file friendly bundle of your Pip‑Boy tools + parcel rasters.

## Contents
- `apps/` — DecisionHub + planners + intake/PDR tools
- `data/` — GeoTIFF rasters for EH1003006
- `docs/` — UI kit, feature contract, and PDFs
- `config/` — Config schema
- `scripts/` — Build, serve, and GitHub init helpers
- `index.html` — Landing page with quick links

## Quick Start (Local)
```bash
cd StaticRooster_PipBoy_EH1003006_v1_0
bash scripts/serve.sh 8000
# in your browser: http://localhost:8000/
# open: http://localhost:8000/apps/EH1003006_DecisionHub_index_v3_2_1.html
```

Windows (PowerShell):
```powershell
cd StaticRooster_PipBoy_EH1003006_v1_0
powershell -ExecutionPolicy Bypass -File scripts\serve.ps1 -Port 8000
# then open http://localhost:8000/
```

> The HTML tools attempt to load rasters from `../data/…`. Serving this folder at its root ensures those paths resolve.

## Build (static copy to `dist/`)
```bash
bash scripts/build.sh
# outputs to dist/
```

## Initialize Git & Push to GitHub
Create an empty repo on GitHub, then:
```bash
bash scripts/init_github.sh git@github.com:YOURUSER/YOURREPO.git
# or https://github.com/YOURUSER/YOURREPO.git (with a credential helper)
```

## Filenames normalized
To avoid 'file stream' and quoting issues, spaces/parentheses were removed:
- (none)

## Notes
- This bundle is versioned (v1.0). Future changes should bump the suffix and keep old builds intact per your Regression Protocol.
