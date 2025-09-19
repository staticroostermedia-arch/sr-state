# SR Beacon + Agent Kit (v0.1)

**What you get**
- `bin/sr_emit_state_beacon_v0_1.sh`: emits `public/state/state_beacon_v0_1.json`
- `agent/agent.py`: polls `~/static-rooster/proposals/`, verifies signed bundles (HMAC), enforces policy, executes sandboxed commands, writes receipts, bumps beacon
- `docs/schemas/`: JSON Schemas for beacon + action bundle
- `bin/sr_sign_bundle.py`, `bin/sr_verify_bundle.py`: signing helpers

**Deps**
- bash + `jq` + `sha256sum`
- Python 3.9+ with `jsonschema` + `pyyaml`

**Quick start**
```bash
export SR_ROOT="$HOME/static-rooster"
mkdir -p "$SR_ROOT"/{receipts,public/state,config,docs/identity,proposals,secrets}
python3 -m pip install --user jsonschema pyyaml
"/mnt/data/sr_beacon_agent_kit_v0_1/bin/sr_emit_state_beacon_v0_1.sh"
python3 "/mnt/data/sr_beacon_agent_kit_v0_1/agent/agent.py"
```

**Create & sign a proposal**
```bash
cat > /tmp/proposal.json <<'JSON'
{
  "schema":"sr.action_bundle.v0_1",
  "id":"action_$(date -u +%Y%m%dT%H%M%SZ)_demo",
  "issued_at_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "intent":"validate_config_then_backup",
  "based_on":{"beacon_seq":1},
  "commands":[
    {"type":"validate_json_schema","path":"config/decisionhub_config.json","schema":"docs/schemas/DecisionHubConfig_Schema_v0_0.json"}
  ],
  "outputs_expected":["receipts/sr_done_receipt_apply_*.json"]
}
JSON
[ -f "$SR_ROOT/secrets/hmac.key" ] || (mkdir -p "$SR_ROOT/secrets" && head -c 32 /dev/urandom > "$SR_ROOT/secrets/hmac.key")
python3 "/mnt/data/sr_beacon_agent_kit_v0_1/bin/sr_sign_bundle.py" "$SR_ROOT/secrets/hmac.key" /tmp/proposal.json > "$SR_ROOT/proposals/$(date -u +%Y%m%dT%H%M%SZ).json"
```

**Receipts** land in `$SR_ROOT/receipts/`. Re-emit beacon:
```bash
"/mnt/data/sr_beacon_agent_kit_v0_1/bin/sr_emit_state_beacon_v0_1.sh"
```
