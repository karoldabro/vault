---
type: plan
project: vault
slug: mechanical-session-gates
repos: [vault]
status: approved
process_record: 2026-09-04-0900-mechanical-session-gates.trail.md
dod_profile: code
tags: [plan, gates, enforcement]
---

# mechanical-session-gates — plan

## Task

Replace written rules with checks that run. A session may not end while a completion claim is
unproven, and a change may not close without one run of the real system showing that change in its
output. Cut the instruction corpus, because every unenforced rule lowers compliance on the enforced
ones. The gate contract is `vault/architecture/session-gates.md`.

## Open & deferred

| id | item | state |
|----|------|-------|
| O-1 | An unenforced rule is not free. Deleting prose is the repair, not tidying — but nothing yet measures which rules are load-bearing, so D-01 counts before D-03 cuts | OPEN |
| O-2 | Hooks are escapable. They do not fire in `claude -p` pipe mode, subagent and MCP tool calls ignore a deny, and a model blocked from `Write` has been observed using a `Bash` heredoc instead. This is the strongest mechanism available and it is not airtight | ACCEPTED |
| O-3 | The agent verifier is rejected. No LLM-judge configuration exceeds 0.65 AUROC at detecting a false completion claim, and 0.54 on execution traces | REJECTED |
| O-4 | The "read the communication rules before writing output" gate is rejected. No hook fires before a model writes prose. `bin/output-lint.sh` measures the reply instead, and already ships | REJECTED |
| O-5 | The `Read communication.md first` banner stays in 32 command files. Dropping the hard gate is what the evidence supports; deleting 32 pointers is not | ACCEPTED |
| O-6 | `graphify-out/graph.json` cannot support a reachability check here: 2,598 nodes, all markdown documents, all 2,385 edges `contains`, and `bin/` `scripts/` `lib/` unindexed. B-04 greps instead | ACCEPTED |
| O-7 | `verdict --run` executes scripts named in a plan. It must never run against a plan from an untrusted source | ACCEPTED |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a session tries to end with an unproven completion claim THE SYSTEM SHALL block the end and return the failing check as the next instruction | delivery | command | `./tests/run.sh tests/unit/completion-hook.bats` | exit 0 | MET | `./tests/run.sh tests/unit/completion-hook.bats` printed `ok 1` through `ok 12` with no `not ok`; case 1 asserts exit 2 on a DONE item with no verdict |
| SC-2 | WHEN a criterion names a check THE SYSTEM SHALL require a committed script and refuse a command written inline in the plan | unit | command | `./tests/run.sh tests/unit/gate.bats` | exit 0 | | |
| SC-3 | WHEN a plan carries no criterion that runs the real system THE SYSTEM SHALL refuse it | unit | command | `./tests/run.sh tests/unit/gate.bats` | exit 0 | | |
| SC-4 | WHEN the gate runs against this repo's own plan THE SYSTEM SHALL execute every committed check and pass only on the real exit codes | delivery | command | `./bin/gate.sh verdict vault/plans/2026-09-04-0900-mechanical-session-gates.md --run` | exit 0 | | |
| SC-5 | WHEN a check has fired wrongly more than one time in ten THE SYSTEM SHALL report it as over budget | unit | command | `./tests/run.sh tests/unit/gate-budget.bats` | exit 0 | | |
| SC-6 | WHEN the instruction corpus is counted THE SYSTEM SHALL report fewer rule-lines than the 173 it carries today, and more requirements than prohibitions | delivery | command | `./bin/rule-count.sh --assert` | exit 0 | | |
| SC-7 | WHEN a repo declares no test, lint and delivery commands THE SYSTEM SHALL refuse at the first step of a session | unit | command | `./tests/run.sh tests/unit/gate.bats` | exit 0 | | |
| SC-8 | WHEN a defect is repaired THE SYSTEM SHALL require a test that failed before the repair | unit | command | `./tests/run.sh tests/unit/gate.bats` | exit 0 | | |
| SC-9 | WHEN the existing suites run THE SYSTEM SHALL fail no more tests than the four failing today | unit | command | `./bin/regression-count.sh 4` | exit 0 | | |

## Research

