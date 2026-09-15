---
type: trail
project: vault
plan: 2026-07-03-1230-v-pm-cross-project-planning
personas: [fallback-shared]
rounds: 1
convergence: clean
tags: [trail, record]
---

# 2026-07-03-1230-v-pm-cross-project-planning — process record

Contract document: `vault/plans/2026-07-03-1230-v-pm-cross-project-planning.md`.
Design rationale and research trail lived in the session scratchpad at `scratchpad/v-pm-design.md`,
which is not committed. Everything it decided that still binds is in the plan's `## Context`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| `contracts.md` stays separate and structured | Merge it into `generic-plan.md` for fewer concepts | A separate parseable file is what enables the deterministic drift check; concept-load was cut instead by deriving the ledger and deferring the LLM consistency-pass |
| The planning panel runs its own sequential pipeline on the `commands/v-team/steps/03-propose-loop.md` shape | Reuse `commands/_shared/critic-panel.md` | That module is diff-review only: a planning run has no diff and no analyzers to ground on |
| The ledger is derived from thread filenames on read | A written `ledger.md` file in the workspace | Shared append from parallel sessions races |
| Deterministic `contracts.md` diff, LLM only for prose rationale | A broad LLM consistency-pass over the plan and the project | The LLM pass produces false confidence with no checkable output |
| Auto-pickup is pull-only, plus a `v-pm status` sweep | Notify the originating thread when a reply lands | Nothing can push into another session; a reply surfaces only at the next open of the asking project |
| A new `commands/v-team/steps/00-feature-pickup.md` pre-step | Edit `commands/v-team/steps/02-*` and `commands/v-work/steps/02-load-context.md` | The v-team step named did not exist, and the edit leaked feature machinery into `/v-work` |
| The test asserts the installer links `v-pm` after a run | A work item editing `install.sh` by hand | `install.sh` auto-discovers commands via glob, so the hand-edit is dead work |

## Findings & dispositions

### Round 0 — draft

The plan's work items 1–11, derived from the converged design doc, entered the panel for Round 1.

### Round 1 — findings + dispositions

Panel (fallback-shared): architect, skeptic, dx. All three returned REQUEST_CHANGES. Findings were
de-biased and clustered across personas.

| persona | id | severity | grounding | issue (clustered) | disposition |
|---------|----|----------|-----------|-------------------|-------------|
| architect | architect-1 | BLOCKER | confirmed | planning panel can't reuse `_shared/critic-panel.md` (diff-review only) | **applied** — own pipeline on `03-propose-loop` shape (item 3) |
| architect | architect-2 | MAJOR | confirmed | linear pipeline ≠ any existing parallel-panel module | **applied** — new control flow, reuse schema+synthesize only (item 3) |
| skeptic | skeptic-1 | BLOCKER | confirmed | auto-pickup pull-only → orphaned threads; human not out of loop | **applied** — new `v-pm status` sweep (item 6) |
| skeptic | skeptic-2 | MAJOR | confirmed | `→pm` threads only drain on manual reconcile | **applied** — status sweep covers `→pm` + reconcile auto-prompt (items 5–6) |
| skeptic | skeptic-3 | MAJOR | confirmed | "notify originating thread" is fiction; no latency bound | **applied** — drop "notify", document latency contract + ANSWERED digest (items 7, 9) |
| skeptic | skeptic-4 | MAJOR | confirmed | LLM prose consistency-pass = false-confidence | **applied** — deterministic contracts diff; defer LLM pass (item 7) |
| skeptic | skeptic-5 | MAJOR | confirmed | `ledger.md` shared-append race | **applied** — derive ledger from filenames on read (item 4) |
| skeptic | skeptic-6 | MINOR | advisory | no break-even; single-project = ceremony | **applied** — break-even gate (item 2) |
| architect | architect-3 | MAJOR | confirmed | edits non-existent `v-team/steps/02`; leaks into `/v-work` | **applied** — new `00-feature-pickup.md`, v-work/02 untouched (item 7) |
| architect | architect-4 | MAJOR | confirmed | install.sh is glob-based; hand-edit is dead work | **applied** — dropped edit; test asserts installer links v-pm (item 11) |
| architect | architect-5 | MAJOR | confirmed | `_features/` has no git owner / dangling symlinks | **escalated to user** + gitignore symlinks (plan `## Open & deferred`) |
| architect | architect-6 | MINOR | confirmed | missing templates for the load-bearing artifacts | **applied** — templates/_features incl. project-shard (item 8) |
| dx | dx-1 | MAJOR | confirmed | ~10 new concepts for a solo dev | **partially applied** — derive ledger, defer consistency-pass; kept contracts separate |
| dx | dx-2 | MAJOR | confirmed | no push/notification surface for waiting threads | **applied** — `v-pm status` + SessionStart surfacing (items 6, 9) |
| dx | dx-3 | MAJOR | confirmed | no "when to use v-pm"; no single-project degrade | **applied** — dispatcher line + break-even gate (items 1–2) |
| dx | dx-4 | MAJOR | confirmed | OPEN→proj thread can stall silently forever | **applied** — staleness flag (item 5) |
| dx | dx-5 | MINOR | confirmed | mistyped slug silently misses all threads | **applied** — derive from symlink, warn on mismatch (item 7) |
| dx | dx-6 | NIT | confirmed | landing-page rule already respected | **no change** (compliant) |

## Metrics

| measure | round 1 |
|---|---|
| findings | 18 |
| clusters | 11 |
| confirmed BLOCKER | 2 |
| confirmed MAJOR | 9 |
| MINOR | 3 |
| NIT | 1 |
| advisory | 1 |
| escalated to the user | 1 |
| dispositioned `applied` | all confirmed |

## Convergence

The revised plan went to the approval gate rather than to a Round 2. Every confirmed finding was an
architectural correction that had been applied, not iterative refinement. The one remaining item,
git ownership of `~/vault/_features/`, is a user decision and not a panel call.

## Rejected / deferred

| approach | what killed it |
|---|---|
| A `ledger.md` file inside `~/vault/_features/<feature>/` | Parallel sessions append to it and race; the derived view reads thread filenames instead |
| Reusing `commands/_shared/critic-panel.md` for the planning panel | Diff-review module: no diff and no analyzers exist at planning time |
| Editing `commands/v-team/steps/02-*` and `commands/v-work/steps/02-load-context.md` | The v-team step did not exist; the v-work edit leaked feature machinery into a command that does not use it |
| A work item editing `install.sh` to register `v-pm` | `install.sh` discovers commands by glob |
| "Notify the originating thread" when a reply lands | No push channel exists between sessions |
| A broad LLM consistency-pass over plan and project | Deferred as false confidence; only the deterministic `contracts.md` diff shipped |
