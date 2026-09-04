---
type: plan
project: vault
slug: rule-compliance-study
repos: [vault]
status: executed
process_record: 2026-09-04-1100-rule-compliance-study.trail.md
dod_profile: code
tags: [plan, research, measurement]
---

# rule-compliance-study — plan

## Task

Measure which framework rules sessions actually follow, and which property predicts it. Read-only
over 155 commits and 1,709 transcripts already on disk. The result decides whether the instruction
cut in `vault/plans/2026-09-04-0900-mechanical-session-gates.md` items D-02 and D-03 is worth doing,
and in what form. Keywords: compliance, rule, audit, transcript, prohibition, self-checkable.

## Open & deferred

| id | item | state |
|----|------|-------|
| S-1 | Two of ten rules came back UNSCORABLE: `do not auto-push` has no trace separating a sanctioned push from an unsanctioned one, and `use pnpm` has a denominator of 2 | ACCEPTED |
| S-5 | Eight scored rules cannot separate self-checkability from enforcement, because all three enforced rules were enforced from the day they were written. `vault/research/rule-compliance.md` states this rather than resolving it | OPEN |
| S-2 | `brevity-log.jsonl` was never created, so the one purpose-built compliance log on this machine holds nothing. The study works from git and transcripts only | ACCEPTED |
| S-3 | 155 commits is a small sample, and eight scored rules is smaller. A gap under roughly 20 points between two rules or two groups is not a finding here | ACCEPTED |
| S-4 | This study writes no framework change. It reports; the other plan acts | ACCEPTED |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN the audit runs over the real corpus THE SYSTEM SHALL print a compliance rate for every scorable rule and the literal word UNSCORABLE for the rest | delivery | command | `checks/rule-compliance-SC-1.sh` | exit 0 | MET | `checks/rule-compliance-SC-1.sh` exited 0 · 10 rules: every one carries a rate or UNSCORABLE with a reason |
| SC-2 | WHEN the audit is re-run THE SYSTEM SHALL print the same numbers | delivery | command | `checks/rule-compliance-SC-2.sh` | exit 0 | MET | `checks/rule-compliance-SC-2.sh` exited 0 · two runs over the cached corpus printed identical output |
| SC-3 | WHEN a rule's trace is a mention in prose rather than a real invocation THE SYSTEM SHALL exclude it | unit | command | `checks/rule-compliance-SC-3.sh` | exit 0 | MET | `checks/rule-compliance-SC-3.sh` exited 0 · rule-audit.bats: 12 cases, 0 failing |
| SC-4 | WHEN the study reports a rate THE SYSTEM SHALL name the command and the denominator that produced it | artifact | artifact | `vault/research/rule-compliance.md` | every rate carries its command and its denominator | MET | `vault/research/rule-compliance.md:42` · eight scored rates, each with its `n/d` and its command; two UNSCORABLE rows with reasons |

## Verified current state

| fact | how it was checked | date |
|---|---|---|
| Conventional commit format is followed on 144 of 155 commits; the 50-character subject limit on 28 of 155 | `bin/rule-audit.sh --rule R-01` and `--rule R-02` | 2026-09-04 |
| Both rules sit in one sentence at `commands/v-work/steps/05-commit-capture.md:57`, so file size, position and structure are held constant between them | read of the line | 2026-09-04 |
| The 50-character rate rose from 10.2% in June to 25.9% in September with no rewording of the rule | `bin/rule-audit.sh --rule R-02 --by-month` | 2026-09-04 |
| Raw grep over transcripts overcounts by roughly 18 to 1: `git add -A` appeared 74 times, of which 4 were real Bash invocations and the rest were the rule text being read | a JSON walk over `message.content` blocks, counting only `tool_use` entries named `Bash` | 2026-09-04 |
| 1,709 transcripts, 2.3 GB. Their assistant turns carry only 2026-08 and 2026-09 timestamps, so transcript rules have two monthly points, not five | a `jq` pass over `.timestamp` in every `~/.claude/projects/**/*.jsonl`, grouped by month | 2026-09-04 |

## Decisions

| decision | reason | record |
|---|---|---|
| A rule is scored only from a real invocation, never from a text match | raw grep overcounted 74 against a true 4 | local |
| A rule that cannot be scored reliably is reported UNSCORABLE | an unrun check must never read as a clean one | local |
| The study ships its measurement script | a number nobody can re-run is the claim this framework exists to stop | local |
| Rules are classified on three axes before their rates are compared | the framework already assumed grammar was the cause; the local pair shows file structure is not, and neither is settled | local |

## Scope & non-goals

Covers: scoring ten framework rules against git history and Claude Code transcripts, classifying
each on three properties, and reporting which property predicts compliance.

