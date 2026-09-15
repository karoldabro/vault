---
type: plan
project: vault
slug: v-capture-business-logic
status: executed   # proposed | approved | executed | superseded
process_record: 2026-06-20-1900-v-capture-business-logic.trail.md
tags: [plan, team, v-capture, test-enablement]
---

# v-capture-business-logic — team plan

## Task
Extend `/v-capture` so captured `sessions/` and `features/` docs carry **modest** business-logic /
behavioral context — domain rules, expected outcomes, edge cases in test-shaped form — so downstream
business / feature / integration / UI test authoring has source material. Keywords: v-capture, sessions,
features, business-logic, test-enablement, behaviors.

## Plan
Dependency-ordered. All edits are doc/contract + one bats test. No schema, frontmatter, step, or index churn.

1. **`templates/session.md`** · ADD section · Edit · place **after `## Learned`**, before `## Next`.
   Heading `## Behaviors & rules`. Comment: "Prescriptive domain rules / expected outcomes / edge cases
   this session established or relied on, phrased so a test could assert them. Suggested shape:
   `precondition → expected outcome [; edge: when X then Y]`. Distinct from Learned (descriptive
   discovery). **Omit entirely** if the session carried no domain rules (pure infra/refactor/config)."

2. **`templates/feature.md`** · ADD section · Edit · place **after `## Contracts`**, before `## Coupling`.
   Heading `## Behaviors & rules`. Comment: "Durable domain rules / invariants / acceptance criteria the
   feature must satisfy — what a feature/integration/UI test asserts. Distinct from Contracts (interface
   *shape*) and Gotchas (traps). List each rule once; if it is also a trap, keep it here and cross-link
   from Gotchas."

3. **`commands/v-capture.md` Step 3** · Edit · add to the "Fill honestly" list:
   "**Behaviors & rules** — domain rules / expected outcomes / edge cases the work established or
   validated, phrased so a test could assert them (suggested: `precondition → expected [; edge: when X
   then Y]`). Only rules this session *established or validated* — never aspirational 'should build'
   items (✓ 'idempotency key = sha256(file:rule:code)'; ✗ 'we should add rate limiting'). **Omit the
   section entirely** for sessions with no domain rules."

4. **`commands/v-capture.md` Step 5b** · Edit · UPDATE trigger wording → "...changed its **contracts,
   behaviors/rules, gotchas, or coupling**..."; add an instruction line: "populate `## Behaviors & rules`
   with the durable invariants/acceptance criteria the session established (~3–7 bullets, test-shaped);
   keep each rule in one section — Behaviors, not duplicated in Gotchas."

5. **`commands/v-capture.md` Step 4b** · Edit (one line) · note that rule-shaped Behaviors bullets that
   recur across features are natural indication candidates (the existing always/never/rule: scan already
   catches them) — light escalation pointer, no new machinery.

6. **`tests/unit/capture-templates.bats`** · ADD · assert `templates/session.md` and
   `templates/feature.md` each contain the literal `## Behaviors & rules`. Guards against silent drift
   or rename (CLAUDE.md clean-rename rule).

## Test plan
- **Structural (bats, implementable now):** `tests/unit/capture-templates.bats` — both templates contain
  `## Behaviors & rules`. Runs in the Docker bats harness (per CLAUDE.md dockerized-tests rule).
- **Behavioral (v-capture run shape):** the "refactor-only session omits the section / domain session
  includes it" and "session→feature flow, no Gotchas duplication" checks exercise the LLM command itself,
  which the bats suite cannot execute — recorded in the backlog as **deferred** with that reason, not
  silently dropped.

## Proposed test backlog

| id | kind | target | intent | priority | disposition |
|----|------|--------|--------|----------|-------------|
| t1 | structural | both templates contain `## Behaviors & rules` | guard header drift/rename | should | **implement** (EXECUTE) |
| t2 | feature | v-capture: refactor-only omits section; domain session includes it | verify skip-hatch + prompt honored | should | **defer** — needs LLM-command run, not bats-testable |
| t3 | integration | session behavior → feature dossier, no Gotchas duplication | verify boundary + provenance | nice | **defer** — same reason as t2 |

## Open trade-offs / deferrals
- **Test-shape rigor:** the prompt suggests one shape and gives one example. It imposes no mandatory
  given/when/then format; applying a rigid schema would violate the user's "do not exaggerate"
  constraint and bloat every capture.
- **Feature section placement:** `## Behaviors & rules` sits after `## Contracts`, which pairs the rules
  with the interface shape. Boundary wording handles the Gotchas duplication risk in either order.
- **Deferred out of scope:** cross-feature behavior index, test↔behavior cross-linking, and
  behavior-coverage lint. Each has real future value for "test-enablement" and each exceeds a modest
  capture-content change.

## Refs
- [[../features/v-cr]]
- [[../sessions/2026-06-19-1605-v-cr-panel-spawn-coverage-brevity]]
- Process record: `vault/plans/2026-06-20-1900-v-capture-business-logic.trail.md` — findings, dispositions, rejected options.
