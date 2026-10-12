---
type: plan
project: vault
slug: v-pm-planning-loop
repos: [vault]
status: approved
process_record: 2026-10-12-0944-v-pm-planning-loop.trail.md
arch_spec: 2026-10-12-0944-v-pm-planning-loop.arch.md
human_plan: https://claude.ai/artifact/1p53JxX85WZycsqK7gunwB
session_of:
session:
tags: [plan, v-pm, personas, planning]
---

# v-pm-planning-loop — plan

## Task
Rework `/v-pm` into a read-only planner. It refuses to plan until the operator states success criteria. It reads the vault and the code of every repo in scope, researches prior art, and drafts an architecture plan. A parallel panel of planning reviewers critiques the draft until it converges. The output is one normalized plan. Its Sessions table names the repo and command of each session and gives a run order in parallel waves. Each session has one brief with a ready-to-paste shell line. The reviewers live in a reusable group, `personas/_shared/planning/`. Keywords: `v-pm`, `planning`, `personas/_shared/planning`, `briefs/`, `pm-plan.sh`, `feature-pickup`, `session_of`, `scale tier`.

## Open & deferred
- accepted: the review ran its two rounds. The second round raised 16 new must-fix items about claiming and closing a session row, and all are applied below without a third review. The rules most likely to hide a remaining gap are D-10 to D-13.
- accepted limit: a claim (`doing`) is visible only to sessions that share the working copy of the plan's vault until the next push succeeds. `~/vault/_features` has no upstream today, so every claim stays local (D-12).
- accepted limit: legacy workspaces keep their current shard readers unchanged (D-13). Open shard rows today: `empty-feed-activation` api S1 `doing`, `feature-requests` api S4 `blocked`, `city-location-gating` (three shards with a non-standard column order), and `ask-digitally` (no `## Sessions` table). Reconcile converts a row only after the operator confirms its mapping.
- unverified: whether a bare `/v-work` inside the quoted prompt of `claude "<prompt>"` resolves to the plugin skill `vault:v-work`. S4 closes only after one pasted run line is seen to fire Step 0 (SC-7).
- unverified: no test runs a `/v-pm` session end to end. SC-5 runs the plan format through both scripts; the command steps are graded by text.
- existing defect, not this plan's: three unit tests fail on `e292f48`, before this plan: `research-clarify.bats` 11 and `document-standard.bats` 33 and 41. `checks/pm-loop-SC-6.sh` tolerates the `research-clarify.bats` one by name.
- existing defect, not this plan's: `bin/gate.sh`, `bin/vault-sync.sh`, `tests/integration/vault-sync.bats` and `tests/unit/gate.bats` carry uncommitted changes from other work. No session of this plan stages them.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Do existing `_features/` workspaces need migrating? | no | status-column scan of `~/vault/_features/*/projects/*/plan.md` `## Sessions` | defaulted | no; their readers stay unchanged and reconcile converts one with operator-confirmed mapping (D-13) |
| Q-2 | Keep the business-advisor and product-owner reviewers? | no | `commands/v-pm/steps/03-plan-panel.md` §(b); `commands/_shared/elicitation.md` | defaulted | no; intake elicitation writes `requirements.md`, and `lazy-dev` asks whether the work is worth building (D-2) |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a command loads the planning group THE SYSTEM SHALL find `personas/_shared/planning/README.md` and eight lens files (`solution-architect`, `codebase-fit`, `lazy-dev`, `future-scope`, `system-integration`, `security-architect`, `harness-engineer`, `delivery-planner`), each at most 150 lines, each with persona frontmatter and the sections Mandate, Bound analyzer, Severity rubric, Checklist, Scale and Output, and `personas/_resolution.md` SHALL name the group's selection rule | functional | command | `checks/pm-loop-SC-1.sh` | exit 0 | | |
| SC-2 | WHEN `bin/pm-plan.sh` runs on `tests/fixtures/pm/` THE SYSTEM SHALL exit 0 for `check` on the valid plan, print one line per session for `order` (wave, id, status, readiness, repo, brief), set one row with `set`, and exit 1 naming the defect for a missing brief, a brief without a `## Next command` run line, a run line whose repo or command differs from its row, an empty success-criteria table, a criterion no session reaches, a missing default done line, a contract whose consumer does not list the producer in `depends`, and a `depends` cycle | functional | command | `checks/pm-loop-SC-2.sh` | exit 0 | | |
| SC-3 | WHEN a session reads `commands/v-pm.md`, `commands/v-pm/steps/` and `commands/_shared/elicitation.md` THE SYSTEM SHALL find the success-criteria refusal with its reply text, the scale tier, the read-only code orientation, the parallel planning panel, `pm-plan.sh check` before the approval gate, briefs written from `templates/handoff.md`, and no sequential pipeline and no appetite | functional | command | `checks/pm-loop-SC-3.sh` | exit 0 | | |
| SC-4 | WHEN a session reads the execution side THE SYSTEM SHALL find `commands/_shared/feature-pickup.md` named by `commands/v-work.md` and `commands/v-team.md`, the row write after the code commit in `commands/v-work/steps/05-commit-capture.md`, no step `(f3)`, and no file outside the legacy readers naming `generic-plan.md`, `planning-session.md` or `plan-appetite-not-tasks` | functional | command | `checks/pm-loop-SC-4.sh` | exit 0 | | |
| SC-5 | WHEN a plan is instantiated from `templates/feature-plan.md` with two briefs from `templates/handoff.md` THE SYSTEM SHALL keep every `##` heading of the template, pass `bin/pm-plan.sh check` and `bin/gate.sh master`, mark only S1 runnable in `order`, and mark S2 runnable once `set` makes S1 `done` | delivery | command | `checks/pm-loop-SC-5.sh` | exit 0 | | |
| SC-6 | WHEN the unit tests this plan touches run in the test container THE SYSTEM SHALL pass `tests/unit/v-pm.bats`, `tests/unit/pm-plan.bats`, `tests/unit/planning-personas.bats`, `tests/unit/v-team.bats` and `tests/unit/research-clarify.bats` | functional | command | `checks/pm-loop-SC-6.sh` | exit 0 | | |
| SC-7 | WHEN the operator pastes one run line produced from `tests/fixtures/pm/valid/` into a shell THE SYSTEM SHALL open Claude Code in the named repo and run Step 0 of the named command against that session | delivery | observed | paste the S1 run line of `tests/fixtures/pm/valid/briefs/` and read the first reply; FAIL when the reply does not print the session pickup output; no-command: no harness drives an interactive Claude Code session | Step 0 output names S1 | | |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | change does what the task asked | | |
| B2 | tests covering the change pass | | |
| B3 | lint passes on changed files | | |
| B4 | every review finding fixed or recorded | | |
| B5 | invalidated docs updated | | |
| B6 | nothing unrelated in the commit | | |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | A `/v-pm` plan is normalized: every Sessions row has one brief whose run line names the row's repo and command | ENFORCED | `bin/pm-plan.sh check` at the end of `commands/v-pm/steps/03-plan-panel.md`; the approval gate refuses on exit 1; `tests/unit/pm-plan.bats` |
| E-2 | `/v-pm` does not plan without operator success criteria, a session reaching each, and the default done lines | ENFORCED | `bin/pm-plan.sh check`; `tests/unit/pm-plan.bats` |
| E-3 | A session started from a brief may not start before its dependencies are `done` | ENFORCED | `commands/_shared/feature-pickup.md` refuses unless `pm-plan.sh order` prints the row `todo runnable`; `bin/gate.sh master` refuses the same case at close |
| E-4 | `/v-pm` writes no code | PROSE | `commands/v-pm.md` and `commands/v-pm/steps/02-load-context.md` say so; reviewers run read-only |
| E-5 | A planning finding blocks only with re-runnable evidence | PROSE | `personas/_shared/planning/README.md` grounding rule, linked from each lens's Output section |

