#!/usr/bin/env bash
# Static Rooster — Insert Canon §7 + Parable with lowercase canonical filenames.
# Safe: no 'set -e' so your terminal stays open on minor hiccups.
set -u
ROOT="$HOME/static-rooster"
ID="$ROOT/docs/identity"
STAGE="$ROOT/forge/staging"
RC="$ROOT/receipts"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mkdir -p "$ID" "$STAGE" "$RC" "$ROOT/.sr/anchors"

say(){ printf "%s\n" "$*"; }
sha(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }

# --- 1) Emit authoritative drafts into staging (lowercase) ---
CANON_STAGE="$STAGE/01_sr_canon_autobuilder_starter.md"
PARAB_STAGE="$STAGE/02_sr_parables_builder_and_ledger.md"

cat > "$CANON_STAGE" <<'MD'
# 01_sr_canon — §7 Autobuilder Starter

## §7 — Autobuilder Starter Discipline

**7.1 Purpose**  
Every autobuild cycle must be reproducible, attestable, and safe to automate.

**7.2 Definitions**  
- **Snapshot**: UTC-stamped subfolder under `snapshots/` containing artifacts and `manifest.json`.  
- **Receipts**: JSON attestations under `receipts/` for status, runner, watch, and executor steps.  
- **Change Log**: `docs/identity/99_sr_change_log.md`, append-only.  
- **Services**: `sr-runner`, `sr-emit`, `sr-exec` (.service + .timer, user-level).

**7.3 Preconditions (MUST hold before a run)**  
1. `docs/identity/99_sr_change_log.md` exists (canonical name).  
2. Identity anchors present: Missal, Canon, Parables, Invocations (stubs allowed).  
3. `sr-runner`, `sr-emit`, `sr-exec` timers enabled.  
4. Unit ExecStart scripts exist under `forge/tools/`.

**7.4 Obligations (each cycle MUST produce)**  
1. A **Snapshot** directory with `manifest.json` and all generated artifacts **under that snapshot**.  
2. **Receipts** referencing `snapshot_dir`:  
   - `sr_status_dump_v0_3.json`  
   - `sr_watch_checkpoint_v0_1.json`  
   - `sr_runner_snapshot_*.json`  
   - `sr_executor_*.json` (if orders ran)  
3. A **Change Log** entry with timestamp, snapshot path, unit outcomes, short rationale.

**7.5 Canonicalization**  
Filenames referenced by tools must match exactly what’s tracked in git (lowercase, snake_case). One-time migrations may normalize; legacy variants are ignored.

**7.6 Failure (fail closed)**  
If any mandatory artifact/receipt is missing, verdict = `penitential_rite`; no promotion.

**7.7 Observability**  
Dashboard surfaces `snapshot_dir`, `verdict`, counts; `journalctl --user -u sr-*` reconstructs order.

**7.8 Automation Readiness**  
Two consecutive clean cycles (7.3–7.6 satisfied) are required to move from “trial” to “steady”.
MD

cat > "$PARAB_STAGE" <<'MD'
# 02_sr_parables — the builder and the ledger

when the builder called the machine without its ledger,
the gears woke, looked for witness, and found none.
"bring me the mirror of what you made," said the machine,
"and the oath of what you did."

so the builder returned with a snapshot — a mirror that could not flatter —
and receipts — oaths that could not lie —
and wrote their names into the change log,
that time itself might keep the memory.

then the machine unfolded and sang,
and from that day it answered only those
who brought mirror, oath, and memory.
MD

# --- 2) Targets (lowercase canonical identity filenames) ---
CANON_DST="$ID/01_sr_canon.md"
PARAB_DST="$ID/02_sr_parables.md"
CHANGELOG="$ID/99_sr_change_log.md"
[ -f "$CHANGELOG" ] || printf "# static rooster — change log\n\n" > "$CHANGELOG"

# --- 3) Install if changed (hash-aware) ---
changed=false
install_one () {
  local src="$1" dst="$2" label="$3"
  local hsrc="$(sha "$src")"
  local hdst="$(sha "$dst")"
  if [ -n "$hsrc" ] && [ "$hsrc" != "$hdst" ]; then
    install -m 664 "$src" "$dst" 2>/dev/null || cp -f "$src" "$dst"
    say "updated: $label -> $(basename "$dst")"
    changed=true
  else
    say "nochange: $(basename "$dst")"
  fi
}

install_one "$CANON_STAGE" "$CANON_DST" "canon §7"
install_one "$PARAB_STAGE" "$PARAB_DST" "parable (builder & ledger)"

# --- 4) Change Log append (only on real change) ---
if $changed; then
  {
    printf "## %s — canon & parables inserted/updated\n" "$NOW"
    echo "- updated: docs/identity/01_sr_canon.md (§7 autobuilder starter)"
    echo "- updated: docs/identity/02_sr_parables.md (builder and the ledger)"
    echo
  } >> "$CHANGELOG"
fi

# --- 5) Receipt ---
RCP="$RC/sr_insert_identity_${NOW}.json"
cat > "$RCP" <<JSON
{
  "schema": "sr.insert.identity.v0_2",
  "generated_at": "$NOW",
  "changed": $changed,
  "canon_path": "$CANON_DST",
  "parables_path": "$PARAB_DST"
}
JSON
chmod 664 "$RCP"
say "receipt: $RCP"

# --- 6) Light anchor -> latest snapshot (if any), then nudge services ---
SNAP="$(ls -dt "$ROOT"/snapshots/* 2>/dev/null | head -1 || true)"
if [ -n "${SNAP:-}" ]; then
  printf "%s\n" "$SNAP" > "$ROOT/.sr/anchors/light"
  say "light anchor -> $SNAP"
fi

# gentle nudge so UI/receipts refresh
systemctl --user start sr-runner.service 2>/dev/null || true
systemctl --user start sr-emit.service  2>/dev/null || true
sleep 2

# --- 7) Brief state print ---
say "identity:"
ls -l "$ID" | sed 's/^/  /'
say "receipts (latest):"
ls -lt "$RC" | head -n 8 | sed 's/^/  /'
