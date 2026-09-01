---
type: indication
project: vault
slug: cr-panel-spawn-and-visibility
scope: repo
tags: [indication]
---

# cr-panel-spawn-and-visibility

## Rule
The critic panel must **actually spawn one read-only `Agent` per selected persona** — inlining the
personas' reasoning in the main thread is non-conformant. Prove it with a `Spawned:` line that matches
the selected critics, and every critic writes its findings block to a file and reports that path — a
truncated report loses its tail, which is where the receipt sits.

**Coverage is computed from per-file receipts, never inferred from findings.** Each critic returns
`FILES_EXAMINED` rows (`commands/_shared/critic-panel.md` §(d)); `cr_coverage` diffs them against the
changed-file list. The summary states **three buckets** — with findings · examined clean · not
examined. Never two: **silence is not evidence of cleanliness**, and a line that merges the file
nobody opened with the file checked and cleared reports coverage the review has not earned. A `read`
row carries an anchor the caller checks against the diff, and an examined-clean file says what was
checked, so the claim is falsifiable without reopening the file.

The summary must also surface **test posture** (tests are executed only under `--sandbox`; otherwise
state "not executed — static review only") and **brevity** (inline comments ≤3 lines: one-sentence
issue + one-sentence recommendation, no diff restatement).

## Rationale
A specified-but-unenforced spawn lets a run inline the critique and look identical to a real panel, so
the decorrelation the panel exists for silently disappears. Precision-first silence (the ≤10 volume cap +
grounding gate) reads as "missed files" unless coverage is stated. Tests not running by default (safe —
executing attacker PR code is opt-in, [[../decisions/ADR-009-v-cr-sandboxed-execution|ADR-009]]) misleads
unless the posture is surfaced. Long comments bury the actionable signal.

## Examples
- Do: `Spawned: [Software Architect → backend-architect, correctness → Explore, security → security-engineer]`,
  then `Coverage: 12 changed · 3 with findings · 7 examined clean · 2 NOT EXAMINED` naming the two
  paths, and `Tests: not executed (static review only — re-run with --sandbox to gate on tests)`.
- Don't: present three persona verdicts that were reasoned inline with no `Agent` calls; emit a summary
  with findings but no coverage/test line; report a file as clean because no critic mentioned it; post
  a 15-line inline comment that re-explains the diff.

## Applies-to
`commands/_shared/critic-panel.md`, `commands/v-cr/steps/03-review.md` §3.6, `lib/cr-helpers.sh`
(`cr_coverage`), and any caller that wraps the shared panel. The receipt binds every caller;
**`/v-team` is exempt from rendering the coverage line** — `commands/v-team/steps/04-execute-loop.md`
bars panel vocabulary from user-facing output, so it consumes the machine set and prints nothing.
The receipt-and-diff method itself is `commands/_shared/agent-conduct.md` Fan-out; this rule says
where `/v-cr` applies it, not what it is.