## Verified current state
- `/v-pm` runs a sequential four-reviewer pipeline and emits an appetite, never session rows · `sed -n 196,219p commands/v-pm/steps/03-plan-panel.md` · 2026-10-12
- `/v-team` step `(f3)` holds the only copy of the session sizing rules (~9 files median, split past ~15, vertical cut, command ladder) · `sed -n 207,241p commands/v-team/steps/03-propose-loop.md` · 2026-10-12
- `bin/gate.sh` can be sourced without running, which exposes `table_rows`, `table_header` and `col_index`; `bin/render-human.sh` already does this · `tail -3 bin/gate.sh`; `sed -n 12,17p bin/render-human.sh` · 2026-10-12
- `lib/master-check.sh` order mode reads readiness from contract rows only, never from `depends`, and detects self-loops only · `lib/master-check.sh` `master_problems` · 2026-10-12
- `session_of` resolves a relative path against the plan's folder and does not expand `~` · `lib/master-check.sh` `master_order_check` · 2026-10-12
- `~/vault/_features` is its own git repository with no upstream · `git -C ~/vault/_features rev-parse --abbrev-ref @{u}` fails · 2026-10-12
- every exit of `bin/vault-sync.sh` is non-fatal to its caller, and `commands/_shared/vault-sync.md` says a sync failure never halts the lifecycle · `bin/vault-sync.sh` header; `grep -n 'never halts' commands/_shared/vault-sync.md` · 2026-10-12
- close step 5.0 runs before the step 5.1 code commit, and sets the master row there today · `sed -n 12,39p commands/v-work/steps/05-commit-capture.md` · 2026-10-12
- `/v-work` has no Step 0, a fast path that skips LOAD CONTEXT, and no `session_of` line in PROPOSE · `commands/v-work.md`; `commands/v-work/steps/01-analyze.md` §1.4c; `grep -n session_of commands/v-work/steps/03-propose.md` · 2026-10-12
- `commands/_shared/elicitation.md` makes `requirements.md` the single home of the success metric and records a missing metric as open instead of refusing · `grep -n 'not supplied\|single home\|not a gate' commands/_shared/elicitation.md` · 2026-10-12
- `templates/handoff.md` already carries Left to do, Do not touch, Goal, Requirements, Next command and Success criteria, and `handoff` is a contract type in `bin/doc-lint.sh` · `grep -n '^## ' templates/handoff.md`; `bin/doc-lint.sh` `is_record_type` · 2026-10-12
- `claude "<prompt>"` starts an interactive session with that prompt · `claude --help` · 2026-10-12

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 `/v-pm` runs the parallel panel of `commands/v-team/steps/03-propose-loop.md` §(c) to §(f) by reference. §(e).6 writes to "the trail sidecar of the caller's plan". `/v-pm` runs no `(f2)` test-design fan-out, so advisory test hints stay in the trail. The sequential pipeline is deleted | one loop definition; the trail path was the only value hard-coded to `/v-team` | ADR-033 |
| D-2 A new group `personas/_shared/planning/` holds eight lenses: `solution-architect`, `codebase-fit`, `lazy-dev`, `future-scope`, `system-integration`, `security-architect`, `harness-engineer`, `delivery-planner`. `consumer` and `skeptic` are reused; on a planning panel `skeptic` leaves the simpler-path question to `lazy-dev`. Each lens is at most 150 lines and references the shared lens it extends (`quality.md`, `security.md`) instead of restating it. The README table carries a "not mine, goes to" column | software and AI harnesses fail differently, so `harness-engineer` is its own seat; thin lenses keep reviewers decorrelated | ADR-033 |
| D-3 A planning finding is `confirmed` only when `check` holds a repo `path:line`, a vault path, or a command whose output the synthesizer can re-run, such as `npm view <pkg>`. A fetched URL alone keeps a finding `advisory`, and the operator sees it as a sourced proposal. The rule lives once in `personas/_shared/planning/README.md`; each lens's Output section links to it | the synthesizer cannot re-grade grounding, so the lens must demand re-runnable evidence | ADR-033 |
| D-4 Intake sets a scale tier from countable intake facts. `small`: 1 repo, and no schema, auth, payment, public-contract or new-external-service change. `large`: 3 or more repos, or 2 repos with a contract change, or a new system. `medium`: every other case. The tier sets the per-run reviewer cap (3, 4, 5) and round cap (1, 2, 2); a `team_max_parallel_critics` or `team_max_rounds` key in `VAULT.md` caps the per-run value and is never rewritten. `solution-architect`, `lazy-dev` and `consumer` always sit; the other lenses seat on a trigger. The table lives in the planning README | a small project must not get a large-system plan; `/v-team`'s own caps stay untouched | ADR-033 |
| D-5 `/v-pm` reads code read-only (Serena when present, else grep) in LOAD CONTEXT and writes only vault files | slicing a repo into sessions needs its code; the planner implements nothing | ADR-033 |
| D-6 `/v-pm` decides the session count. `plan.md` carries `## Sessions` and `## Cross-session contracts` under `templates/master-plan.md`, which gains three optional columns: `repo` (absolute path where the command runs), `req` (the `REQ-NN` ids the session satisfies, written only by `/v-pm`) and `deviation` | the row is the one home of status, repo, command, dependencies and rule coverage | ADR-033 |
| D-7 A brief is an instance of `templates/handoff.md` saved as `briefs/<id>-<slug>.md`, with `plan` (absolute path) and one added key `id`. Its `## Next command` holds the run line; `## Left to do` names the exact files; `## Success criteria` copies the master criteria the row reaches | the next session already reads that shape; no second template or doc-lint type | ADR-033 |
| D-8 A multi-repo plan lives in `~/vault/_features/<feature>/`; a single-repo plan in `<project-vault>/plans/<feature>/`. Both hold `plan.md` from `templates/feature-plan.md`, `plan.trail.md` and `briefs/`. Options considered and research go in the trail | one format for both homes; `briefs/` does not collide with old `sessions/` records | local |
| D-9 `bin/pm-plan.sh` has three subcommands. `check <plan>` validates the format. `order <plan>` prints one line per session: wave, id, status, readiness (`runnable`, `waits <ids>`, `blocked <dropped ids>` or `done`), repo, brief path. `set <plan> <id> <field>=<value>...` edits one row under `flock`. Readiness reads `depends` only, and `check` refuses a contract whose consumer does not list its producer in `depends`, so `gate.sh master` and `order` agree. Wave layering and cycle detection are new code; table parsing sources `bin/gate.sh` | one parser, one readiness rule, one row writer | local |
| D-10 A brief's run line is `cd <repo> && claude --add-dir <plan folder> "<command> <absolute plan path>#<id>"`. `pm-plan.sh check` refuses a line whose repo or command differs from the row | the pasted line starts Claude Code in the right repo, lets it write the plan, and names the session exactly | ADR-033 |
| D-11 `commands/v-team/steps/00-feature-pickup.md` moves to `commands/_shared/feature-pickup.md` and becomes Step 0 of `/v-work` and `/v-team` when the task holds `<plan>#<id>` or `<feature>` with an optional `S<n>`. It resolves the plan (`<project-vault>/plans/<feature>/plan.md`, then `~/vault/_features/<feature>/plan.md`). It also resolves the tracker: `plan.md` Sessions, else the legacy shard rows. It refuses and ends the session unless `order` prints the row `todo runnable`, then writes `doing` through the D-12 routine. It reads the brief's `## Goal` as the task restatement and prints upstream `deviation` cells. It copies the master criteria the row reaches into the session plan, and turns off the `/v-work` fast path. `/v-work` lists it as task 0. `/v-work` and `/v-team` PROPOSE write `session_of: <absolute plan path>#<id>` | one file resolves the plan and the tracker for every reader; thread pickup and the drift check keep their place in it | ADR-033 |
| D-12 One routine writes a master row: `bin/vault-sync.sh pull` on the plan's vault, `pm-plan.sh set`, then `bin/vault-sync.sh push` naming `plan.md` and any brief the session appended. Exit 0 is done. Exit 1 retries once after a fresh pull, then records the unpushed row in the session's Open & deferred. Exit 4 stages the files in the session's own commit. Exit 5 commits locally and says once that the plan stayed local. The routine never halts a close | the master sits in another git repo; the shared sync contract stays non-fatal | ADR-033 |
| D-13 The close writes the row after the step 5.1 code commit, as step 5.1a: `status: done`, `evidence: <commit sha>` and the master criteria verdicts. A workspace without `plan.md` keeps its current shard readers unchanged. `/v-pm reconcile <feature>` converts shard rows into `plan.md` only after the operator confirms the mapping of each non-standard heading, status or id, and folds `generic-plan.md` into `plan.trail.md` | `done` means committed; live shards differ in shape, so conversion cannot be blind | ADR-033 |
| D-14 An executing session may edit its own row's `scope` and `deviation`, and may append a row plus a brief when it finds work no row holds. `pm-plan.sh check` accepts the result. `pm-plan.sh set <plan> <id> status=todo` releases a row a dead session left `doing` | the rows will be wrong in detail; a tracker the session cannot correct goes stale | ADR-033 |
| D-15 Step `(f3)` of `commands/v-team/steps/03-propose-loop.md` is deleted. Its sizing rules move into `personas/_shared/planning/delivery-planner.md`: the ~9 file median, a split past ~15, a vertical cut with the hardest part first, the command ladder, `/v-ask` not eligible, and rows expected to be wrong in detail | the rules keep one home, the lens that reviews the split | ADR-033 |
| D-16 The project shard template keeps `## What this project does for the feature`, `## Consumed contract`, `## Constraints & rationale`, `## Tests to guard the behavior` and `## Up-links`, and loses its Sessions, Cross-session contracts and Business-rules sections. `templates/_features/generic-plan.md` and `templates/_features/planning-session.md` are deleted; `plan.trail.md` from `templates/trail.md` is the planning record | the tracker and the rule coverage have one home in a new workspace; the drift check still reads `## Consumed contract` | ADR-033 |
| D-17 `/v-pm` stops at an approval gate before it commits the plan. The gate runs `pm-plan.sh check` and `gate.sh master` and refuses on exit 1 | approving the plan authorizes every session it creates | local |
| D-18 `/v-pm` refuses to plan until the operator states at least one success criterion as `WHEN <trigger> THE SYSTEM SHALL <observable>`. Intake may draft a line from the operator's own words; an explicit operator "yes" to that line counts as stated, silence does not. `plan.md` `## Success criteria` is the single home of the target; `requirements.md` `## Business context & goals` references it. `commands/_shared/elicitation.md` states this `/v-pm` exception once; `/v-method` and `/v-loop` keep the current behaviour | a plan with no operator-owned target cannot be judged done | ADR-033 |
| D-19 `plan.md` `## Definition of done` carries four lines the operator may extend. DD-1 is planning done: the plan is approved and `pm-plan.sh check` exits 0. DD-2 is code implemented: every row `done` with evidence, or `dropped` with a reason, per F2 and F3 of `commands/_shared/definition-of-done.md`. DD-3 is code tested, per B2. DD-4 is static analysis passed, per B3, or `not-applicable` with a reason on a repo with no code. `check` refuses a missing line, never a blank state. `/v-pm status` fills DD-2 to DD-4 when every row is closed | the floor keeps one home in the module; the plan shows the operator's four lines | ADR-033 |
| D-20 `ADR-033` supersedes ADR-024 decisions 3 and 4, and from ADR-013 the sequential pipeline, the clause that `/v-work` load-context stays untouched, and the derived-ledger no-race clause. It supersedes ADR-014's single-writer shard business-rules section, whose role passes to the `req` column written only by `/v-pm`. It amends ADR-024 decision 1 for success criteria only (D-18), and names the ADR-029 sentence on appetite it replaces | every reversed clause is named, so no older record reads as current | ADR-033 |
| D-22 All five sessions run in one conversation, one commit each | approved by the operator with the defaults | local |
| D-21 `vault/indications/pm-plans-sessions.md` replaces `vault/indications/plan-appetite-not-tasks.md` | the old rule rested on `/v-pm` not reading code, which D-5 reverses | ADR-033 |

