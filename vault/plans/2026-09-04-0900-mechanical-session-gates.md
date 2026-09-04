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

Build `bin/gate.sh`, a single executable that refuses to let a `/v-*` session plan, approve or close
work whose questions, success criteria, definition of done or verification are missing. Wire it into
`/v-team`, `/v-work`, `/v-do`, `/v-pm` and the reporting half of `/v-cr`. The gate contract is
`vault/architecture/session-gates.md`. Keywords: gate, refusal, success criteria, definition of done,
verification, enforcement state.

## Open & deferred

| id | item | state |
|----|------|-------|
| O-2 | `/v-do` gains three gates and loses its "no ceremony" character. Scaled to a stub plan of three tables, which is the smallest form that still refuses | ACCEPTED |
| O-3 | The operator brief is printed to the terminal at up to 80 lines, above the 15-line cap in `commands/_shared/communication.md`. The operator asked for the architecture plan in the console | ACCEPTED |
| O-4 | `/v-cr` gets evidence-per-finding and enforcement states only. It reviews work it did not plan, so `criteria` and `verdict` have no source there | ACCEPTED |
| O-5 | Phases 2 to 6 run in later sessions. Phase 1 is done: `bin/gate.sh` refuses and passes, `criteria` and `verdict --run` are built and tested, and the gate ran against this plan | OPEN |
| O-6 | Seven of the nine criteria are not yet due, so this session proved SC-1, SC-6 and SC-8 only. `gate.sh verdict` prints which, and refuses the moment a covering work item flips to DONE | OPEN |
| O-7 | `verdict --run` executes commands written in a markdown file. It is opt-in, prints each command first, and must never run against a plan from an untrusted source | ACCEPTED |
| O-8 | A raw `\|` inside a `check` cell splits the row. Escape it as `\\|`; the parser restores it. `gate.sh` cannot tell an unescaped pipe from a column break | ACCEPTED |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a plan states its criteria THE SYSTEM SHALL pass it, and WHEN a plan states none THE SYSTEM SHALL refuse | e2e | command | `./bin/gate.sh criteria vault/plans/2026-09-04-0900-mechanical-session-gates.md && ! ./bin/gate.sh criteria vault/plans/2026-09-03-0929-enforce-brevity-mechanically.md` | exit 0 | MET | `./bin/gate.sh criteria vault/plans/2026-09-03-0929-enforce-brevity-mechanically.md` printed `no '## Success criteria' table` and exited 1; the same command on this plan exited 0 |
| SC-2 | WHEN a session runs `git commit` with a criterion unmet THE SYSTEM SHALL block the commit and name the criterion | e2e | command | `bash tests/unit/gate-hooks.bats` | exit 0 | | |
| SC-3 | WHEN each gate check meets a plan carrying its defect THE SYSTEM SHALL refuse, and WHEN it meets the fixed plan THE SYSTEM SHALL pass | unit | command | `./tests/run.sh tests/unit/gate.bats` | exit 0 | MET | `./tests/run.sh tests/unit/gate.bats` printed `ok 1` through `ok 32` with no `not ok` |
| SC-4 | WHEN `states` runs on this plan THE SYSTEM SHALL print a state and a named mechanism for every complaint in the defect report | artifact | artifact | `bin/gate.sh states` against this plan's `## Enforcement states` | 37 rows, none blank, none BOUND-UNREAD | | |
| SC-5 | WHEN `states` runs THE SYSTEM SHALL print an enforced count above the 13 the defect report recorded | e2e | command | `./bin/gate.sh states vault/plans/2026-09-04-0900-mechanical-session-gates.md` | exit 0, printing `ENFORCED n/37` with n above 13 | | |
| SC-6 | WHEN the existing unit suite runs THE SYSTEM SHALL fail no more tests than it failed before this work | unit | command | `bash -c 'n=$(./tests/run.sh tests/unit 2>&1 \| grep -c "^not ok" \|\| true); [ "$n" -le 4 ]'` | exit 0 | MET | `./tests/run.sh tests/unit` reported 521 tests with 4 failures, all pre-existing: `document-standard.bats:308`, `document-standard.bats:350`, `plugin-install.bats:106`, `research-clarify.bats:108` |
| SC-7 | WHEN the configuration gate runs on an onboarded repo THE SYSTEM SHALL pass it, and WHEN it runs on one never onboarded THE SYSTEM SHALL refuse | e2e | command | `./tests/run.sh tests/integration/vault-init.bats` | exit 0 | | |
| SC-9 | WHEN a `/v-*` command reaches a phase boundary THE SYSTEM SHALL invoke the gate for that phase | unit | command | `./tests/run.sh tests/unit/gate-wiring.bats` | exit 0 | | |
| SC-8 | WHEN a criterion carries a judgement no command can decide THE SYSTEM SHALL accept it with its failure condition and its no-detector reason | unit | command | `./bin/gate.sh criteria tests/fixtures/gate/observed-criterion.md` | exit 0 | MET | `./bin/gate.sh criteria tests/fixtures/gate/observed-criterion.md` exited 0 on a plan whose only criterion is `how: observed` |