| source | takeaway | bears on | verdict |
|---|---|---|---|
| `https://arxiv.org/abs/2505.16944` | AGENTIF: 707 instructions from 50 real agentic apps, 11.9 constraints each; the best model satisfies every constraint on under 30% | the whole instruction corpus | contradicts writing more rules |
| `https://arxiv.org/abs/2507.11538` | IFScale: compliance falls as instruction count rises; 68% at 500 | the corpus size | contradicts growing the framework |
| `https://arxiv.org/html/2605.10039` | 1,650 Claude Code sessions, 16,050 observations: file size, instruction position and file architecture show no detectable effect on compliance | every past attempt to fix rules by rewriting them | contradicts rewriting as a repair |
| `https://arxiv.org/abs/2604.20911` | 4,416 trials: prohibitions fall from 73% to 33% by turn 16; requirements hold at 100%; re-injection restores compliance | 178 prohibitions against 32 requirements here | supports D-02 and D-04 |
| `https://arxiv.org/abs/2606.09863` | 75.8% of failures in self-assessing coding agents are reported as success; no judge configuration exceeds 0.65 AUROC, 0.54 on traces; an independent process reading state drops it to 3% | the verdict path | supports A-01, contradicts an agent verifier |
| `https://arxiv.org/html/2608.02011v1` | Read-Gate: refusing to let an agent finalise before it opened the evidence raised accuracy 14.9 to 19.9 points on the affected cases | the Stop hook shape | supports A-01 |
| `https://abseil.io/resources/swe-book/html/ch20.html` | Tricorder launches a check only under 10% false positives; the platform runs below 5%; noisy analyzers are disabled | every check built here | supports E-01 |
| `https://github.com/sjh9714/nuhuh` | a Stop hook that extracts completion claims and re-executes them against fresh exit codes, files and git state, with no model call | A-01's design | supports A-01 |
| `https://code.claude.com/docs/en/hooks` | a PreToolUse hook denies before the permission check and holds when prompting is off; injected context does not | the hook layer | supports A-02 |

## Verified current state

| fact | how it was checked | date |
|---|---|---|
| A `/v-team` session is told to obey 173 rule-carrying lines across 2,347 lines and roughly 20,000 tokens | one grep for rule words over the twelve files a run reads | 2026-09-04 |
| Prohibitions outnumber requirements 178 to 32 in the shared contracts and step files | two greps over `commands/_shared/` and `commands/v-*/steps/` | 2026-09-04 |
| `bin/gate.sh` exists with `criteria`, `verdict`, `verdict --run` and `all --phase`, and 32 tests pass | `./tests/run.sh tests/unit/gate.bats` | 2026-09-04 |
| The gate reads check strings out of markdown cells, so the session authoring the work also authors the check | read of `cmd_verdict` in `bin/gate.sh` | 2026-09-04 |
| The unit suite is 521 tests with 4 failures, all pre-existing | `./tests/run.sh tests/unit`; failures at `document-standard.bats:308` and `:350`, `plugin-install.bats:106`, `research-clarify.bats:108` | 2026-09-04 |
| `hooks/hooks.json` registers SessionStart, PostToolUse, Stop and UserPromptSubmit; the Stop hook only measures reply length | read of the file and `scripts/output-lint-hook.sh` | 2026-09-04 |

## Decisions

| decision | reason | record |
|---|---|---|
| A check is a committed script, never a command string in a plan | the session that writes the work must not also author the thing that grades it | ADR-026 |
| No model decides whether work was done | no judge configuration exceeds 0.65 AUROC, and 0.54 on execution traces | ADR-026 |
| Every change carries one check that runs the real system and finds the change in its output | an existing suite passes green while a new field never reaches the output | ADR-026 |
| Assertions read what the run produced, never what the system wrote about itself | a manifest records intent; the artifact records delivery | ADR-026 |
| Rules are written as requirements, never as prohibitions | prohibitions fall to 33% by turn 16 while requirements hold | ADR-026 |
| An unenforced rule is deleted rather than kept | compliance falls as instruction count rises, so an ignored rule costs the enforced ones | ADR-026 |
| A check firing wrongly more than one time in ten is fixed or deleted | Google disables an analyzer at that line, and a distrusted check gets switched off wholesale | ADR-026 |
| `GATE=off` stays, whole-run only | a gate with no relief valve is abandoned rather than used with an exception | ADR-026 |

## Scope & non-goals

Covers: the Stop hook that re-runs completion claims, checks as committed scripts, the delivery
check, the instruction cut, the per-check false-positive budget, the recurrence ledger, and the
per-project commands written at onboarding.