## Scope & non-goals
In scope: the planning group, the feature-plan template, the master-plan columns, briefs as handoffs, `bin/pm-plan.sh` and the shared feature-pickup step. Also in scope: every `/v-pm` step, and each file that reads the old appetite, shard tracker or generic plan.

Not in scope: the thread protocol, `contracts.md`, and the legacy shard readers' behaviour. No command other than `/v-pm` seats the planning group by default. A pack reuses a lens through `use_shared` or `personas.add`.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `personas/_shared/planning/*.md` lens files | `commands/v-pm/steps/03-plan-panel.md` reviewer seating | S1 | each reviewer, verbatim in its envelope | a lens with no file: the step warns once and seats `skeptic` in its place; `checks/pm-loop-SC-1.sh` exits 1 |
| tier table and grounding rule in `personas/_shared/planning/README.md` | `commands/v-pm/steps/01-intake.md` and every reviewer envelope | S1 | intake, reviewers | no tier in the intake output: the panel step refuses to seat reviewers |
| `## Success criteria` and `## Definition of done` of `plan.md` | `bin/pm-plan.sh check` | `/v-pm` intake, from the operator | the approval gate; `commands/_shared/feature-pickup.md`, which copies the reached criteria into the session plan | empty criteria, an unreached criterion or a missing default line: `check` exit 1 and the gate refuses |
| `## Sessions` and `## Cross-session contracts` of `plan.md` | `bin/pm-plan.sh` `check`, `order`, `set`; `bin/gate.sh master` | `/v-pm` step 03; the executing session through the D-12 routine | feature pickup, `/v-pm status`, the operator | `check` names the row; pickup refuses a row that `order` does not print `todo runnable` |
| brief `briefs/<id>-<slug>.md` and its `## Next command` run line | `commands/_shared/feature-pickup.md` | `/v-pm` step 03; an executing session that appends a row | the operator who pastes the line, the executing session | `check` exit 1: missing brief, missing run line, repo or command differing from the row |
| `session_of: <absolute plan path>#<id>` in the executing plan | step 5.1a of `commands/v-work/steps/05-commit-capture.md` and `bin/gate.sh master` | `/v-work` and `/v-team` PROPOSE | the close step | a relative or `~` path into another vault: `gate.sh master` refuses with `session_of names a master plan that does not exist` |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `personas/_shared/planning/README.md` | new: lens table with "not mine, goes to", grounding rule (D-3), tier table and cap precedence (D-4), reuse note | Write | ≤150 lines | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-2 | `personas/_shared/planning/solution-architect.md` | new lens from `vault/research/v-pm-planning-lenses/architect.md` | Write | ≤150 lines | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-3 | `personas/_shared/planning/codebase-fit.md` | new lens from `vault/research/v-pm-planning-lenses/fit-and-lazy.md`; references `personas/_shared/quality.md` | Write | ≤150 lines; no package question | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-4 | `personas/_shared/planning/lazy-dev.md` | new lens with the package evidence card | Write | ≤150 lines | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-5 | `personas/_shared/planning/future-scope.md` | new lens from `vault/research/v-pm-planning-lenses/future-scope.md` with the one-way-door rule | Write | ≤150 lines | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-6 | `personas/_shared/planning/system-integration.md` | new lens from `vault/research/v-pm-planning-lenses/system-integration.md` | Write | ≤150 lines; seated only with 2+ systems | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-7 | `personas/_shared/planning/security-architect.md` | new lens from `vault/research/v-pm-planning-lenses/security-architect.md`; references `personas/_shared/security.md` | Write | ≤150 lines | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-8 | `personas/_shared/planning/harness-engineer.md` | new lens from `vault/research/v-pm-planning-lenses/harness-engineer.md` | Write | ≤150 lines | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-9 | `personas/_shared/planning/delivery-planner.md` | new lens from `vault/research/v-pm-planning-lenses/delivery-planner.md`, carrying the `(f3)` sizing rules (D-15) | Write | ≤150 lines | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-10 | `personas/_resolution.md` | add §2.3 planning-group selection by tier and trigger | Edit | selection rule lives here only | SC-1 | `checks/pm-loop-SC-1.sh` | TODO |
| W-11 | `tests/unit/planning-personas.bats` | new: lens files, caps, sections, selection, tier thresholds, the moved sizing rules | Write | | SC-6 | `checks/pm-loop-SC-6.sh` | TODO |
| W-12 | `checks/pm-loop-SC-1.sh` | grader | Write | executable | SC-1 | runs | TODO |
| W-13 | `templates/feature-plan.md` | new: Need, Scale, Success criteria with `sessions`, Definition of done DD-1 to DD-4, Decisions, Solution shape, Sessions, Cross-session contracts, Risks and rollback | Write | column rules point to `templates/plan.md` and `templates/master-plan.md` | SC-5 | `checks/pm-loop-SC-5.sh` | TODO |
| W-14 | `templates/master-plan.md` | define the optional `repo`, `req` and `deviation` columns (D-6) | Edit | | SC-5 | `checks/pm-loop-SC-5.sh` | TODO |
| W-15 | `templates/handoff.md` | add the optional `id` key and the brief use (D-7) | Edit | | SC-5 | `checks/pm-loop-SC-5.sh` | TODO |
| W-16 | `bin/pm-plan.sh` | new: `check`, `order`, `set` (D-9) | Write | sources `bin/gate.sh`; expands `~`; `flock` on `set` | SC-2, SC-5 | `checks/pm-loop-SC-2.sh` | TODO |
| W-17 | `tests/fixtures/pm/valid/` | new: one valid plan with two briefs | Write | broken variants are built in the bats file | SC-2 | `checks/pm-loop-SC-2.sh` | TODO |
| W-18 | `tests/unit/pm-plan.bats` | new: the SC-2 variants, `set`, concurrent `set` | Write | | SC-6 | `checks/pm-loop-SC-6.sh` | TODO |
| W-19 | `checks/pm-loop-SC-2.sh` and `checks/pm-loop-SC-5.sh` | graders | Write | | SC-2, SC-5 | runs | TODO |
| W-20 | `commands/v-pm.md` | rewrite plan mode: INTAKE, LOAD CONTEXT, PLAN PANEL, APPROVAL GATE, SEED, CAPTURE; read-only rule | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-21 | `commands/v-pm/steps/01-intake.md` | add the success-criteria refusal with its reply text (D-18), the done lines (D-19), the scale tier (D-4) and the single-repo plan home | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-22 | `commands/_shared/elicitation.md` | state the `/v-pm` exception and the single home of the criteria (D-18) | Edit | `/v-method` and `/v-loop` unchanged | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-23 | `commands/v-pm/steps/02-load-context.md` | add read-only code orientation and the path index handed to reviewers | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-24 | `commands/v-pm/steps/03-plan-panel.md` | rewrite: research, draft plan and briefs, parallel panel, converge, `pm-plan.sh check` | Write | ≤150 lines | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-25 | `commands/v-team/steps/03-propose-loop.md` | §(e).6 names the caller's trail sidecar (D-1) | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-26 | `commands/v-pm/steps/04-seed-workspace.md` | rewrite: symlinks and shard stubs for multi-repo | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-27 | `commands/v-pm/steps/05-capture.md` | the trail replaces the planning record; print `pm-plan.sh order` and the first wave's run lines | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-28 | `commands/v-pm/steps/06-reconcile.md` | convert shard rows with operator-confirmed mapping; fold `generic-plan.md` into the trail (D-13) | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-29 | `commands/v-pm/steps/07-status.md` | read the tracker through feature pickup's resolver; fill DD-2 to DD-4 when every row is closed | Edit | | SC-3 | `checks/pm-loop-SC-3.sh` | TODO |
| W-30 | `tests/unit/v-pm.bats`, `tests/unit/research-clarify.bats`, `tests/unit/document-standard.bats` | update for the new steps | Edit | | SC-6 | `checks/pm-loop-SC-6.sh` | TODO |
| W-31 | `checks/pm-loop-SC-3.sh` | grader | Write | | SC-3 | runs | TODO |
| W-32 | `commands/_shared/feature-pickup.md` | `git mv` from `commands/v-team/steps/00-feature-pickup.md`, extended per D-11 | Bash `git mv`, Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-33 | `commands/v-work.md` | task 0 and Step 0 run feature pickup when the task names a session | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-34 | `commands/v-work/steps/01-analyze.md` | §1.4c: no fast path with a session | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-35 | `commands/v-work/steps/03-propose.md` | write `session_of` as an absolute path | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-36 | `commands/v-work/steps/05-commit-capture.md` | move the master-row bullet from step 5.0 to a new step 5.1a after the code commit (D-12, D-13) | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-37 | `commands/v-team.md` | Step 0 points to `commands/_shared/feature-pickup.md` | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-38 | `commands/v-team/steps/03-propose-loop.md` | delete `(f3)`; the master-plan paragraph points to `/v-pm` for feature splits | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-39 | `commands/v-team/steps/04-execute-loop.md`, `commands/v-capture.md`, `commands/v-do.md` | each row duty references feature pickup's tracker resolver in one line | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-40 | `checks/master-SC-5.sh` | delete; it grades step `(f3)` | Bash `git rm` | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-41 | `tests/unit/v-team.bats` | replace the `(f3)` and Step 0 path tests | Edit | | SC-6 | `checks/pm-loop-SC-6.sh` | TODO |
| W-42 | `checks/pm-loop-SC-4.sh` and `checks/pm-loop-SC-6.sh` | graders | Write | | SC-4, SC-6 | runs | TODO |
| W-43 | `templates/_features/project-shard.md` | delete the three tracker sections (D-16) | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-44 | `templates/_features/generic-plan.md` and `templates/_features/planning-session.md` | delete | Bash `git rm` | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-45 | `templates/_features/header.md`, `templates/_features/requirements.md`, `templates/trail.md` | point to `plan.md`, the success-criteria home and `plan.trail.md` | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-46 | `checks/shard-contracts-SC-1.sh` to `checks/shard-contracts-SC-4.sh` | delete; they grade the shard tracker sections this plan removes | Bash `git rm` | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-47 | `commands/v-method.md` and `templates/method.md` | read the session count from `plan.md` | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-48 | `vault-guide.md`, `docs/cross-project-workspaces.md`, `docs/commands.md`, `README.md`, `_moc.md` | new layout; one-line `/v-pm` entry | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-49 | `vault/decisions/ADR-033-v-pm-planning-loop.md` and `vault/decisions/_inventory.md` | new ADR per D-20, inventory row | Write | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-50 | `vault/indications/pm-plans-sessions.md`, `vault/indications/plan-appetite-not-tasks.md`, `vault/indications/_index.md` | replace the indication (D-21) | Write, `git rm` | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-51 | `vault/features/v-pm.md` and `vault/features/v-method.md` | rewrite the dossier; fix the appetite seam | Edit | | SC-4 | `checks/pm-loop-SC-4.sh` | TODO |
| W-52 | operator paste of one fixture run line | observe Step 0 output | manual | after S4 lands | SC-7 | SC-7 procedure | TODO |