## Research

| source | takeaway | how it changed this plan |
|---|---|---|
| `https://github.com/github/spec-kit` | phases with checkpoints between them, `[NEEDS CLARIFICATION]` markers in the spec, and checklists that validate requirement completeness | the `## Open questions` table is the same marker, made to refuse rather than to annotate |
| `https://kiro.dev/docs/specs/feature-specs/requirements-first/` | acceptance criteria in EARS notation, `WHEN <condition> THE SYSTEM SHALL <behaviour>`, written before design starts | the `criterion` cell adopts that shape |
| `https://arxiv.org/html/2507.11662` | agreement bias is pervasive; failure detection falls to roughly 50%, and binary pass-or-fail framing makes it worse | the verifier pastes the check output before it judges, and runs on a different model |
| `https://www.swebench.com/SWE-bench/guides/evaluation/` | the harness hides the tests, applies the patch in a container and re-runs them; pass or fail is mechanical and no model judges it | `gate.sh verdict --run` executes every runnable `check` itself; an agent judges only the rows a script cannot run |
| `https://arxiv.org/abs/2607.05904` | a policy optimised against its own judge drove judge-reported success from 0.72 to 0.94 while true accuracy stayed at 0.20 | the same change: the fewer verdicts a model produces, the less there is to game |
| `https://code.claude.com/docs/en/hooks` | a `PreToolUse` hook denies a tool call before the permission check and holds even when permission prompting is turned off; injected context does not | the close gate is a hook, not an instruction in a command file |
| `https://leopard-lab.github.io/paper/ase23-ConfTainter.pdf` | dead-code detectors find unused code paths; no mainstream tool detects a configuration key that nothing reads | `gate.sh bindings` has no off-the-shelf substitute and is built here |
| `https://proceedings.iclr.cc/paper_files/paper/2025/file/f3c5e56274140e0420baa3916c529210-Paper-Conference.pdf` | a model that produced an invalid step often fails to detect it | verification is a separate seat, never a self-review |
| `https://rgalen.com/agile-training-news/2016/11/8/definition-of-ready-as-an-anti-pattern` | a stringent readiness gate becomes a stage gate and items never qualify | the clarify gate blocks only on decision-changing questions |

## Verified current state

| fact | how it was checked | date |
|---|---|---|
| `bin/doc-lint.sh` is the only executable gate the lifecycle runs, and it checks document form, not session state | `wc -l bin/*.sh`, read of the usage header | 2026-09-04 |
| `commands/_shared/definition-of-done.md` exists with a six-line baseline and no profiles | read of the file | 2026-09-04 |
| `commands/_shared/elicitation.md` states that elicitation is not a gate and must not hold work | read of its "What this is not" section | 2026-09-04 |
| `hooks/hooks.json` registers SessionStart, PostToolUse, Stop and UserPromptSubmit, and no PreToolUse | read of the file | 2026-09-04 |
| `templates/plan.md` carries no success-criteria, open-questions or definition-of-done table | read of the file | 2026-09-04 |

