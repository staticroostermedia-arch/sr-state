#!/usr/bin/env python3
import json, hmac, hashlib, base64, sys
from pathlib import Path
def canonical(b):
    b = dict(b); b.pop("signature", None)
    return json.dumps(b, sort_keys=True, separators=(",",":")).encode()
if len(sys.argv) < 3:
    print("Usage: sr_sign_bundle.py <hmac_key_file> <bundle.json>", file=sys.stderr); sys.exit(1)
key = Path(sys.argv[1]).read_bytes()
bundle = json.loads(Path(sys.argv[2]).read_text())
payload = canonical(bundle)
sig = hmac.new(key, payload, hashlib.sha256).digest()
bundle["signature"] = "hmac-sha256:" + base64.b64encode(sig).decode()
print(json.dumps(bundle, indent=2))
