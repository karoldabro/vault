---
type: plan
project: vault
slug: vpm-pm-discipline
repos: [vault]
status: executed
process_record: 2026-09-01-0900-vpm-pm-discipline.trail.md
session:
tags: [plan, v-pm, elicitation, definition-of-done, tracking]
---

# vpm-pm-discipline — plan

Give `/v-pm` the four things a working product manager does and this framework does not: elicit until
the doubts are named, state a size budget instead of a task list, define what "done" means, and make
the plan's progress readable without opening every file. Search keywords: elicitation, definition of
done, appetite, session table, REQ coverage, status rollup.

## Open & deferred

- **Deferred — the question-shaping rules live in two places**:
  `commands/_shared/communication.md` and `v-work/steps/03-propose.md` §3a.0a.
  `tests/unit/research-clarify.bats` pins those exact strings to the second, so collapsing them needs a
  decision about that pinned contract rather than a quiet edit. `commands/_shared/elicitation.md`
  references the rules instead of restating them, so there is no third home. Raise it separately.
- **Deferred — WIP limits.** Published practice caps items in flight and swarms when a column fills.
  Not built: this framework has one operator, so a limit has no second person to redirect.
- **Deferred — MoSCoW capacity cap.** Priority per rule is added (W8); the "Musts under 60% of
  capacity" check is not, because the framework has no capacity number to check against.
- **Could not verify — "update the task row" as a Definition-of-Done line.** No authoritative source
  makes it one. The justification is local and is stated under Verified current state.
- **Could not verify — whether unexecuted features indicate over-planning.** Three features have never
  started; all three could equally reflect the operator's priorities. Nothing here separates the two.

## Verified current state

- Three of twelve features have never started · every shard of `abuse-observability`,
  `pickup-scheduling` and `public-events` under `~/vault/_features/` carries `status: todo`; the other
  nine have at least one shard at `in-progress`, `built` or `done` · 2026-09-01.
- **The feature-level status field is wrong on nine of twelve features** · their `header.md` reads
  `status: planning` while their own shards read `in-progress` or `done`; nothing in any command
  writes `header.md` after seeding · 2026-09-01.
- **Shard status has no controlled vocabulary** · seven different values are in use across 43 shards —
  `todo`, `not-started`, `planned`, `in-progress`, `built`, `done`, `cancelled` — against a template
  that offers three · 2026-09-01.
- An up-front session split can work · `~/vault/_features/ask-digitally/projects/digitally-core/plan.md`
  shipped 10 of 10 planned sessions between 2026-08-03 and 2026-08-28, recording each deviation in the
  row that deviated · 2026-09-01.
- An up-front session split can also stall · `~/vault/givore/plans/2026-07-23-2013-marketplace-execution-roadmap.md`
  ran 2 of 15 planned sessions in 5.5 weeks. The difference from the case above is where the tracker
  lived: in the shard the executing session already opens, against a separate file nothing made anyone
  read · 2026-09-01.
- A status row goes stale unnoticed · one `ask-digitally` row sat unchanged for 10 days · 2026-09-01.
- `/v-pm` has no Definition of Done · `grep -rin "definition of done" commands/ templates/` returns
  nothing · 2026-09-01.
- `/v-pm` splits work only to one shard per repo · `commands/v-pm/steps/04-seed-workspace.md` §3.1
  seeds a shard per participant and nothing below it · 2026-09-01.
- `/v-pm`'s clarify gate is borrowed from execution and tuned to ask *less* ·
  `commands/v-pm/steps/01-intake.md` §1.1 delegates to `commands/v-work/steps/03-propose.md` §3a.0a,
  which says "don't manufacture questions" · 2026-09-01.