## Decisions

| decision | reason | record |
|---|---|---|
| One executable, `bin/gate.sh`, with subcommands | a second script gets wired into one command and forgotten | ADR-026 |
| The plan artifact is the machine-readable session state | a separate state file drifts from the plan nobody updates | ADR-026 |
| A blocking question may never be answered by a default | the operator asked for a hard stop on decision-changing unknowns | ADR-026 |
| The blocking question must carry the vault paths already searched | an operator answering what the vault answered learns that answering is wasted | ADR-026 |
| A criterion may be decided by a command, an artifact check, or a named observation | not everything is a command, and a judgement dressed as a metric accepts the cases it should reject | ADR-026 |
| An observed criterion must name its disconfirming condition and why no detector exists | without both it closes on "it looked fine", and no detector ever gets built | ADR-026 |
| Onboarding writes every definition-of-done command, including the ones it cannot resolve | an omitted key makes the next session believe the question was settled | ADR-026 |
| At most four blocking questions per session | agents measurably repeat questions and ask what the prompt already answered; an uncapped gate becomes the checkpoint that stops work over small gaps | ADR-026 |
| The gate executes every runnable check itself; an agent judges only the rest | a verdict a script produced cannot be talked into existing, and a judge a model can optimise against reports success that is not there | ADR-026 |
| At least one success criterion must invoke the real system | components proven in isolation and never integrated is the defect that cost the most | ADR-026 |
| Verification is a separate agent that never sees the implementer's report | a verifier shown a claim confirms it | ADR-026 |
| `GATE=off` is whole-run only, with no per-check suppression | a gate silenced one check at a time gets silenced | ADR-026 |
| `elicitation.md` keeps its anti-stall rule for non-blocking questions | a stringent readiness gate is a documented anti-pattern: items never qualify and value stops shipping | ADR-026 |
| The verifier runs on a different model from the implementer and pastes output before judging | a model judging its own work agrees with it, and measured failure detection falls to about half | ADR-026 |
| A success criterion is written as `WHEN <trigger> THE SYSTEM SHALL <observable>` | a criterion with no trigger and no observable cannot be told apart from a preference | ADR-026 |

## Scope & non-goals

Covers: the gate executable, its wiring into five commands, the plan template, the two
definition-of-done profiles, the verification contract, the operator brief, the cross-plan tracker
and the defect ledger.

Non-goals: scored evaluation sets for rules that cannot become gates; any change to persona packs;
any change to `/v-capture` beyond the tracker reconciliation.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `bin/gate.sh` | every close path in `commands/v-work/steps/05-commit-capture.md` §5.0 | this plan | the five `/v-*` commands and `scripts/gate-hook.sh` | the step reports the gate unavailable and stops; it never proceeds unchecked |
| `## Success criteria` table in a plan | `bin/gate.sh criteria` and `bin/gate.sh verdict` | PROPOSE | the verification agent | `criteria` exits 1 naming the empty table; PROPOSE cannot write work items |
| `## Open questions` table in a plan | `bin/gate.sh clarify` | ANALYZE and PROPOSE | the operator at the clarify stop | `clarify` exits 1 naming the row with the empty `searched` cell |
| `## Enforcement states` table in a plan | `bin/gate.sh states` | EXECUTE | the close report | `states` exits 1; the close report cannot print its ENFORCED count |
| `## definition of done` block in `VAULT.md` (`dod_profile`, `test_command`, `lint_command`, `duplication_command`, `e2e_command`, `interface_doc_path`) | `bin/gate.sh config` at ANALYZE and `bin/gate.sh dod` at close | `bin/vault-init.sh`, confirmed by the operator | both gates, and the close report | `config` exits 1 at the start of the session and names every missing key; the session does not begin |
| `scripts/gate-hook.sh` | `hooks/hooks.json` PreToolUse matcher on `git commit` | this plan | Claude Code | the commit is not blocked; the close gate becomes advisory, which is the failure this plan exists to prevent |
| `vault/_open.md` | `bin/gate.sh tracker` and `/v-capture` | EXECUTE and capture | the next session | `tracker` exits 1 naming the plan whose open rows are absent |
| `vault/defect-ledger.md` | the regression-test rule in `definition-of-done.md` | the session that repairs a defect | the next session repairing the same class | the recurrence measurement has no denominator and reports UNRUN, never clear |
| `plans/<slug>.brief.md` | the approval gate in all five commands | PROPOSE | the operator, in the terminal | the gate prints the 15-line decision block alone and says the brief is missing |
| `commands/_shared/verification.md` | `v-team/steps/04-execute-loop.md` §5.3a | this plan | the verification agent | EXECUTE cannot spawn the verifier and the close gate refuses on empty verdicts |

