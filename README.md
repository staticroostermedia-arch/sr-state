# Static Rooster — Beta Payload v1.0

This archive contains the Pip-Boy DecisionHub and tool HTML files plus configs and helper scripts.

## Quick start
```bash
# unzip at the root of your repo clone
unzip StaticRooster_Beta_Payload_v1_0.zip -d .

# build and serve locally
bash scripts/build.sh
bash scripts/serve.sh 8000  # then open http://localhost:8000
```

## Commit to your repo
```bash
git add apps docs config scripts dist/index.html
git commit -m "Add beta payload (hub + tools + configs)"
git push
```

## Files
- apps/: EH1003006_DecisionHub_index_*.html and tool HTMLs
- config/: DecisionHubConfig_Schema_v1_0.json, Feature_Contract
- docs/: UI Kit and PDFs
- scripts/: build.sh, serve.sh, serve.ps1
- static-rooster.service.example: optional systemd user unit
