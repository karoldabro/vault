---
type: plan
project: vault
slug: v-capture-business-logic
status: executed   # proposed | approved | executed | superseded
personas: [generic-panel]
rounds: 1
convergence: clean   # clean | capped-with-open-blockers
tags: [plan, team, v-capture, test-enablement]
---

# v-capture-business-logic — team plan

Written by `/v-team`. Converged implementation plan + critique trail + proposed-test backlog.

## Task
Extend `/v-capture` so captured `sessions/` and `features/` docs carry **modest** business-logic /
behavioral context — domain rules, expected outcomes, edge cases in test-shaped form — so downstream
business / feature / integration / UI test authoring has source material. Keywords: v-capture, sessions,
features, business-logic, test-enablement, behaviors.

## Converged plan
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

6. **bats structural test** · ADD · assert `templates/session.md` and `templates/feature.md` each contain
   the literal `## Behaviors & rules`. Guards against silent drift / rename (CLAUDE.md clean-rename rule).
   Exact file + harness confirmed in EXECUTE (likely `tests/unit/`).

## Test plan
- **Structural (bats, implementable now):** new test in the unit suite — both templates contain
  `## Behaviors & rules`. Runs in the Docker bats harness (per CLAUDE.md dockerized-tests rule).
- **Behavioral (v-capture run shape):** the "refactor-only session omits the section / domain session
  includes it" and "session→feature flow, no Gotchas duplication" checks exercise the LLM command itself,
  which the bats suite cannot execute — recorded in the backlog as **deferred** with that reason, not
  silently dropped.

## Proposed test backlog

| id | persona | kind | target | intent | priority | disposition |
|----|---------|------|--------|--------|----------|-------------|
| t1 | arch+qual+test (merged) | structural | both templates contain `## Behaviors & rules` | guard header drift/rename | should | **implement** (EXECUTE) |
| t2 | arch+qual+test (merged) | feature | v-capture: refactor-only omits section; domain session includes it | verify skip-hatch + prompt honored | should | **defer** — needs LLM-command run, not bats-testable |
| t3 | arch+test (merged) | integration | session behavior → feature dossier, no Gotchas duplication | verify boundary + provenance | nice | **defer** — same reason as t2 |

## Open trade-offs / deferrals
- **Test-shape rigor (test-1, MAJOR·advisory):** resolved as a *light suggestion* + one example, not a
  mandatory given/when/then format — applying a rigid schema would violate the user's "do not exaggerate"
  and quality critic's anti-bloat finding. Trade-off surfaced, not escalated.
- **Feature section placement:** after `## Contracts` (not after `## Gotchas` as arch-2 floated) — pairs
  the rules with the interface shape; the duplication risk is handled by boundary wording regardless of
  order. Minor, recorded.
- **Deferred out of scope (test-2 advisory tail):** cross-feature behavior index, test↔behavior
  cross-linking, and behavior-coverage lint. Real future value for "test-enablement" but beyond a modest
  capture-content change.

## Critique trail

### Round 0 — draft
Three doc edits (session template, feature template, v-capture contract) adding one `## Behaviors & rules`
section + prompt wiring + brevity guard. Anti-bloat by construction: one section per template, reuse the
feature gate's create/update/skip logic, no new step/index/schema.

### Round 1 — findings + dispositions
Panel: 3 generic critics (no app pack resolved → v-work-with-a-panel). All verdicts APPROVE_WITH_NITS.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| Architect | arch-1 | MAJOR | confirmed | session Behaviors after Did splits behavior from Learned | **applied** — moved after Learned + prescriptive/descriptive boundary wording |
| Architect | arch-2 | MINOR | confirmed | feature Behaviors vs Gotchas ambiguity | applied — boundary wording; placement after Contracts (rationale in trade-offs) |
| Architect | arch-3 | MINOR | advisory | shared heading may blur session-vs-feature intent | applied — per-template comment disambiguates; heading kept shared for consistency |
| Architect | arch-4 | NIT | confirmed | UPDATE trigger is a condition, clarify wording | applied — explicit trigger wording in step 4 |
| Architect | arch-5 | NIT | advisory | no drift guard for template sections | applied — structural bats test (t1) |
| Quality | qual-1 | MAJOR | confirmed | skip hatch unenforced → empty-section ceremony | **applied** — prompt actively instructs "omit entirely" |
| Quality | qual-2 | MINOR | confirmed | Behaviors/Gotchas redundancy in features | applied — "list each rule once, cross-link" wording |
| Quality | qual-3 | MINOR | advisory | structural test could enforce empty sections | resolved — test targets template files, not captured docs; safe |
| Quality | qual-4 | NIT | confirmed | "speculative/aspirational" undefined | applied — established-vs-aspirational examples in prompt |
| Test-enablement | test-1 | MAJOR | advisory | "phrased so a test could assert" too abstract | **applied (light)** — suggested shape + example (kept optional per anti-bloat) |
| Test-enablement | test-2 | MAJOR | confirmed | no session-behavior → durable-indication path | applied (light) — step 5; index/lint tail deferred |
| Test-enablement | test-3 | MINOR | confirmed | feature Behaviors vs Gotchas boundary | applied — same wording as qual-2 |
| Test-enablement | test-4 | MINOR | advisory | structural test left floating | applied — concretized as t1 |

_Metrics: new confirmed blockers: 0 · confirmed findings: 8 · advisory: 5 · findings-delta (R0→R1): +13 ·
per-persona overlap: 3 clusters shared across ≥2 personas (placement/boundary, skip-hatch, structural-test)
· verdicts: 3× APPROVE_WITH_NITS · panel tokens: ~3 Explore agents._

**Convergence:** clean at Round 1. All confirmed MAJORs applied; no BLOCKER; no unresolved conflict.
Second round skipped deliberately — low-risk doc change, unanimous nits-only verdicts; per the loop's own
`team_max_rounds:1` guidance a round-2 panel would not yield new confirmed blockers proportionate to cost.

### Review round 1 — diff verification (EXECUTE)
Same 3 personas in review posture against the working-tree diff + new bats test. Unit suite: **102 ok / 0
fail** (was 99 → +3 from `tests/unit/capture-templates.bats`).

| persona | result | notes |
|---------|--------|-------|
| Architect | CLEAN | arch-1 (placement after Learned), arch-4 (UPDATE trigger), arch-5 (structural test) all confirmed applied; Output/Idempotency/Step 6 need no change; no broken/duplicate headings |
| Quality | APPROVE | qual-1 skip-hatch now imperative ("Omit entirely"), qual-4 ✓/✗ examples present; ~66 added lines, no new step/index/frontmatter; bats test targets template files (can't enforce empty captured sections) |
| Test-enablement | verified-by-diff | test-1 shape present in both templates + Step 3; four test kinds named; test-3 boundary wording present; durable(feature)-vs-delta(session) preserved. Agent re-spawn blocked by a transient platform classifier outage; checklist confirmed directly from the diff (read-only) — recorded transparently, not silently skipped |

_Metrics: new confirmed BLOCKER/MAJOR: 0 · review rounds: 1 · tests: 102 ok / 0 fail (3 new) · convergence: clean._

## Refs
- [[../features/v-cr]]
- [[../sessions/2026-06-19-1605-v-cr-panel-spawn-coverage-brevity]]