## Work items

Phase 1 is the end-to-end spine and closes this session. Phases 2 to 6 are the multi-session tail
and each row carries its own status.

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-01 | `bin/gate.sh` | create | Write | subcommand dispatch, markdown-table parser, `GATE=off`, exit 0/1/2, usage header naming every check | SC-1 | `bash -n bin/gate.sh` and `bin/gate.sh --help` | DONE |
| W-02 | `bin/gate.sh` | modify | Edit | implement `criteria`: refuse empty table, empty `check`/`expect`, a `check` with no backtick or path, and zero `kind: e2e` rows without a frontmatter `no-runtime:` | SC-1 | `tests/unit/gate.bats` criteria cases | DONE |
| W-02b | `bin/gate.sh` | modify | Edit | `criteria` warns, and does not refuse, when a `criterion` cell carries no `WHEN`/`SHALL` pair — the shape is guidance until the corpus uses it | SC-1 | `tests/unit/gate.bats` shape case | DONE |
| W-02c | `bin/gate.sh` | modify | Edit | `criteria` accepts three `how` values. `command` and `artifact` are decided by the gate. `observed` is refused unless the row names its disconfirming condition and a `no-command: <reason>` | SC-8 | `tests/unit/gate.bats` observed cases | DONE |
| W-03 | `bin/gate.sh` | modify | Edit | implement `verdict`: refuse a non-`MET` verdict, a `MET` row with empty evidence, and evidence with no backticked command or `path:line` | SC-1 | `tests/unit/gate.bats` verdict cases | DONE |
| W-03b | `bin/gate.sh` | modify | Edit | implement `verdict --run`: execute each `check` cell that is a command, compare its exit code to `expect`, write the output into `evidence`, and refuse on disagreement. A check that cannot be executed is left to the agent verifier and marked so | SC-1 | `tests/unit/gate.bats` run-mode cases | DONE |
| W-04 | `templates/plan.md` | modify | Edit | add `## Open questions`, `## Success criteria`, `## Definition of done`, `## Enforcement states`; make `## Decisions` a table with a `record` column; add `covers` to work items | SC-9 | `bin/doc-lint.sh templates/plan.md` | DONE |
| W-05 | `commands/v-work/steps/03-propose.md` | modify | Edit | §3a.0a calls `gate.sh clarify`; a new §3a.4a calls `gate.sh criteria` before work items are written; a nonzero exit stops the step | SC-9 | `tests/unit/gate-wiring.bats` greps for both invocations | DONE |
| W-06 | `commands/v-work/steps/05-commit-capture.md` | modify | Edit | §5.0 calls `gate.sh all <plan> --phase close` before staging; a nonzero exit stops the close | SC-9 | same test file | DONE |
| W-07 | `tests/unit/gate.bats` | create | Write | one refuse case and one pass case per implemented subcommand, each with its own fixture | SC-3, SC-6 | `tests/run.sh unit` | DONE |
| W-08 | `tests/fixtures/gate/observed-criterion.md` | create | Write | the committed fixture for a judgement no command can decide. The defect fixtures are generated inside `tests/unit/gate.bats` by `mkplan` instead, so each defect sits beside the assertion about it | SC-3 | `bin/gate.sh criteria tests/fixtures/gate/observed-criterion.md` | DONE |
| W-09 | `vault/plans/2026-09-04-0900-mechanical-session-gates.md` | modify | Edit | run the full close phase against this plan and record every verdict with its evidence | SC-1 | `bin/gate.sh all` on this file exits 0 | DONE |
| W-10 | `bin/gate.sh` | modify | Edit | implement `clarify` per the schema in `vault/architecture/session-gates.md`, including the four-row cap on `blocks: yes` questions | SC-3 | `tests/unit/gate.bats` clarify cases | TODO |
| W-11 | `bin/gate.sh` | modify | Edit | implement `coverage`: every criterion id appears in a work-item `covers` cell | SC-3 | same | TODO |
| W-12 | `bin/gate.sh` | modify | Edit | implement `dod`: refuse a state that is not `met`, `failed` or `absent: <reason>`, and refuse any `failed` | SC-3 | same | TODO |
| W-13 | `bin/gate.sh` | modify | Edit | implement `decisions`: refuse a `record` cell that is neither a repo-relative path nor `local` | SC-3 | same | TODO |
| W-14 | `bin/gate.sh` | modify | Edit | implement `bindings`: grep each backticked identifier in `## Artifact lifecycles` across the repo, excluding comment lines and the declaring file; zero readers refuses | SC-3 | same | TODO |
| W-15 | `bin/gate.sh` | modify | Edit | implement `states`: print `ENFORCED n/total`, count `observed` criteria separately so the fraction says how much a script can decide, and refuse any `BOUND-UNREAD` row | SC-4, SC-5 | same | TODO |
| W-16 | `bin/gate.sh` | modify | Edit | implement `tracker`: refuse when a `proposed` or `approved` plan has open rows absent from `vault/_open.md` | SC-3 | same | TODO |
| W-16b | `bin/gate.sh` | modify | Edit | implement `config <repo>`: refuse when `VAULT.md` declares no `dod_profile`, or a profile line has neither a command nor an `absent: <reason>` | SC-7 | `tests/unit/gate.bats` config cases | TODO |
| W-16c | `commands/v-work/steps/01-analyze.md`, `commands/v-team.md` | modify | Edit | call `gate.sh config` at ANALYZE, before Step 2 loads anything; a nonzero exit stops the session and names the missing keys | SC-7 | `tests/unit/gate-wiring.bats` | TODO |
| W-17 | `commands/_shared/definition-of-done.md` | modify | Edit | add the `code` and `ai-instructions` profiles with their refused-evidence lists; add the regression-test rule pointing at `vault/defect-ledger.md`. Each profile line names the `VAULT.md` key holding its command | SC-7 | `bin/doc-lint.sh` on the file | TODO |
| W-17b | `templates/VAULT.md` | modify | Edit | add a `## definition of done` section: `dod_profile`, `test_command`, `lint_command`, `duplication_command`, `e2e_command`, `interface_doc_path`. Every key is present, holding a command or `absent: <reason>` | SC-7 | `bin/gate.sh config` on a repo built from the template | TODO |
| W-17c | `bin/vault-init.sh` | modify | Edit | after scaffolding, resolve each command from `scripts/detect-stack.sh`, present them for confirmation, and write the block. An unresolved command is written as `absent: <reason>`, never omitted | SC-7 | `tests/integration/vault-init.bats` | TODO |
| W-17d | `commands/v-init.md` | modify | Edit | document the new step in "What it does" and name the keys it writes | SC-7 | `bin/doc-lint.sh` on the file | TODO |
| W-18 | `commands/_shared/verification.md` | create | Write | the verifier receives criteria, diff and repo, never the implementer's report; runs on a different model; pastes each `check` output before judging; names what would have made the row `NOT MET`; two loops then escalate | SC-9 | `bin/doc-lint.sh` on the file | TODO |
| W-19 | `commands/_shared/elicitation.md` | modify | Edit | the anti-stall rule survives for non-blocking questions; a `blocks: yes` question may never be defaulted and routes to the operator | SC-9 | `bin/doc-lint.sh` on the file | TODO |
| W-20 | `templates/plan-stub.md` | create | Write | the three-table plan `/v-do` writes | SC-9 | `bin/doc-lint.sh` on the file | TODO |
| W-21 | `commands/v-team/steps/03-propose-loop.md` | modify | Edit | call `clarify`, `criteria` and `coverage` at the same points `/v-work` does | SC-9 | `tests/unit/gate-wiring.bats` | TODO |
| W-22 | `commands/v-team/steps/04-execute-loop.md` | modify | Edit | new §5.3a spawns the verifier per `commands/_shared/verification.md` and writes verdicts back | SC-9 | same | TODO |
| W-23 | `commands/v-do.md` | modify | Edit | write the stub plan, run `criteria` before editing and `verdict` plus `dod` before committing | SC-9 | same | TODO |
| W-24 | `commands/v-pm/steps/01-intake.md` | modify | Edit | `requirements.md` carries the `## Success criteria` table and `gate.sh criteria` runs on it | SC-9 | same | TODO |
| W-25 | `commands/v-cr/steps/03-review.md` | modify | Edit | every finding carries the command that produced it; a finding without one is advisory | SC-9 | same | TODO |
| W-26 | `templates/brief.md` | create | Write | architecture and success criteria only, 80 lines maximum | SC-9 | `bin/doc-lint.sh --class contract templates/brief.md` | TODO |
| W-27 | `bin/doc-lint.sh` | modify | Edit | add type `brief` with cap 80 to `cap_for_type` and `singularize_type` | SC-9 | `bin/doc-lint.sh --list-caps` shows it | TODO |
| W-28 | `vault/_open.md` | create | Write | one row per open item across all plans: id, what, plan, state, what would close it | SC-3 | `bin/gate.sh tracker vault` | TODO |
| W-29 | `vault/defect-ledger.md` | create | Write | one row per defect class: id, what, repair, regression-test path, recurrence count | SC-4 | referenced by `definition-of-done.md` | TODO |
| W-30 | `scripts/gate-hook.sh` | create | Write | PreToolUse hook matching `git commit`; runs the close phase against the session's plan; blocks on exit 1 | SC-2 | `tests/unit/gate-hooks.bats` | TODO |
| W-31 | `hooks/hooks.json` | modify | Edit | register the PreToolUse matcher; SessionStart also injects the numbers table from `commands/_shared/communication.md` | SC-2 | same | TODO |
| W-32 | `vault/decisions/ADR-026-mechanical-session-gates.md` | create | Write | the eight decisions above, with the rejected alternatives | SC-4 | `bin/doc-lint.sh` on the file | TODO |
| W-33 | `vault-guide.md` | modify | Edit | one section naming `bin/gate.sh`, `dod_profile` and the refusal contract | SC-4 | `bin/doc-lint.sh vault-guide.md` | TODO |
| W-34 | `install.sh` | modify | Edit | ship `bin/gate.sh`, `scripts/gate-hook.sh` and the PreToolUse registration | SC-7 | `tests/unit/install.bats` | TODO |
| W-35 | `vault/_moc.md`, `vault/decisions/_inventory.md` | modify | Edit | index the new architecture doc, ADR-026 and the two new vault surfaces | SC-4 | `bin/doc-lint.sh --changed` | TODO |

