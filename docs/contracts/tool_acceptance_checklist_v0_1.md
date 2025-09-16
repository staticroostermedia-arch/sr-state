# Tool Acceptance Checklist (v0.1)

**Purpose**  
Define the hard gates a generated Pip-Boy tool must pass before it can be registered in DecisionHub.

**Placement**  
`static-rooster/docs/contracts/tool_acceptance_checklist_v0_1.md`

**Checks**

1. **Filename**
   - Must include `_vX_Y_Z` (semantic version suffix).
   - Must not contain spaces, parentheses, or special characters.

2. **Size**
   - Minimum size: 6 KB (prevents 3 KB stubs).
   - Upper bound: none, but must render within 2 seconds on localhost.

3. **DOM Requirements**
   - Title element present.
   - Version badge visible.
   - QuickCheck block present and functional.
   - At least one primary action element (button, tab, form).

4. **Events**
   - `ready` event posts within 2 seconds.
   - `status` event responds to a user action.
   - `capture` event fires on the declared trigger.
   - `error` event can be emitted by design.

5. **Viewport**
   - Must render without overflow at 360×640 (mobile).
   - Must render cleanly at 412×915 (phablet).

6. **Probe**
   - Route must respond HTTP 200 (Probe Contract v0.1).
   - Failing probes trigger Penitential Rite.

**Compliance**
- Any failure blocks registration of the tool.
- Runner writes a receipt `sr_done_receipt_acceptance_fail_*` with reason.
