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
the selected critics. The review summary must surface what the panel did, not just its findings:
**coverage** (`reviewed N · inline M · N−M silent`), **test posture** (tests are executed only under
`--sandbox`; otherwise state "not executed — static review only"), and **brevity** (inline comments
≤3 lines: one-sentence issue + one-sentence recommendation, no diff restatement).

## Rationale
A specified-but-unenforced spawn lets a run inline the critique and look identical to a real panel, so
the decorrelation the panel exists for silently disappears. Precision-first silence (the ≤10 volume cap +
grounding gate) reads as "missed files" unless coverage is stated. Tests not running by default (safe —
executing attacker PR code is opt-in, [[../decisions/ADR-009-v-cr-sandboxed-execution|ADR-009]]) misleads
unless the posture is surfaced. Long comments bury the actionable signal.

## Examples
- Do: `Spawned: [Software Architect → backend-architect, correctness → Explore, security → security-engineer]`,
  then `Coverage: reviewed 12 files · inline on 3 · 9 silent (no confirmed findings)` and
  `Tests: not executed (static review only — re-run with --sandbox to gate on tests)`.
- Don't: present three persona verdicts that were reasoned inline with no `Agent` calls; emit a summary
  with findings but no coverage/test line; post a 15-line inline comment that re-explains the diff.

## Applies-to
`commands/_shared/critic-panel.md`, `commands/v-cr/steps/03-review.md`, and any caller that wraps the
shared panel (`commands/v-team/steps/04-execute-loop.md`).
