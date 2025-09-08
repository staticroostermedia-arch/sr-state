# AI Bridge API v0.1 (draft)

## Messages
- plan.submit {id, window, goals[], inputs[]}
- task.receipt {id, step_name, started_at, ended_at, status, inputs[], outputs[], notes}
- artifact.push {path, sha256, size, bytes?}
- artifact.ref {path, sha256, size, note}
- dossier.pull {since_sha?}

## Contracts (JSON Schema-ish)
- sr.done_receipt.v0_1: {id, step_name, started_at, ended_at, status, inputs[], outputs[], notes}
- sr.manifest.v0_1: {files: [{path, sha256, size}]}
- sr.chain.v0_1: {prev:{path, sha256, size}, append_only}
