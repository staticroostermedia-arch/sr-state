# Static Rooster — Canon v0.1
- Cadence: drop every 120 minutes (additive, not subtractive).
- Ledger: append-only chain; each dossier references the prior SHA-256.
- Artifacts: lower_snake_case with version suffix; large assets referenced by path+sha256+size.
- Truth: dossier.json + manifest.json + receipts/* + checkpoint/* define state.
- Gates: filename lint, canon-diff, checkpoint; failure triggers Penitential Rite.
