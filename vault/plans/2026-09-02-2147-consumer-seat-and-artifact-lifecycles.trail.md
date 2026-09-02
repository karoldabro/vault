---
type: trail
project: vault
plan: 2026-09-02-2147-consumer-seat-and-artifact-lifecycles
tags: [trail, record]
---

# 2026-09-02-2147-consumer-seat-and-artifact-lifecycles — process record

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| The `consumer` critic simulates the handoff | it reviews the plan against a four-question checklist | a checklist approves a handoff that reads complete and is not — the exact failure being fixed |
| Claim words are checked by the critic, not the linter | a regex over `wired`, `complete`, `covered`, `integrated` | `lib/doc-lint-patterns.tsv` states precision is the product; those words appear in legitimate prose, and a linter that fires on correct work gets switched off |
| PLAN2 keys off a `create` work item, gated to `proposed`/`approved` | fire on any plan with a work-items table | that fired on 2 of 24 existing plans, both already built; re-linting history changes nothing that ships |
| The rule's prose lives in `lib/doc-lint-patterns.tsv` and `templates/plan.md` | a new paragraph in `commands/_shared/document-standard.md` | that file is 119 lines against a 120-line cap its own test enforces; the added clause pushed it to 125 and broke two passing tests |
| The seat is guaranteed and undroppable | a keyword-triggered relevance pick | a panel selected for mechanism by one mind reproduces that mind's blind spot; author-suggested reviewers rate more favourably than independently chosen ones |
| Over cap, raise `team_max_parallel_critics` to 4 | drop the change's own triggered lens | dropping a `security` lens on an auth change to fit a cap is the worse trade; the hard max is 5, so 4 needs no config change |

## Findings & dispositions

### Round 0

Two critics ran on the drafted plan: `consumer` (seated with the new persona, so the seat reviewed
the plan that creates it) and `skeptic`. Both reports arrived after implementation had started, so
several findings were already closed by the shipped code when they landed; those are marked
`already fixed` below. The consumer critic withdrew its own work-item-2 finding after re-reading the
edited `personas/_resolution.md`.

The consumer seat found two blockers the mechanism critic did not, both by simulating rather than
reviewing, and both real: the drafted gate for `check_plan` was self-contradictory, and the `none`
escape had no written shape. It also ran a second dry run against the shipped `templates/plan.md`
and reported that its section comment was insufficient — it had to invent three conventions,
including whether a CLI flag is one artifact or two, and which of two readings of "who asks for it"
applies. That ambiguity is unresolved.

| id | severity | disposition | note |
|---|---|---|---|
| skeptic-1 | MAJOR | applied, modified | the Rollback section gated the check on the section being present and also fired it on the section being absent. Replaced with a single trigger, but not the one proposed: gating on "any work-items row" would fire on all 24 existing plans, so the trigger is a `create` row plus `status: proposed`/`approved`. |
| skeptic-2 | MAJOR | applied | the check-maps-to-rule test never opened `document-standard.md` and left SIZE1, LONG1, DUP1 and INDEX1–3 unmapped. A new test greps `bin/doc-lint.sh` for every emitted code; a registry block in `lib/doc-lint-patterns.tsv` supplies the mapping. |
| skeptic-3 | MAJOR | applied | architect + consumer + skeptic reaches the default cap of 3 on exactly the high-risk changes that also trigger a `security` or `performance` lens. §2 now names what may never be dropped and permits a raise to 4. |
| skeptic-4 | MAJOR | applied | §2.1 (testing group) and §2.2 (business packs) carry their own seat lists and had no consumer entry, so the guarantee did not reach six business packs or test-writing work. Both edited. |
| skeptic-5 | MAJOR | applied | `templates/plan.md` is instantiated only by `/v-team`, so the linter can never see `/v-work` or `/v-do` work. Recorded as an open gap and partly covered by the §3a.6 lite-critic edit. |
| consumer-1 | BLOCKER | applied | the drafted Rollback paragraph gated `check_plan` on the section being present and also fired PLAN2 on its absence — opposite answers on the same file. One gate now: PLAN1 with the section, PLAN2 without it. |
| consumer-2 | BLOCKER | applied | the `none` escape had no written shape, and the obvious table form tripped the blank-cell rule it was meant to escape. The literal passing row now sits in the template's section comment; the blank data row stays blank on purpose, because a shipped `none` row would let a forgetful session pass with a false declaration. |
| consumer-3 | MAJOR | already fixed | `templates/plan.md` carries `type: plan` and is linted as a plan, so `check_plan` exempts templates and a test asserts the template exits 0. |
| consumer-4 | MAJOR | already fixed | the claim that an existing test would catch `check_plan` going missing was false. Two new tests cover it: one asserts the dispatch line, one maps every emitted code to a rule. |
| consumer-5 | MAJOR | already fixed | item 8's stated reason was that `/v-work` carries most plans; it carries none. Corrected in the plan and in the §3a.6 edit. |
| skeptic-6 | MAJOR | applied | PLAN1 tested emptiness only, so four cells of plausible prose passed. A row must now carry at least one path or backticked identifier. |
| skeptic-7 | MAJOR | deferred | widening PLAN2 to any non-empty work-items table fires on all 8 plans still marked `status: proposed`, which switches the linter off. Recorded in the plan's `Open & deferred` with the condition for revisiting. |
| skeptic-8 | MINOR | already fixed | the template exemption and its test. |
| skeptic-9 | MINOR | applied by other means | claim words inside lifecycle cells are caught by the identifier rule: `wired` alone in a cell carries no backticked name. |
| skeptic-10 | MAJOR (advisory) | partly applied | the pre-mortem named the cap, the `/v-work` gap and the emptiness-only check as one failure. Two are closed; the `/v-work` gap stays open because that command writes no plan file. |

Both reports arrived truncated and were re-requested. The consumer critic's held MINOR — that
nothing outside prose would notice if the guaranteed seat stopped being seated — was not collected,
and neither was the remainder of the skeptic's proposed tests.

## Repairs made outside the plan's scope

`lib/doc-lint-patterns.tsv` named rules 2, 4 and 9 for the HIST, PROC and REF groups while
`document-standard.md` numbers those rules 5, 7 and 10. The bats test asserting the mapping had been
failing on it. Renumbered in both files, because the new code registry sits in the same file and
would have contradicted the stale numbers beside it.

## Metrics

| measure | value |
|---|---|
| critics spawned | 2 (`consumer`, `skeptic`) |
| reports returned | 2 of 2, both truncated and re-requested |
| confirmed findings applied | 8, plus 4 already closed by shipped code and 1 deferred |
| rounds | 1 (no re-loop; reports landed after implementation began) |
| files changed | 10 |
| tests added | 11 |

## Open questions the seat raised and this change did not answer

Running against the shipped `templates/plan.md`, the consumer seat filled the table for a
hypothetical plan and reported three conventions the section comment does not state:

- **Granularity.** The comment lists "a file, a field, a marker, a report, a prompt, a row on a
  choice surface". A CLI flag is none of those, so whether a flag and its output format are one row
  or two is the drafter's call.
- **"Who asks for it" has two readings** — the person requesting the work, or the surface that
  obliges the artifact to exist. The seat read it the second way from the phrase "a binding nothing
  asks for"; the first reading yields a different and equally fillable table.
- **"Absent or malformed" mixes two senses** — absent at build time, malformed at run time — and the
  seat used a different sense per row.
