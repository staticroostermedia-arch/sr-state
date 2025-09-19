#!/usr/bin/env python3
import json, hmac, hashlib, base64, sys
from pathlib import Path
def canonical(b):
    b = dict(b); b.pop("signature", None)
    return json.dumps(b, sort_keys=True, separators=(",",":")).encode()
if len(sys.argv) < 3:
    print("Usage: sr_verify_bundle.py <hmac_key_file> <bundle.json>", file=sys.stderr); sys.exit(1)
key = Path(sys.argv[1]).read_bytes()
bundle = json.loads(Path(sys.argv[2]).read_text())
sig = bundle.get("signature","")
if not sig.startswith("hmac-sha256:"): print("invalid sig scheme"); sys.exit(2)
b64 = sig.split(":",1)[1]
payload = canonical(bundle)
if hmac.compare_digest(base64.b64decode(b64), hmac.new(key, payload, hashlib.sha256).digest()):
    print("OK"); sys.exit(0)
print("MISMATCH"); sys.exit(3)
