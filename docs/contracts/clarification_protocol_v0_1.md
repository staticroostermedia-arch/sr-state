# Clarification Protocol (v0.1)

**Purpose**  
Prevent assumption drift when steward intent is ambiguous.

**Placement**  
`static-rooster/docs/contracts/clarification_protocol_v0_1.md`

**Rules**

1. **Three Probes Rule** (from Parable of the Standard)
   - If a request cannot be explained in three probes, halt and ask.

2. **No Silent Changes** (Canon Rule 4)
   - Surface differences before applying.
   - Request confirmation when meaning is unclear.

3. **Halt on Ambiguity**
   - If steward uses ambiguous terms (e.g. “auto-build”), clarify:
     - Runner building stubs?
     - Runner building finished tools from spec?
     - Assistant free-running background?

4. **Receipts**
   - Ambiguity + clarification requests are logged in receipts as `sr_done_receipt_clarification_*`.

**Compliance**
- Breaking this protocol risks drift → `foedus fractum`.
