# Obvious-Use-Cases Lens v0.1

For every feature, assert the *boring truths*:

- **Passive ingestion needed?** If this produces artifacts, how do they reach the steward-AI without manual upload?
- **Run-from-anywhere?** Can every script be invoked from any terminal?
- **Idempotent?** Re-running produces same result + receipt, no dupes.
- **Receipt discipline?** Lowercase snake_case filenames with t/z.
- **Visibility?** Action leaves a visible trace (commit, artifact, or heartbeat).

> If any answer is “no,” add a rule or a script—don’t rely on memory.
