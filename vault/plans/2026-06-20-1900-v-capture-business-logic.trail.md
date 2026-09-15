---
type: trail
project: vault
plan: 2026-06-20-1900-v-capture-business-logic
personas: [generic-panel]
rounds: 1
convergence: clean
tags: [trail, record]
---

# 2026-06-20-1900-v-capture-business-logic — process record

Contract document: `vault/plans/2026-06-20-1900-v-capture-business-logic.md`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| `## Behaviors & rules` sits after `## Learned` in `templates/session.md` | Place it after `## Did` | Placing it after `## Did` splits the prescriptive rule from the descriptive discovery it came from |
| `## Behaviors & rules` sits after `## Contracts` in `templates/feature.md` | Place it after `## Gotchas` | Pairing the rules with the interface shape beats pairing them with traps; boundary wording handles the duplication risk in either order |
| The prompt suggests `precondition → expected [; edge: when X then Y]` and one example | Mandate a given/when/then schema | A rigid schema contradicts the user's "do not exaggerate" constraint and bloats every capture |
| One shared heading in both templates, disambiguated by a per-template comment | A different heading in each template | Two headings cost cross-document consistency; the comment already separates session intent from feature intent |
| A structural bats test asserts the literal heading in both templates | Trust the templates to stay in sync | A silent rename breaks capture with no failing test |
| The structural test targets the template files | Assert that captured docs carry no empty section | The test cannot reach captured output, and asserting emptiness there would fight the skip hatch |

## Findings & dispositions

### Round 0 — draft

Three doc edits (session template, feature template, `commands/v-capture.md`) adding one
`## Behaviors & rules` section plus prompt wiring and a brevity guard. Anti-bloat by construction:
one section per template, reuse of the feature gate's create/update/skip logic, no new step, index
or schema.

### Round 1 — findings + dispositions

The `/v-team` panel ran 3 generic critics; no app pack resolved, so it fell back to
v-work-with-a-panel. All verdicts APPROVE_WITH_NITS.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| Architect | arch-1 | MAJOR | confirmed | session Behaviors after Did splits behavior from Learned | **applied** — moved after Learned + prescriptive/descriptive boundary wording |
| Architect | arch-2 | MINOR | confirmed | feature Behaviors vs Gotchas ambiguity | applied — boundary wording; placement after Contracts |
| Architect | arch-3 | MINOR | advisory | shared heading may blur session-vs-feature intent | applied — per-template comment disambiguates; heading kept shared for consistency |
| Architect | arch-4 | NIT | confirmed | UPDATE trigger is a condition, clarify wording | applied — explicit trigger wording in step 4 |
| Architect | arch-5 | NIT | advisory | no drift guard for template sections | applied — structural bats test (t1) |
| Quality | qual-1 | MAJOR | confirmed | skip hatch unenforced → empty-section ceremony | **applied** — prompt actively instructs "omit entirely" |
| Quality | qual-2 | MINOR | confirmed | Behaviors/Gotchas redundancy in features | applied — "list each rule once, cross-link" wording |
| Quality | qual-3 | MINOR | advisory | structural test could enforce empty sections | resolved — test targets template files, not captured docs; safe |
| Quality | qual-4 | NIT | confirmed | "speculative/aspirational" undefined | applied — established-vs-aspirational examples in prompt |
| Test-enablement | test-1 | MAJOR | advisory | "phrased so a test could assert" too abstract | **applied (light)** — suggested shape + example, kept optional per anti-bloat |
| Test-enablement | test-2 | MAJOR | confirmed | no session-behavior → durable-indication path | applied (light) — step 5; index/lint tail deferred |
| Test-enablement | test-3 | MINOR | confirmed | feature Behaviors vs Gotchas boundary | applied — same wording as qual-2 |
| Test-enablement | test-4 | MINOR | advisory | structural test left floating | applied — concretized as t1 |

Round 2 was skipped deliberately. Every confirmed MAJOR was applied, no BLOCKER was raised, and no
conflict stayed open. Under the loop's own `team_max_rounds:1` guidance a second panel would not
yield new confirmed blockers proportionate to its cost.

### Review round 1 — diff verification (EXECUTE)

The same 3 personas reviewed the working-tree diff and the new bats test.

| persona | result | notes |
|---------|--------|-------|
| Architect | CLEAN | arch-1 (placement after Learned), arch-4 (UPDATE trigger) and arch-5 (structural test) confirmed applied; Output, Idempotency and Step 6 need no change; no broken or duplicate headings |
| Quality | APPROVE | qual-1 skip hatch now imperative ("Omit entirely"); qual-4 ✓/✗ examples present; ~66 added lines, no new step, index or frontmatter key; bats test targets template files |
| Test-enablement | verified-by-diff | test-1 shape present in both templates and in Step 3; four test kinds named; test-3 boundary wording present; durable-feature vs delta-session split preserved |

The test-enablement agent could not be re-spawned: a transient platform classifier outage blocked
it. That checklist was confirmed read-only from the diff instead.

## Metrics

| measure | round 1 | review round 1 |
|---|---|---|
| new confirmed blockers | 0 | 0 |
| confirmed findings | 8 | 0 |
| advisory findings | 5 | 0 |
| findings-delta (R0→R1) | +13 | — |
| persona overlap | 3 clusters across ≥2 personas: placement/boundary, skip-hatch, structural-test | — |
| verdicts | 3× APPROVE_WITH_NITS | CLEAN / APPROVE / verified-by-diff |
| panel cost | ~3 Explore agents | 0 spawned |
| unit suite (`tests/unit/`) | — | 102 ok / 0 fail (was 99; +3 from `tests/unit/capture-templates.bats`) |
| convergence | clean | clean |

## Rejected / deferred

Deferred out of the plan's scope: a cross-feature behavior index, test↔behavior cross-linking, and
a behavior-coverage lint. Each has real value for test-enablement and each exceeds a modest change
to what capture writes.

Deferred as not bats-testable: the two behavioral checks `t2` and `t3` in the plan's test backlog.
They exercise the `/v-capture` LLM command itself, which the bats suite cannot run.
