---
type: indication
project: vault
slug: generators-emit-critics-confirm
scope: repo
tags: [indication, v-team, testing]
---

# generators-emit-critics-confirm

## Rule
Test-design **generators** and test **critics** must be decorrelated by lifecycle phase: a generator
grounds in the design plan, binds **no** analyzer, emits `advisory` candidates, and **never seats on the
critique panel** (pre-impl); a critic grounds in written tests + a bound analyzer and owns the **post-impl
VOTE**. All confirmation of a generated dossier happens in EXECUTE, never inside the PROPOSE panel.

## Rationale
Multi-agent panels lose value when two seats correlate — a generator that also votes collapses into its
mirror critic and double-counts. Worse, confirming generated tests *inside* the PROPOSE panel is
temporally impossible: the panel converges before the dossier is written, so the confirmer would vote
before its input exists. Splitting by phase (emit pre-impl / confirm post-impl) makes the generate→confirm
loop both decorrelated and executable, and keeps "only confirmed findings block" intact.

## Examples
- Do: `personas/_shared/testing/design/fault-relation-prospector` emits fault hypotheses + metamorphic
  relations as `advisory` dossier rows; `assertion-auditor` (mutation) and `system-domain-expert` (rule
  existence) confirm them in EXECUTE §5.3.
- Do: every generator file carries both a `NOT → <critic>` (vertical) and a `NOT → <other generator>`
  (horizontal) decorrelation line.
- Don't: a "generate-mode" added to a critic persona, or a generator that runs mutation/coverage and casts
  a blocking vote at plan time.

## Applies-to
`personas/_shared/testing/design/**`, `personas/_shared/testing/system-domain-expert.md`,
`commands/v-team/steps/03-propose-loop.md` (§f2), `commands/v-team/steps/04-execute-loop.md` (§5.3).