Non-goals: changing any rule; changing the framework; scoring rules whose trace is not mechanical;
claiming causation from an observational sample.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `bin/rule-audit.sh` | SC-1, SC-2, and every rate in the report | W-02 | the report, and anyone re-checking it | the study's numbers cannot be reproduced and the report is an opinion |
| `vault/research/rule-compliance.md` | items D-02 and D-03 of the gates plan, which are blocked on it | W-05 | the session that runs the instruction cut | D-02 and D-03 proceed on the papers alone, which already failed once against local data |
| `vault/research/rule-inventory.md` | `bin/rule-audit.sh` reads the rule list from it | W-01 | the audit script | the audit has no rules to score and exits 2 |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-01 | `vault/research/rule-inventory.md` | create | Write | ten rules with a mechanical trace. Per row: the rule, its exact source `file:line`, the trace to count, the denominator, and three classifications — `form` requirement or prohibition, `self_checkable` yes or no, `enforced` yes or no | SC-1 | `bin/rule-audit.sh --list` reads every row | DONE |
| W-02 | `bin/rule-audit.sh` | create | Write | read the inventory, score each rule, print `id rate numerator/denominator command`. Transcript rules count only `tool_use` blocks named `Bash`, never text. An unscorable rule prints UNSCORABLE with the reason | SC-1, SC-2 | `./bin/rule-audit.sh` on this repo | DONE |
| W-03 | `tests/unit/rule-audit.bats` | create | Write | one fixture transcript where the rule appears in prose and once as a real invocation; the audit counts one, not two. One case asserting an unscorable rule prints UNSCORABLE and does not print a rate | SC-3 | `./tests/run.sh tests/unit/rule-audit.bats` | DONE |
| W-04 | `bin/rule-audit.sh` | modify | Edit | `--by-month` groups each rule's rate by commit month, so a rate that moved without the rule being reworded is visible | SC-1 | same | DONE |
| W-05 | `vault/research/rule-compliance.md` | create | Write | the rates, then the three-axis comparison, then what it does and does not establish. Every rate carries its command and denominator. Where the sample is too small to separate two rules, say so | SC-4 | `bin/doc-lint.sh` on the file | DONE |
| W-06 | `vault/plans/2026-09-04-0900-mechanical-session-gates.md` | modify | Edit | record the finding against items D-02 and D-03, and unblock or redirect them | SC-4 | `bin/gate.sh criteria` on that plan | DONE |
| W-07 | `checks/rule-compliance-SC-1.sh`, `checks/rule-compliance-SC-2.sh`, `checks/rule-compliance-SC-3.sh` | create | Write | `bin/gate.sh` began refusing a criterion whose check is typed into the plan while this study was running. One script per criterion, prefixed with the plan slug because `checks/` is flat and the gates plan already owns `SC-1.sh` | SC-1, SC-2, SC-3 | `bin/gate.sh criteria` on this plan | DONE |

## Sequencing & dependencies

W-01 before W-02, because the audit reads the inventory. W-03 before the report, because a scoring
bug would put a wrong number into a document that then justifies deleting 173 rules. W-06 last, and
only after W-05 states what the numbers support.

## Rollback

Nothing to roll back. The study reads git and transcripts and writes three new files. Deleting them
restores the previous state exactly. No framework file changes until W-06, which edits one table row
in the gates plan.

## Test plan

`tests/unit/rule-audit.bats` covers the scoring logic against fixture transcripts written into a
temp directory: a prose mention that must not count, a real Bash invocation that must, and an
unscorable rule. It runs through `tests/run.sh`, which executes in the container.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-01 | SC-3 | unit | `tests/unit/rule-audit.bats` | a rule named in assistant prose is not counted as a violation | high | |
| T-02 | SC-3 | unit | `tests/unit/rule-audit.bats` | a real `tool_use` Bash block carrying the pattern is counted once | high | |
| T-03 | SC-3 | unit | `tests/unit/rule-audit.bats` | a rule with no trace prints UNSCORABLE and no rate | high | |
| T-04 | SC-2 | unit | `tests/unit/rule-audit.bats` | two runs over the same corpus print identical output | high | |
| T-05 | SC-1 | unit | `tests/unit/rule-audit.bats` | a malformed transcript line is skipped, and the run still exits 0 | medium | |

## Refs

`vault/plans/2026-09-04-0900-mechanical-session-gates.md` — items D-02 and D-03 are blocked on this study's result.
`commands/v-work/steps/05-commit-capture.md` — line 57 holds the two rules that differ by 74 points with everything else held constant.
`https://arxiv.org/abs/2605.10039` — the factorial study this questions: two TypeScript projects, five tasks, one trivial annotation.
`https://arxiv.org/abs/2604.20911` — the prohibition-decay finding, which this study can corroborate or fail to.
