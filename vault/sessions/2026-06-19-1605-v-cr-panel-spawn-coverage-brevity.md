---
type: session
project: vault
date: 2026-06-19
topic: v-cr panel-spawn enforcement, coverage + test-posture visibility, comment brevity
continues: [[2026-06-19-1132-v-cr-code-review-command]]
files_touched:
  - commands/_shared/critic-panel.md
  - commands/v-cr/steps/03-review.md
decisions: []
tags: [session, v-cr, code-review, critic-panel]
---

# v-cr panel-spawn enforcement, coverage + test-posture visibility, comment brevity

## Goal
Resolve four standing doubts about `/v-cr` review quality by hardening the contract: real persona-agent spawn, visible coverage, honest test posture, and short comments.

## Did
- ANALYZE: read [[../../commands/v-cr/steps/03-review|03-review.md]], `02-gather.md`, `commands/v-cr.md`, [[../../commands/_shared/critic-panel|critic-panel.md]], `personas/_resolution.md` to ground each doubt against the actual contract (not assumption).
- Edit A — `critic-panel.md` (c): made the multi-`Agent` spawn **mandatory**; an inlined (un-spawned) panel is now non-conformant. Added a `Spawned:` conformance line to the module Output that must match the selected critics.
- Edit B — `03-review.md` §3.5: summary must carry a **coverage line** (`reviewed N · inline M · N−M silent`) so precision-first silence stops reading as missed files.
- Edit C — `03-review.md` §3.5: summary must carry a **test-posture line** — without `--sandbox`: `Tests: not executed (static review only — re-run with --sandbox)`; with it: the gate verdict. Plus a brevity rule: inline ≤3 lines (one-sentence issue + one-sentence rec, no diff restatement), summary ≤3 advisory bullets.
- Edit D — `03-review.md` Required output: added `Spawned:`, `Coverage:`, `Tests:` lines.
- Committed on branch `fix/v-cr-panel-spawn-coverage-brevity` (efcd7e8).

## Learned
- **Tests are executed only under `--sandbox`** (gate in `sandbox.md` S5). Default path reviews test files *as code* via the testing-critic group but runs nothing — by design (executing attacker PR code is unsafe, ADR-009). The real gap was *invisibility*, not missing execution; fix = surface posture, not auto-run.
- **The panel already receives the full changed-file list** (`02-gather.md` §2.1 + `critic-panel.md` Inputs). Sparse comments are the deliberate ≤10 volume cap + grounding gate, not blindness. Fix = make coverage explicit.
- **Persona spawn was specified but unenforced**: `critic-panel.md` (c) said "multiple Agent calls" but nothing forced it or proved it, so a run could inline the critique and look identical. Same reliance exists in `/v-team`. Fix = mandatory + `Spawned:` proof line.
- `~/.claude/commands/v-cr` and `~/.claude/commands/_shared` are **symlinked dirs into the repo**, so edits are live with no `install.sh` re-run.
- No bats test asserts on the review summary prose, so doc-only edits needed no test changes.

## Next
- Optional (declined this session): raise v-cr default critic cap 3→4 for wider coverage.
- Consider mirroring the `Spawned:` enforcement into `/v-team`'s execute loop, which has the same un-enforced-spawn exposure.
- Merge `fix/v-cr-panel-spawn-coverage-brevity` to main when ready.

## Refs
- [[2026-06-19-1132-v-cr-code-review-command]]
- [[../decisions/ADR-008-v-cr-remote-pr-review]]
- [[../decisions/ADR-009-v-cr-sandboxed-execution]]
- [[../features/v-cr]]
