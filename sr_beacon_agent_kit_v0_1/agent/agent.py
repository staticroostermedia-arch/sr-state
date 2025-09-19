#!/usr/bin/env python3
import os, sys, time, json, hmac, hashlib, base64, shutil, subprocess
from pathlib import Path

ROOT = Path(os.environ.get("SR_ROOT", str(Path.home() / "static-rooster")))
PROPOSALS_SRC = os.environ.get("SR_PROPOSALS_SOURCE", str(ROOT / "proposals"))
HMAC_KEY_PATH = os.environ.get("SR_HMAC_SECRET_PATH", str(ROOT / "secrets" / "hmac.key"))
POLICY_PATH = os.environ.get("SR_POLICY_PATH", str(ROOT / "agent" / "policy.yaml"))
BEACON_EMITTER = os.environ.get("SR_BEACON_EMITTER", str(ROOT / "bin" / "sr_emit_state_beacon_v0_1.sh"))
RECEIPTS = ROOT / "receipts"
PROCESSED = ROOT / "proposals_processed"
POLL_SECONDS = int(os.environ.get("SR_POLL_SECONDS", "10"))

import yaml, jsonschema

ACTION_SCHEMA_PATH = ROOT / "docs/schemas/sr_action_bundle_v0_1.json"
with open(ACTION_SCHEMA_PATH) as f:
    ACTION_SCHEMA = json.load(f)

def hmac_verify(payload_bytes: bytes, signature: str, key: bytes) -> bool:
    if not signature.startswith("hmac-sha256:"):
        return False
    sig_b64 = signature.split(":",1)[1]
    expected = hmac.new(key, payload_bytes, hashlib.sha256).digest()
    try:
        provided = base64.b64decode(sig_b64)
    except Exception:
        return False
    return hmac.compare_digest(expected, provided)

def canonicalize(bundle: dict) -> bytes:
    b2 = dict(bundle); b2.pop("signature", None)
    return json.dumps(b2, sort_keys=True, separators=(",",":")).encode("utf-8")

def load_policy():
    with open(POLICY_PATH) as f:
        return yaml.safe_load(f)

def write_receipt(kind:str, action_id:str, status:str, meta:dict):
    RECEIPTS.mkdir(parents=True, exist_ok=True)
    ts = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    rid = f"sr_done_receipt_{kind}_{ts}"
    payload = {
        "schema": f"sr.done_receipt.{kind}.v0_1",
        "id": rid,
        "action_id": action_id,
        "status": status,
        "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "meta": meta
    }
    path = RECEIPTS / f"{rid}.json"
    with open(path, "w") as f:
        json.dump(payload, f, indent=2)
    return path

def validate_json(path: Path, schema_path: Path):
    with open(path) as f:
        data = json.load(f)
    with open(schema_path) as f:
        schema = json.load(f)
    jsonschema.validate(instance=data, schema=schema)
    return True

def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as f: 
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def ensure_parent(p: Path):
    p.parent.mkdir(parents=True, exist_ok=True)

def safe_move(src: Path, dst: Path):
    ensure_parent(dst); shutil.move(str(src), str(dst))

def run_cmd(cmd: str, timeout: int = 60):
    return subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, text=True)

def process_bundle(bundle: dict, key: bytes, policy: dict):
    canonical = canonicalize(bundle)
    if not hmac_verify(canonical, bundle.get("signature",""), key):
        raise RuntimeError("signature verification failed")
    jsonschema.validate(instance=bundle, schema=ACTION_SCHEMA)
    approvals = policy.get("approval", {}); whitelist = policy.get("whitelist", {})
    action_id = bundle.get("id","unknown")
    logs = []
    for cmd in bundle.get("commands", []):
        ctype = cmd["type"]
        required = approvals.get(ctype, "require_approval")
        if required not in ("auto", "auto_if_expected_sha_matches"):
            raise RuntimeError(f"command {ctype} requires approval")
        if ctype == "validate_json_schema":
            path = ROOT / cmd["path"]; schema = ROOT / cmd["schema"]
            validate_json(path, schema); logs.append(f"validated {path} against {schema}")
        elif ctype == "backup":
            path = ROOT / cmd["path"]; dest = ROOT / cmd["dest"]
            ensure_parent(dest); shutil.copy2(path, dest); logs.append(f"backup {path} -> {dest}")
        elif ctype in ("move","move_noncritical"):
            src = ROOT / cmd["src"]; dst = ROOT / cmd["dst"]; exp = cmd.get("expected_sha256")
            if required == "auto_if_expected_sha_matches" and exp:
                actual = sha256_file(src)
                if actual != exp: raise RuntimeError(f"expected_sha mismatch for {src}, got {actual}")
            safe_move(src, dst); logs.append(f"move {src} -> {dst}")
        elif ctype == "run":
            cmdline = cmd["cmd"]
            allowed = [p.replace("$HOME", str(Path.home())) for p in whitelist.get("run_cmd_prefixes", [])]
            if not any(cmdline.startswith(pref) for pref in allowed):
                raise RuntimeError("run command not in whitelist")
            res = run_cmd(cmdline); logs.append(f"run `{cmdline}` rc={res.returncode}")
            if res.returncode != 0: raise RuntimeError(f"run failed: {cmdline}")
        elif ctype == "restart_service":
            svc = cmd["service"]; res = run_cmd(f"systemctl restart {svc}")
            logs.append(f"restart_service {svc} rc={res.returncode}")
            if res.returncode != 0: raise RuntimeError(f"restart failed: {svc}")
        else:
            raise RuntimeError(f"unknown command type {ctype}")
    rpath = write_receipt("apply", action_id, "success", {"logs": logs})
    if Path(BEACON_EMITTER).exists(): _ = run_cmd(f'"{BEACON_EMITTER}"')
    return rpath

def main():
    key_path = Path(HMAC_KEY_PATH); key_path.parent.mkdir(parents=True, exist_ok=True)
    if not key_path.exists(): key_path.write_bytes(os.urandom(32))
    key = key_path.read_bytes()
    policy = {}
    if Path(POLICY_PATH).exists():
        import yaml as _y; policy = _y.safe_load(open(POLICY_PATH))
    proposals_path = Path(PROPOSALS_SRC)
    PROCESSED.mkdir(parents=True, exist_ok=True); RECEIPTS.mkdir(parents=True, exist_ok=True)
    print(f"[agent] ROOT={ROOT}")
    print(f"[agent] proposals source={proposals_path} (local dir polling)")
    while True:
        try:
            for f in sorted(proposals_path.glob("*.json")):
                try:
                    bundle = json.loads(f.read_text())
                    r = process_bundle(bundle, key, policy)
                    dest = PROCESSED / f.name; shutil.move(str(f), str(dest))
                    print(f"[agent] processed {f.name} -> {r.name}")
                except Exception as e:
                    rid = f"err_{int(time.time())}"
                    write_receipt("apply_failure", bundle.get("id","unknown"), "failure", {"error": str(e)})
                    dest = PROCESSED / (f.name + ".failed"); shutil.move(str(f), str(dest))
                    print(f"[agent] failure {f.name}: {e}")
        except Exception as loop_err:
            write_receipt("observe", "agent_loop", "failure", {"error": str(loop_err)})
        time.sleep(POLL_SECONDS)

if __name__ == "__main__":
    main()