Non-goals: judging output quality; a clarification gate that detects ambiguity, which nothing can do;
scored evaluation sets; any change to persona packs.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `scripts/completion-hook.sh` | the `Stop` entry in `hooks/hooks.json` | A-01 | Claude Code, at every turn end | DONE |
| `checks/<criterion-id>.sh` in the working repo | `bin/gate.sh criteria` and `verdict --run` | the session at PROPOSE, before work items exist | the gate, and the operator on a clean checkout | `criteria` exits 1 naming the criterion whose script is absent |
| `## Success criteria` table in a plan | `bin/gate.sh criteria` | PROPOSE | the gate | `criteria` exits 1 and no work items may be written |
| `## definition of done` block in `VAULT.md` holding `test_command`, `lint_command` and `delivery_command` | `bin/gate.sh config` at ANALYZE | `bin/vault-init.sh`, confirmed by the operator | the gate and the close report | `config` exits 1 at the first step and names each missing key |
| `bin/rule-count.sh` | D-01 and SC-6 | D-01 | the close report and CI | the corpus grows unmeasured, which is how it reached 173 rules |
| `vault/defect-ledger.md` | `bin/gate.sh recurrence` | the session that repairs a defect | the next session repairing the same class | recurrence has no denominator and reports UNRUN, never clear |
| `vault/check-budget.md` | `bin/gate.sh budget` | the operator, when a check fires wrongly | E-01 | a noisy check survives and the whole gate gets switched off instead |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| A-01 | `scripts/completion-hook.sh` | create | Write | a `Stop` hook that reads the session's plan, runs every committed check, and exits 2 with the failing check on stderr so it becomes the next instruction. No model call. Honours `stop_hook_active` so it cannot loop | SC-1 | `tests/unit/completion-hook.bats` | TODO |
| A-02 | `hooks/hooks.json` | modify | Edit | register A-01 on `Stop` beside the existing output-lint entry | SC-1 | same | DONE |
| A-03 | `tests/unit/completion-hook.bats` | create | Write | one case where a failing check blocks the stop, one where a passing set allows it, one asserting the hook cannot loop | SC-1 | `./tests/run.sh tests/unit/completion-hook.bats` | DONE |
| B-01 | `bin/gate.sh` | modify | Edit | `criteria` requires each row's `check` to name an existing executable file; an inline command string is refused | SC-2 | `tests/unit/gate.bats` | TODO |
| B-02 | `bin/gate.sh` | modify | Edit | `verdict --run` executes the named script, compares its exit code to `expect`, and writes the captured output into `evidence` itself | SC-2, SC-4 | same | TODO |
| B-03 | `templates/check.sh` | create | Write | the skeleton a criterion script starts from: exit 0 when met, 1 when not, and print what it observed | SC-2 | `bash -n templates/check.sh` | TODO |
| B-04 | `bin/gate.sh` | modify | Edit | `readers`: grep each identifier declared in `## Artifact lifecycles` across the repo, excluding comments and its declaring file; zero readers refuses | SC-2 | same | TODO |
| C-01 | `bin/gate.sh` | modify | Edit | `criteria` refuses a plan with no row of `kind: delivery`. A delivery row runs the real system and asserts this change appears in what the run produced. A repo with no runtime declares `no-runtime:` in frontmatter | SC-3 | same | TODO |
| C-02 | `templates/VAULT.md`, `bin/vault-init.sh`, `commands/v-init.md` | modify | Edit | onboarding resolves and writes `dod_profile`, `test_command`, `lint_command` and `delivery_command`; an unresolved command is written `absent: <reason>` and never omitted | SC-7 | `tests/integration/vault-init.bats` | TODO |
| C-03 | `bin/gate.sh` | modify | Edit | `config <repo>` refuses at ANALYZE when `VAULT.md` declares no such block | SC-7 | `tests/unit/gate.bats` | TODO |
| C-04 | `commands/v-work/steps/01-analyze.md`, `commands/v-team.md` | modify | Edit | call `gate.sh config` before Step 2 loads anything | SC-7 | `tests/unit/gate-wiring.bats` | TODO |
| D-01 | `bin/rule-count.sh` | create | Write | count rule-carrying lines and the prohibition-to-requirement ratio across the files a run reads; `--assert` fails above the recorded budget | SC-6 | `./bin/rule-count.sh` on this repo | TODO |
| D-02 | `commands/_shared/*.md`, `commands/v-work/steps/*.md`, `commands/v-team/steps/*.md` | modify | Edit | rewrite every surviving prohibition as a requirement. `Never git add -A` becomes `Stage each file by name` | SC-6 | `./bin/rule-count.sh --assert` | TODO |
| D-03 | same files | modify | Edit | delete every rule with no check behind it and record the count deleted. A rule kept without a check is listed in `vault/check-budget.md` as prose, and that list stays short | SC-6 | same | TODO |
| D-04 | `scripts/rule-inject-hook.sh`, `hooks/hooks.json` | create | Write | a `SessionStart` hook injecting the surviving requirements, which is what restores decayed compliance without retraining | SC-6 | `tests/unit/gate-hooks.bats` | TODO |
| E-01 | `bin/gate.sh`, `vault/check-budget.md` | create | Write | `budget`: each check records its fire count and its wrong-fire count; above one in ten it reports over budget and names the check | SC-5 | `tests/unit/gate-budget.bats` | TODO |
| E-02 | `vault/defect-ledger.md`, `bin/gate.sh` | create | Write | one row per defect class with its repair and the test that failed before it; `recurrence` refuses a repair naming no such test | SC-8 | `tests/unit/gate.bats` | TODO |
| E-03 | `bin/regression-count.sh` | create | Write | run the unit suite, count `^not ok`, and exit 1 above the number given | SC-9 | `./bin/regression-count.sh 4` | TODO |
| F-01 | `vault/decisions/ADR-026-mechanical-session-gates.md` | create | Write | the eight decisions above with the evidence each rests on | SC-6 | `bin/doc-lint.sh` on the file | TODO |
| F-02 | `install.sh`, `INSTALL.md` | modify | Edit | ship `bin/gate.sh`, `scripts/completion-hook.sh`, `bin/rule-count.sh` and the hook registrations | SC-7 | `tests/unit/install.bats` | TODO |
| F-03 | `vault-guide.md`, `vault/_moc.md`, `vault/decisions/_inventory.md` | modify | Edit | one section naming the gate and the delivery check; index ADR-026 and the two new vault surfaces | SC-6 | `bin/doc-lint.sh --changed` | TODO |

