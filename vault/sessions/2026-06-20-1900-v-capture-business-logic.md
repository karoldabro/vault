---
type: session
project: vault
date: 2026-06-20
topic: v-capture business-logic capture for test enablement
files_touched:
  - commands/v-capture.md
  - templates/session.md
  - templates/feature.md
  - tests/unit/capture-templates.bats
  - vault/plans/2026-06-20-1900-v-capture-business-logic.md
decisions: []
tags: [session, v-capture, test-enablement, behaviors, templates]
---

# v-capture business-logic capture for test enablement

## Goal
Make `/v-capture` record modest business-logic / behavioral context in sessions + feature dossiers, so captured docs become source material for business/feature/integration/UI tests instead of only process notes.

## Did
- Ran `/v-team` (panel-critique lifecycle). Persona resolution found no app pack for this framework repo → degraded to v-work-with-a-panel; selected 3 decorrelated critics: Architect/Structure, Quality/anti-bloat, Test-enablement.
- PROPOSE loop (1 round): drafted plan v0, ran the 3 critics in parallel (read-only, tool-grounded). All returned APPROVE_WITH_NITS. Synthesized + applied; converged clean. Plan: [[../plans/2026-06-20-1900-v-capture-business-logic]].
- EXECUTE: added a `## Behaviors & rules` section to `templates/session.md` (after `## Learned`) and `templates/feature.md` (after `## Contracts`); wired prompts into `commands/v-capture.md` Step 3 (session fill list), Step 5b (feature-gate UPDATE trigger + populate instruction), Step 4b (one-line escalation pointer: recurring behaviors → indications).
- Added `tests/unit/capture-templates.bats` (3 tests) guarding the two template headers + the v-capture wiring against drift.
- Diff-review loop (1 round): Architect CLEAN, Quality APPROVE, Test-enablement verified-by-diff. Full unit suite **102 ok / 0 fail** (was 99). Committed `48494de`.

## Learned
- This framework repo has **no persona pack** (no composer/nuxt/pubspec marker), so `/v-team` correctly degrades to a generic panel per `personas/_resolution.md` §1.4 — the lifecycle still runs, just without stack-specific critics.
- The pre-existing templates were **process-/implementation-oriented** (session: Goal/Did/Learned/Next; feature: Scope/Contracts/Coupling/Gotchas). None captured *what the system should do* in an assertable form — that was the real gap for test enablement.
- Behavior content has a **natural home split**: durable rules belong in the feature dossier (reusable across tests), point-in-time deltas in the session. Putting durable rules only in sessions would scatter them.
- The Docker bats harness mounts the repo read-only at `/code` = `VAULT_ROOT`; a structural test that greps `templates/*.md` is safe and cannot enforce empty sections in *captured* docs (only template files), which is why it doesn't reintroduce ceremony.
- A transient platform classifier outage blocked re-spawning one review agent; verified its checklist directly from the diff via read-only Read (classifier-free) rather than skip the lens.

## Behaviors & rules
- A captured `## Behaviors & rules` bullet is written test-shaped: `precondition → expected outcome [; edge: when X then Y]`. Edge: when the bullet is only descriptive discovery, it belongs in `Learned`, not here.
- The section is omitted entirely when a session carries no domain rules (pure infra/refactor/config); expected outcome: no empty heading is written. Edge: a refactor that *changes a behavior contract* is not "pure refactor" → the section is written.
- Only rules the session established or validated are captured — never aspirational "should build" items (✓ `idempotency key = sha256(file:rule:code)`; ✗ `we should add rate limiting`).
- Each rule appears in exactly one feature section: `Behaviors & rules` for the invariant, cross-linked from `Gotchas` if it is also a trap — never duplicated verbatim.
- The feature-gate UPDATE trigger fires when contracts, **behaviors/rules**, gotchas, or coupling change; a session that establishes a domain rule on an existing feature resolves to UPDATE, not SKIP.

## Next
- Deferred (recorded in plan): cross-feature behavior index, test↔behavior cross-linking, behavior-coverage lint — real test-enablement value but beyond a modest capture-content change.
- Deferred test backlog t2/t3 (skip-hatch honored; session→feature flow) need an LLM-command dry-run, not bats — left as manual-validation items.
- Follow-up candidate: no `features/v-capture.md` dossier exists; capture gate resolved SKIP (out of this session's scope). Worth creating one to dogfood the new feature section.
- Merge `feat/v-capture-business-logic` to main when ready.

## Refs
- [[../plans/2026-06-20-1900-v-capture-business-logic]]
- [[../features/v-cr]]
- [[2026-06-19-1605-v-cr-panel-spawn-coverage-brevity]]
- [[cr-panel-spawn-and-visibility]]
