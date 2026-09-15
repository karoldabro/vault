---
type: trail
project: vault
plan: business-persona-packs
personas: [fallback-panel (skeptic, quality, conventions-architect)]
rounds: 2
convergence: capped-round-2-fixes-applied-unverified   # cap hit; round-2 fixes applied in v2, no round 3 ran
tags: [trail, record]
---

# business-persona-packs — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`vault/plans/2026-07-10-1620-business-persona-packs.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| `personas/_shared/business/data-evidence.md` kept as ONE lens owning six numeric facets, with an explicit one-cluster waiver | a second shared numeric lens splitting measurement-validity from decision-honesty | a second shared lens worsens seat pressure; the split trigger is recorded instead, to fire on a 7th numeric concern |
| Proposal & Pricing scoped to the deal instance in `personas/sales.md` | sales keeping price-model and margin critique | cross-pack double-vote with business Unit Economics & Pricing; one trigger, one lens |
| "Market Skeptic" renamed **"Demand Signal"** in `personas/startup-eval.md` | keeping the Market Skeptic name | near-collision with the shared skeptic critic id, and a double-vote on TAM-as-demand |
| `personas.use` accepts a LIST, deduped by union | a silent single-pick of the first binding | a single-pick drops a seated pack's binding without telling anyone |
| dev+business pack mixing disallowed in one `personas.use` list | cross-regime precedence rules | YAGNI; a mixed repo runs separate sessions per deliverable type |
| `_shared/business/README.md` keeps a generic default plus `fallback: recompute-only` | a slug-keyed overlay table in the README | the table is a second source of truth beside `_resolution.md` |
| startup-eval kept as a standing pack | folding it into business.md plus `personas.add` | user opt-in; overlap mitigated by the Demand Signal re-scope and written boundaries |

The data-evidence conflict was decided between two critics holding opposite positions: quality's
merge-and-waive position was adopted through skeptic's own fallback clause, and seat math favoured
it. The plan carries the conflict forward as an escalation for the approval gate.

## Findings & dispositions

Round 1 verdicts: 3× REQUEST_CHANGES. 16 findings — 2 BLOCKER (confirmed), 8 MAJOR (confirmed),
7 MINOR, 2 NIT. All confirmed BLOCKER and MAJOR findings were applied in v1. skeptic-6 went to the
approval gate; quality-3/6 were accepted under the marketing.md self-containment convention. The
full round-1 table lives in the git history of the plan file.

Round 2 verdicts: 3× REQUEST_CHANGES, same panel re-verifying v1. All 16 round-1 findings verified
resolved as written. 12 new findings — 1 BLOCKER (confirmed), 5 MAJOR (confirmed), 4 MINOR, 2 NIT.

Diff-review round 1 (EXECUTE §5.3, review posture, on the staged branch). Verdicts: skeptic
REQUEST_CHANGES · quality APPROVE_WITH_NITS · architect APPROVE_WITH_NITS. All 28 design-round
findings verified honored in the real files, and the must-tests confirmed present in
`tests/unit/business-personas.bats`.