## Sessions

| id | repo | scope | command | status | depends | req | date | evidence | deviation |
|----|------|-------|---------|--------|---------|-----|------|----------|-----------|
| S1 | /home/kdabrow/workspace/vault | planning group: W-1 to W-12 | /v-team | done | | | 2026-10-12 | 5d8e9b4 | |
| S2 | /home/kdabrow/workspace/vault | plan format: W-13 to W-19 | /v-team | done | | | 2026-10-12 | 1e652b8 | |
| S3 | /home/kdabrow/workspace/vault | `/v-pm` command: W-20 to W-31 | /v-team | done | S1 S2 | | 2026-10-12 | a12c16e | |
| S4 | /home/kdabrow/workspace/vault | feature pickup and execution side: W-32 to W-42, W-52 | /v-team | done | S2 S3 | | 2026-10-12 | b08a3a9 1d9adca | |
| S5 | /home/kdabrow/workspace/vault | templates, docs and vault records: W-43 to W-51 | /v-work | todo | S3 S4 | | | | |

## Cross-session contracts

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
| C-1 | planning lens ids and the tier table | S1 | S3 | `personas/_shared/planning/<id>.md` for the eight ids of D-2; tier table in `personas/_shared/planning/README.md` |
| C-2 | feature-plan template, brief keys and the script | S2 | S3 S4 | `templates/feature-plan.md`; `templates/handoff.md` key `id`; `bin/pm-plan.sh` subcommands `check`, `order`, `set` |
| C-3 | `/v-pm` step names and plan homes | S3 | S4 S5 | `commands/v-pm/steps/0[1-7]-*.md`; homes per D-8 |
| C-4 | shared feature pickup | S4 | S5 | `commands/_shared/feature-pickup.md` |