- A "done" status can be false · four `ask-digitally` sessions were marked done against a code path
  that could not run (`S4b`: "Bedrock refuses `generation-1.0.json` on every call, so S4–S7 had never
  produced a live answer") · 2026-09-01.
- The per-test gate already exists, unnamed · `commands/v-team/steps/04-execute-loop.md` §5.2 requires
  builds, green ≥3×, coverage up, and "kills ≥1 seeded mutant — **or, equivalently, a characterization
  check**: temporarily break the code and confirm the test fails" · 2026-09-01.
- This repo has no mutation tool and no end-to-end harness · `tests/` holds bats only and `tests/e2e/`
  is installer-only, excluded from `make test` · 2026-09-01.
- `bin/doc-lint.sh` does not check `commands/_shared/` · `is_document_folder()` at lines 93–101 omits
  it, and the four existing modules there carry no frontmatter, so the linter exits 0 on any content ·
  2026-09-01.
- `commands/v-work/steps/05-commit-capture.md` commits in §5.1, before §5.4 · a gate placed in §5.4
  cannot block a commit that already happened · 2026-09-01.
- `commands/v-do.md` never reads the capture step · so any gate placed there does not apply to `/v-do`
  sessions · 2026-09-01.
- `vault/indications/requirements-spec-vs-established.md` cites `/v-capture` "Step 5b"; the file's
  actual heading is Step 4d · pre-existing defect, unrelated to this change · 2026-09-01.

## Decisions

- The executing session owns the split, and its tracker lives in the shard that session already opens
  — the one stalled roadmap kept its tracker in a file nothing forced anyone to read.
- `/v-pm` states an appetite and names the first slice instead of emitting tasks — it does not read the
  code it is slicing. Weaker ground than first thought; see Open & deferred.
- Elicitation asks everything, then defaults and flags what is unanswered — a hard block on open
  questions is a Definition of Ready, which stalls work that could have started.
- Elicitation stops when the technique menu is exhausted and every remaining question fails the
  existing two-part relevance test — a checkable condition, not a feeling.
- Research runs by default in `/v-pm` and is opt-out — `/v-pm` has 12 lifetime runs, so the cost that
  `vault/decisions/ADR-015-retier-lifecycle-lite-critic-fast-path.md` measured against `/v-team` does
  not apply here. `/v-work` and `/v-team` keep the novel-only gate.
- The Definition of Done splits in two: a baseline every session can meet, and a feature-mode
  extension. Each line takes `met`, `failed` or `not-applicable` with a reason — a line that cannot be
  met honestly must be recorded, never ticked.
- Status rolls up from shard rows; nothing hand-maintains a second copy — the feature-level field is
  wrong today precisely because two places hold it and only one gets written.
- Session rows live in each project's own shard, never a shared file — preserves the single-writer rule
  from `vault/decisions/ADR-013-v-pm-cross-project-planning.md`.
- A row reaches `done` only with evidence recorded beside it — unit-green with no evidence field is
  what let four sessions pass against a dead path.

## Scope & non-goals

Covers `/v-pm`'s intake, planning, seeding and status steps, the three `_features/` templates, and the
four downstream files that must honour the new artifacts. Does not change the conversation-thread
protocol, the contracts-drift check, the persona packs, or `/v-cr`. Does not add a task tracker or any
external integration. Does not add a `## Success criteria` section — `requirements.md` already owns the
success metric under `## Business context & goals`.

## Work items

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
| W1 | `commands/_shared/elicitation.md` | CREATE: the technique menu (document analysis → 5 Whys when handed a solution → scenario walkthrough → example-driven), the stopping rule, and the evidence-first question shape where each option names its ground (vault doc, source URL, or "judgement call, no evidence") | Write | ≤250 lines; the ledger IS `requirements.md` `## Open questions` and flagged defaults land in `## Assumptions to test` — do not invent a second store; reference `communication.md` for question shape, never restate it | `tests/unit/v-pm.bats` asserts the file exists, is ≤250 lines, and names the menu, the stopping rule and the ledger's home | DONE |
| W2 | `commands/_shared/definition-of-done.md` | CREATE: a **baseline** every session can meet (lint clean, every review finding fixed or recorded, vault docs updated) and a **feature-mode extension** (covered REQ ids annotated, the session row updated with evidence). Each line records `met`, `failed` or `not-applicable (reason)` | Write | ≤250 lines; reference `commands/v-team/steps/04-execute-loop.md` §5.2 for the per-test gate and reproduce its disjunction verbatim including the characterization-check alternative — do not copy the rest; no line may require tooling this repo lacks | `tests/unit/v-pm.bats` asserts the file exists, is ≤250 lines, carries `not-applicable`, and reproduces the characterization-check wording | DONE |
| W3 | `commands/v-pm.md` | EDIT lines 60–61: rewrite the soft-research sentence to research-on-by-default with `--no-research` opting out; state that `/v-pm` emits an appetite, not a task list; point intake at `_shared/elicitation.md` | Edit | keep the modes table intact; must agree word-for-word with W5 on the research default | `tests/unit/v-pm.bats` green | DONE |
| W4 | `commands/v-pm/steps/01-intake.md` | EDIT §1.1: replace the borrowed clarify gate with `_shared/elicitation.md`; elicit the feature's measurable success metric and its Definition-of-Done additions | Edit | must state that unanswered questions become flagged defaults, never a block | `grep -qi "elicitation.md"` and `grep -qi "success metric"` | DONE |
| W5 | `commands/v-pm/steps/03-plan-panel.md` | EDIT: drop "soft" from the research front gate; emit appetite + first slice + options-considered; forbid emitting a task list | Edit | keep the four-stage pipeline and finding schema unchanged | `grep -qi "appetite"`; `grep -qvi "soft"` on the research gate line | DONE |
| W6 | `commands/v-pm/steps/04-seed-workspace.md` | EDIT §3.1: seed each shard's appetite and an empty `## Sessions` table header beside the existing REQ id list | Edit | v-pm seeds header and appetite only; the executing session owns every row. State the same "keep out of `## Consumed contract`" exclusion the REQ section already carries, so the drift check stays clean | `grep -qi "## Sessions"` and `grep -qi "Consumed contract"` near it | DONE |
| W7 | `commands/v-pm/steps/07-status.md` | EDIT: derive progress and REQ coverage from **shard rows**, not `header.md`; warn when a feature's rows are all `todo`, and when `header.md` disagrees with its shards | Edit | read-only; read shards only for features whose rollup is not `done`, so the sweep stays bounded | `grep -qi "shard"`; `grep -qi "disagree\|stale"` | DONE |
| W8 | `templates/_features/requirements.md` | EDIT: sharpen the `## Business context & goals` comment to demand a measurable success metric; add `## Assumptions to test` (importance × evidence); add a priority marker per `REQ-NN` | Edit | do **not** add a `## Success criteria` section — the metric's home is `## Business context & goals` | `bin/doc-lint.sh` clean; no second acceptance-shaped section exists | DONE |
| W9 | `templates/_features/generic-plan.md` | EDIT: add `## Appetite` (a budget in sessions per repo), `## First slice`, `## Options considered` (rejected approach + why + source) | Edit | `## Options considered` holds the reason, not the argument | `bin/doc-lint.sh` clean | DONE |
| W10 | `templates/_features/project-shard.md` | EDIT: add a `## Sessions` table — `id · scope · command · status · evidence · last touched · deviation note` | Edit | `status` is exactly `todo`/`doing`/`done`/`dropped`, no other value; `command` is `/v-do`, `/v-work` or `/v-team` only (`/v-ask` writes nothing so it cannot close a row); `evidence` holds a commit or session-record path; `done` without evidence is invalid; a `dropped` row and any deviation each need a note. Coverage lives here **only** — delete the coverage-annotation instruction from `## Business rules to satisfy` so one fact has one home. State the exclusion from `## Consumed contract` | `bin/doc-lint.sh` clean; the REQ section no longer instructs coverage annotation | DONE |
| W11 | `commands/v-team/steps/03-propose-loop.md` | EDIT: add the decomposition sub-step — split this repo's scope into session-sized units against the measured ~9-file median, pick each unit's command off the existing ladder, write them as `## Sessions` rows, stop at the stated appetite | Edit | must not re-derive the appetite (it comes from `generic-plan.md`) and must not restate the ladder — reference `vault/indications/light-command-siblings.md` | `grep -qi "session-sized"`, `grep -qi "appetite"`, `grep -qi "light-command-siblings"` | DONE |
| W12 | `commands/v-team/steps/00-feature-pickup.md` | EDIT §0.2: read the shard's `## Sessions` table and report progress in the step output | Edit | read-only, as §0.2 already is | `grep -qi "## Sessions"` | DONE |
| W13 | `commands/v-work/steps/05-commit-capture.md` | EDIT: place the Definition-of-Done check **before** §5.1 stages and commits, as a new §5.0 | Edit | the baseline applies to every session; the feature-mode extension applies only when a `## Sessions` row exists. A plain session must not be blocked by a row it has none of. Reference `_shared/definition-of-done.md`; do not restate it | `grep -n "definition-of-done.md"` shows it above the `git status` block | DONE |
| W14 | `commands/v-do.md` | EDIT the self-review section: apply the baseline Definition of Done, since `/v-do` never reads the capture step and W10 permits `/v-do` rows | Edit | baseline only — `/v-do` has no approval gate and must stay cheap | `grep -qi "definition-of-done.md"` | DONE |
| W15 | `commands/v-capture.md` | EDIT: roll the feature's `header.md` status up from its shard rows on the way out | Edit | derive, never ask; this is the fix for the nine wrong status fields | `grep -qi "header.md"` | DONE |
| W16 | `vault-guide.md` §13 | EDIT: document the appetite, the first slice, the `## Sessions` table and the status rollup in the workspace layout | Edit | ≤600 lines total | `bin/doc-lint.sh` clean | DONE |
| W17 | `vault/indications/requirements-spec-vs-established.md` | EDIT: correct "`/v-capture` Step 5b" to Step 4d | Edit | pre-existing defect; W2 and W13 build on that step | `grep -q "Step 4d"`; `grep -qv "Step 5b"` | DONE |
| W18 | `tests/unit/v-pm.bats`, `tests/unit/research-clarify.bats`, `tests/unit/v-team.bats` | EDIT: file contracts for W1–W17, each beside the gate it qualifies — the research default into `research-clarify.bats`, the W11/W12 contracts into `v-team.bats`, the rest into `v-pm.bats` | Edit | assert the ≤250-line caps directly; do **not** use `bin/doc-lint.sh` for `commands/_shared/` files, where it exits 0 on any content | `tests/run.sh` — 430 pass; the 11 failures all match the pre-existing set by name | DONE |
| W19 | `vault/decisions/ADR-024-vpm-pm-discipline.md` | CREATE the decision record: the corrected counts, the four decisions, consequences | Write | ≤120 lines; must state that it amends `ADR-012`'s research-gate scope **for `/v-pm` only**, and that `/v-work` and `/v-team` keep the novel-only gate | `bin/doc-lint.sh` clean | DONE |
| W20 | `vault/indications/plan-appetite-not-tasks.md` | CREATE the working rule: the planner sets a budget and names the first slice; the executing session splits, picks each piece's command off the ladder, and owns its own status rows with evidence | Write | ≤80 lines | `bin/doc-lint.sh` clean | DONE |

## Sequencing & dependencies

W1 and W2 before every item that references them. W11 ships in session 1 with W3, W5, W6 and W9: `/v-pm` must not start emitting an
appetite before anything decomposes it. W12–W15 depend on W9 and W10 existing. W18 depends on every
file it asserts against. W19 and W20 last.

## Success criterion for this plan

By **2026-10-15**, every feature under `~/vault/_features/` has a `header.md` status that matches its
own shard rows, and every `done` row carries evidence. Measured by re-running the two checks under
Verified current state. If the mismatch count is still above zero, the rollup in W15 did not work and
the status field should be removed rather than left lying.

## Rollback

Every item is a documentation or command-spec change in one git repo; `git revert` of the two commits
restores the previous behaviour with no migration. Nothing writes to a project vault, changes a data
format on disk, or touches installed symlinks. Existing `_features/` workspaces keep working: every
new section is additive and optional, so a workspace seeded before this change reads without error.
The change is fully reversible.

## Test plan

The framework has no runtime, so verification is file contracts plus the linter where it actually runs.

- **File contracts** — `tests/unit/v-pm.bats`, `research-clarify.bats` and `v-team.bats` per W18:
  assert each new module exists, sits under its line cap, and that each new section name is present in
  the file that must carry it.
- **Doc lint** — `bin/doc-lint.sh` on the templates, the guide and the two vault records. Not on the
  two `_shared` modules: the linter does not cover that directory, so a pass there proves nothing.
- **Regression** — `tests/run.sh` (bats inside the container, never on the host). Eight failures are
  pre-existing as of `2026-08-24-1214-docs-writing-standard-pass`; the count must not rise.
- **Manual dry-run** — one `/v-pm` plan run against a throwaway single-repo necessity, checking that
  elicitation fills `## Open questions` and that no task list is emitted.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T1 | W1 | unit | `tests/unit/v-pm.bats` | the elicitation module exists, is ≤250 lines, and names its stopping rule and the ledger's home | high | |
| T2 | W2 | unit | `tests/unit/v-pm.bats` | the Definition-of-Done module carries `not-applicable` and reproduces §5.2's characterization-check alternative | high | |
| T3 | W13 | unit | `tests/unit/v-work.bats` | the check sits above the staging block, and a session with no `## Sessions` row is not blocked by the feature-mode lines | high | |
| T4 | W10 | unit | `tests/unit/v-pm.bats` | the shard table has `evidence` and `last touched`, restricts `status` to four values, and `## Business rules to satisfy` no longer instructs coverage annotation | high | |
| T5 | W11 | unit | `tests/unit/v-team.bats` | the propose loop splits scope into session-sized units, honours the appetite, and assigns a command off the ladder | high | |
| T6 | W15, W7 | unit | `tests/unit/v-pm.bats` | capture rolls `header.md` up from shard rows, and status flags a header that disagrees with its shards | high | |
| T7 | W3, W5 | unit | `tests/unit/research-clarify.bats` | `/v-pm` states research-on-by-default while `/v-work` and `/v-team` keep the novel-only gate | high | |
| T9 | W8, W9 | unit | `tests/unit/document-standard.bats` | the edited templates pass `bin/doc-lint.sh` and carry no second acceptance-shaped section | medium | |
| T10 | W17 | unit | `tests/unit/document-standard.bats` | the indication cites `/v-capture` Step 4d | low | |

## Refs

- `vault/decisions/ADR-013-v-pm-cross-project-planning.md` — establishes the workspace and the
  single-writer rule this plan must not break by adding a shared status file.
- `vault/decisions/ADR-014-vpm-business-knowledge-center.md` — establishes `requirements.md` and the
  `REQ-NN` id chain that the coverage tracking extends.
- `vault/decisions/ADR-012-propose-clarify-research-gates.md` — the clarify and research gates; W19
  amends its research scope for `/v-pm` only.
- `vault/decisions/ADR-015-retier-lifecycle-lite-critic-fast-path.md` — the cost reasoning that gated
  research to novel choices, and the `/v-ask` → `/v-do` → `/v-work` → `/v-team` ladder each session row
  picks its command from.
- `vault/indications/light-command-siblings.md` — the ladder's rules, referenced by W11 not restated.
- `vault/indications/requirements-spec-vs-established.md` — the spec-against-established boundary; W17
  fixes its wrong step number.
- `commands/_shared/communication.md` — owns how a question is shaped; `elicitation.md` references it.
- `2026-09-01-0900-vpm-pm-discipline.trail.md` — the reviewer findings, the rejected options, and the
  corrected evidence behind each decision above.