## Sequencing & dependencies

W-01 through W-09 are phase 1 and run in order; W-09 is the real run that proves the spine and
cannot start before W-07 is green. W-10 to W-16 extend the same executable and may run in any order
after W-01. W-17 to W-20 are contract documents and gate nothing until W-21 to W-25 wire them.
W-30 and W-31 depend on W-06, because the hook runs the same close phase the step runs. W-32 to W-35
close the multi-session build.

## Rollback

`GATE=off` in the environment disables every check without touching a file. To remove the machinery:
revert the commit, delete `bin/gate.sh` and `scripts/gate-hook.sh`, and drop the PreToolUse entry
from `hooks/hooks.json`. Nothing in the framework depends on a gate having run, so removal leaves the
lifecycle exactly as it is today. No migration and no data change is involved.

## Test plan

`tests/unit/gate.bats` covers `bin/gate.sh`: one refusing fixture and one passing fixture per
subcommand, asserting the exit code and the named missing thing. `tests/unit/gate-wiring.bats`
asserts each command step file invokes the gate it is supposed to. `tests/unit/gate-hooks.bats`
covers `scripts/gate-hook.sh` against a blocked and an allowed commit. All three live under
`tests/unit/` and run through `tests/run.sh unit`, which executes in the container.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-01 | SC-3 | unit | `tests/unit/gate.bats` | `criteria` exits 1 on an empty success-criteria table | high | |
| T-02 | SC-3 | unit | `tests/unit/gate.bats` | `criteria` exits 1 when no row has `kind: e2e` and no `no-runtime:` is declared | high | |
| T-03 | SC-3 | unit | `tests/unit/gate.bats` | `criteria` exits 0 when a `no-runtime:` reason is present and no e2e row exists | high | |
| T-04 | SC-3 | unit | `tests/unit/gate.bats` | `verdict` exits 1 on a `MET` row with empty evidence | high | |
| T-05 | SC-3 | unit | `tests/unit/gate.bats` | `verdict` exits 1 on evidence carrying prose with no command or `path:line` | high | |
| T-05b | SC-3 | unit | `tests/unit/gate.bats` | `verdict --run` exits 1 when a check's real exit code contradicts a `MET` verdict written into the plan | high | |
| T-07b | SC-3 | unit | `tests/unit/gate.bats` | `clarify` exits 1 on a fifth `blocks: yes` row | medium | |
| T-06 | SC-3 | unit | `tests/unit/gate.bats` | `clarify` exits 1 on a `blocks: yes` row with an empty `searched` cell | high | |
| T-07 | SC-3 | unit | `tests/unit/gate.bats` | `clarify` exits 1 on a `blocks: yes` row marked `defaulted` | high | |
| T-08 | SC-3 | unit | `tests/unit/gate.bats` | `bindings` exits 1 on an identifier with no reader outside its declaring file | high | |
| T-09 | SC-3 | unit | `tests/unit/gate.bats` | `states` exits 1 on a `BOUND-UNREAD` row and prints the ENFORCED fraction | high | |
| T-10 | SC-3 | unit | `tests/unit/gate.bats` | `GATE=off` exits 0 on every fixture that otherwise refuses | high | |
| T-11 | SC-3 | unit | `tests/unit/gate.bats` | a malformed table exits 2, not 0 — a parser that cannot read the plan must not pass it | high | |
| T-11b | SC-8 | unit | `tests/unit/gate.bats` | `criteria` exits 1 on an `observed` row with no disconfirming condition | high | |
| T-11c | SC-8 | unit | `tests/unit/gate.bats` | `criteria` exits 1 on an `observed` row with no `no-command:` reason | high | |
| T-11d | SC-7 | unit | `tests/unit/gate.bats` | `config` exits 1 when a done-line key is omitted, and exits 0 when it reads `absent: <reason>` | high | |
| T-11e | SC-7 | integration | `tests/integration/vault-init.bats` | a freshly initialised repo's `VAULT.md` carries every done-line key | high | |
| T-12 | SC-2 | unit | `tests/unit/gate-hooks.bats` | `scripts/gate-hook.sh` blocks a `git commit` when the close phase exits 1 | high | |
| T-13 | SC-1 | unit | `tests/unit/gate-wiring.bats` | each of the five command step files invokes the gate subcommand it owns | medium | |

## Refs

`vault/architecture/session-gates.md` — the gate contract this plan builds.
`~/workspace/animation-studio/vault/requirements/2026-09-04-vault-framework-defects-and-required-gates.md` — the defect register whose 37 rows are the acceptance list. Outside this repo; its rows are copied into `## Enforcement states` at W-15.
`commands/_shared/definition-of-done.md` — the baseline the two profiles extend.
`commands/_shared/elicitation.md` — the anti-stall rule the clarify gate must not break.