## Sequencing & dependencies
S1 and S2 run in parallel. S3 needs both. S4 lands after S3 because it moves Step 0 and removes `(f3)`. S5 documents the result. Each session is one commit.

## Rollback
Each session is one commit with explicit paths. `git revert` of S5, S4 and S3, in that order, restores the old `/v-pm`; S1 and S2 are additive and can stay. No operator vault is written, so nothing outside this repo needs undoing. Legacy workspaces keep working through their unchanged shard readers whether or not the revert happens.

## Test plan
Bats unit tests run in the container (`./tests/run.sh tests/unit/<file>`). `tests/unit/pm-plan.bats` drives `bin/pm-plan.sh` against `tests/fixtures/pm/valid/` and variants it builds with sed. `tests/unit/planning-personas.bats` checks lens files. `tests/unit/v-pm.bats` and `tests/unit/v-team.bats` check command text.

## Test design dossier
Fault hypotheses for `bin/pm-plan.sh`:
- a brief named by a row is absent, or two briefs share one id;
- a brief has no run line in `## Next command`;
- a run line names a repo or command that differs from its row;
- the success-criteria table is empty, or a criterion names no session;
- a default done line is missing;
- a contract's consumer does not list its producer in `depends`;
- `order` marks runnable a session whose dependency is `doing`;
- `order` meets a `depends` cycle;
- a dependency is `dropped`;
- two `set` calls run at once on one plan;
- a `repo` cell or `plan` path starts with `~`.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | dossier | unit | `tests/unit/pm-plan.bats` | missing brief exits 1 naming the id | must | |
| T-2 | D-10 | unit | `tests/unit/pm-plan.bats` | run line repo or command mismatch exits 1 | must | |
| T-3 | D-9 | unit | `tests/unit/pm-plan.bats` | `order` prints `waits` while a dependency is not `done`, and `blocked` for a `dropped` one | must | |
| T-4 | D-18 | unit | `tests/unit/pm-plan.bats` | empty success criteria, or a criterion no session reaches, exits 1 | must | |
| T-5 | D-19 | unit | `tests/unit/pm-plan.bats` | a missing done line exits 1; a blank state passes | must | |
| T-6 | D-9 | unit | `tests/unit/pm-plan.bats` | a contract whose consumer lacks the producer in `depends` exits 1 | must | |
| T-7 | D-9 | unit | `tests/unit/pm-plan.bats` | a `depends` cycle exits 1 | must | |
| T-8 | D-9 | unit | `tests/unit/pm-plan.bats` | two concurrent `set` calls both land | should | |
| T-9 | D-14 | unit | `tests/unit/pm-plan.bats` | an appended row with its brief passes `check` | should | |
| T-10 | D-2 | unit | `tests/unit/planning-personas.bats` | every lens ≤150 lines with the six sections | must | |
| T-11 | D-15 | unit | `tests/unit/planning-personas.bats` | `delivery-planner.md` carries the ~9 and ~15 thresholds and the command ladder | must | |
| T-12 | D-18 | unit | `tests/unit/v-pm.bats` | `commands/_shared/elicitation.md` names the `/v-pm` exception once, and `commands/v-method.md` is unchanged | should | |

## Refs
- `commands/v-team/steps/03-propose-loop.md` — the loop `/v-pm` reuses by reference.
- `templates/master-plan.md` — owns the Sessions and contracts table rules.
- `templates/handoff.md` — the shape every brief takes.
- `vault/research/v-pm-planning-lenses/` — the sourced research each lens is written from.
- `vault/decisions/ADR-013-v-pm-cross-project-planning.md`, `vault/decisions/ADR-014-vpm-business-knowledge-center.md`, `vault/decisions/ADR-024-vpm-pm-discipline.md` — the clauses D-20 supersedes.
- `2026-10-12-0944-v-pm-planning-loop.trail.md` — the process record.