| round | finding | sev | disposition |
|---|---------|-----|-------------|
| 1 | skeptic-1 multi-pack seating unsupported | BLOCKER | applied in v1 — `personas.use` list form (item 8) |
| 1 | skeptic-2 cap eviction drops the domain lens | MAJOR | applied in v1 — seat priority order and drop order (item 9) |
| 1 | skeptic-3 SoV-formula ownership split across packs | MAJOR | applied in v1 — GEO cedes to data-evidence (item 4) |
| 1 | skeptic-4 method-adequacy unowned | MAJOR | applied in v1 — data-evidence mandate widened (item 1) |
| 1 | skeptic-5 tool health rows carry no executable check | MAJOR | applied in v1 — `tool-playbook.md` rows (item 12) |
| 1 | skeptic-6 startup-eval overlaps business.md on 2 of 3 lenses | MAJOR | deferred to the approval gate — plan escalation 2 |
| 1 | arch-1 use_shared ids cannot address a group | MAJOR | applied in v1 — `<group>/<id>` form (item 8) |
| 1 | arch-2 business-pack critic selection undefined | BLOCKER | applied in v1 — `_resolution.md` §2.2 (item 9) |
| 1 | arch-3 non-dev packs resolve by the wrong key | MAJOR | applied in v1 — `VAULT.md` `project_type`/`personas.use` only (item 8) |
| 1 | arch-6 marketing.md says "six" after two additions | MINOR | applied in v1 — "eight", lines 13 + 189 (item 7) |
| 1 | quality-1 slug-keyed overlay table is dual truth | MAJOR | applied in v1 — table removed from `_shared/business/README.md` (item 2) |
| 1 | quality-2 Market Skeptic double-votes with skeptic | MAJOR | applied in v1 — re-scoped to Demand Signal (item 6) |
| 1 | quality-3/6 boilerplate repeated across packs | MINOR | accepted per the marketing.md self-containment convention — plan escalation 6 |
| 1 | quality-4 SEO cross-ref is one-way | MINOR | applied in v1 — reciprocal cross-ref to seo.md (item 7) |
| 1 | quality-5 voice findings conditionally rule-sourced | MINOR | applied in v1 — unconditional in `personas/support.md` (item 5) |
| 2 | skeptic-8 §1×§2.2 unsatisfiable under multi-pack | BLOCKER | applied — one-architect seat, family-wide guarantee, N≥2 cap 5, drop order (item 9) |
| 2 | skeptic-9 dedup semantics undefined | MAJOR | applied — union composition (item 8) |
| 2 | skeptic-10 dev+business mixing unspecified | MAJOR | applied — disallowed and documented (item 8) |
| 2 | skeptic-11 data-evidence god-critic | MAJOR | resolved against quality-8 — merged plus waiver plus split trigger (items 1-2); plan escalation 3 |
| 2 | skeptic-12 health rows need real commands | MINOR | applied (item 12) |
| 2 | quality-7 cross-pack pricing double-vote | MAJOR | applied — deal-vs-model boundary, single owner, 1-trigger-1-lens, suppression rule (items 3, 9) |
| 2 | quality-8 data-evidence at god-ceiling | MINOR | applied — waiver plus split trigger (item 2) |
| 2 | quality-9 Demand Evidence name near-collision | NIT | applied — renamed Demand Signal (item 6) |
| 2 | arch-8 cap-4 under-propagated (6 locations) | MAJOR | applied (item 10) |
| 2 | arch-9 personas.use list undocumented in template | MAJOR | applied (item 11) |
| 2 | arch-10 project_type enum stale | MINOR | applied (item 11) |
| 2 | arch-11 ANALYZE record single-pack | MINOR | applied (item 8) |
| diff | skeptic-13 "primary pack" double-defined; guaranteed lens wrongly bound to primary pack (dry-run self-contradiction — cap-eviction bug resurfacing) | MAJOR conf | applied — single first-entry definition; lens trigger-chosen across ALL seated packs; bats guard added |
| diff | quality-10 four pre-existing marketing lenses missing from §2.2 trigger table | MINOR conf | applied — 4 triggers plus no-match fallthrough sentence plus bats guard |
| diff | quality-11 Paid Media ↔ data-evidence spend-math double-vote reachable under [sales, marketing] co-seating | MINOR conf | applied — conditional cede in Paid Media, suppression-list entry, bats guard |
| diff | arch-12 knob-comment ordering diverged template vs repo VAULT.md | NIT conf | applied — repo reordered to match template |
| diff | arch-13 "primary" ambiguity (same as skeptic-13) | MINOR adv | applied via the skeptic-13 fix; first-entry kept, relevance gloss deleted |
| diff | skeptic-14 this plan's item 9 carried the pre-fix wording | NIT | applied — item 9 synced |

Also verified by the architect: the `test-hooks-tools-rename.bats:29` wording fix aligns the test to
the doc's longstanding phrasing, a pre-existing failure on main, and the direction is correct.

Diff-review round 2 was a scoped verification. skeptic verdict: APPROVE. skeptic-13 closed, with
both contradictions removed and the dry-run now provable from the text. The quality-10/11,
fallthrough and suppression edits were checked and raised no new confirmed BLOCKER or MAJOR.

## Metrics

| round | findings | confirmed / advisory | overlap | convergence |
|---|---|---|---|---|
| 1 | 16 | 13 / 3 | — | — |
| 2 | 12 new | 10 / 2 | the multi-pack fix drew skeptic-8, quality-7 and arch-9/11 from all three critics, clustered into plan items 8-9 | capped-with-fixes-applied-unverified — cap 2, new confirmed blocker in the final round |
| diff | 5 | 4 / 1 | — | clean — no new confirmed BLOCKER or MAJOR in the final round |

## Advisory test hints

| id | hint | outcome |
|---|---|---|
| skeptic-t1 | cross-pack deference grep guard | superseded by multi-pack §1; folded into t2 |
| skeptic-t4 | multi-pack selection dry-run | manual at EXECUTE self-review — LLM-side logic, not bats-able; carried as backlog row s4 |
| skeptic-t5 | `_resolution.md` family wiring assertions | folded into t2 |
| skeptic-t6 | method-adequacy single-owner plus waiver note | carried as backlog row s6 |
| arch-t4 | `templates/VAULT.md` list form plus extended enum | carried as backlog row t4 |
| arch-t5 | cap-4 stated in `03-propose-loop.md` | carried as backlog row t5 |

## Rejected / deferred

The slug-keyed overlay table in `personas/_shared/business/README.md` was proposed and dropped; the
generic default plus `fallback: recompute-only` replaced it.

A second shared numeric lens beside data-evidence was proposed and dropped. The split trigger stands
in its place: a 7th numeric concern splits the group into measurement-validity and decision-honesty.

Backlog row a6 (knob-block ordering parity guard in the `VAULT.md` files) was skipped as cosmetic.
The ordering was made identical instead, and the existing section-parity guard already covers it.

An installer change was considered and is not needed. The generative test fan-out was skipped for
this docs-only diff under the §f2 gate, and the proposed-test backlog was populated from the panel's
PROPOSED_TESTS instead.