## Sequencing & dependencies

A-01 to A-03 run first and alone: the Stop hook is the highest-evidence mechanism here and it works
against the gate as it stands today. B repoints checks at committed scripts and lands before C,
because a delivery check living in a markdown cell carries the defect C exists to remove. D depends
on nothing and runs in parallel, except that D-03 deletes rules and follows D-01, which counts them.
E and F close the build.

## Rollback

`GATE=off` disables every check. To remove the machinery: revert the commits, delete `bin/gate.sh`,
`scripts/completion-hook.sh`, `bin/rule-count.sh` and `bin/regression-count.sh`, and drop the `Stop`
and `SessionStart` entries this plan adds to `hooks/hooks.json`. D-02 and D-03 rewrite and delete
prose, which `git revert` restores. Nothing in the lifecycle depends on a gate having run, and no
data or migration is involved.

## Test plan

`tests/unit/gate.bats` covers `bin/gate.sh` with one refusing and one passing fixture per subcommand.
`tests/unit/completion-hook.bats` covers the Stop hook against a blocked and an allowed turn end and
asserts it cannot loop. `tests/unit/gate-budget.bats` covers the false-positive budget.
`tests/unit/gate-wiring.bats` asserts each step file invokes the gate it owns.
`tests/integration/vault-init.bats` covers the onboarding keys. All run through `tests/run.sh`,
which executes in the container.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-01 | SC-1 | unit | `tests/unit/completion-hook.bats` | a failing check blocks the turn end with exit 2 | high | |
| T-02 | SC-1 | unit | `tests/unit/completion-hook.bats` | `stop_hook_active` prevents a second block on the same turn | high | |
| T-03 | SC-1 | unit | `tests/unit/completion-hook.bats` | the hook makes no model call and runs only the named scripts | high | |
| T-04 | SC-2 | unit | `tests/unit/gate.bats` | `criteria` refuses a `check` cell holding an inline command instead of a script path | high | |
| T-05 | SC-2 | unit | `tests/unit/gate.bats` | `criteria` refuses a script path that is absent or not executable | high | |
| T-06 | SC-3 | unit | `tests/unit/gate.bats` | `criteria` refuses a plan with no `kind: delivery` row and no `no-runtime:` | high | |
| T-07 | SC-2 | unit | `tests/unit/gate.bats` | `readers` refuses an identifier with no reader outside its declaring file | high | |
| T-08 | SC-5 | unit | `tests/unit/gate-budget.bats` | `budget` reports over budget at eleven wrong fires in a hundred and stays quiet at nine | high | |
| T-09 | SC-8 | unit | `tests/unit/gate.bats` | `recurrence` refuses a defect-ledger row whose repair names no failing-before test | high | |
| T-10 | SC-7 | unit | `tests/unit/gate.bats` | `config` refuses an omitted key and accepts `absent: <reason>` | high | |
| T-11 | SC-6 | unit | `tests/unit/gate.bats` | `rule-count.sh --assert` fails when prohibitions outnumber requirements | medium | |
| T-12 | SC-2 | unit | `tests/unit/gate.bats` | a table the parser cannot read exits 2, never 0 | high | |

## Refs

`vault/architecture/session-gates.md` — the gate contract this builds.
`vault/plans/2026-09-04-0900-mechanical-session-gates.brief.md` — the operator brief.
`commands/_shared/definition-of-done.md` — the baseline the profiles extend.
`~/workspace/animation-studio/vault/requirements/2026-09-04-vault-framework-defects-and-required-gates.md` — the defect register this answers. Outside this repo.
`~/workspace/animation-studio/vault/requirements/2026-09-04-every-feature-brings-a-fixture.md` — the same delivery rule applied to a video pipeline. Outside this repo.
