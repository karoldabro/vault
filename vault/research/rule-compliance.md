---
type: research
project: vault
slug: rule-compliance
status: living
date_researched: 2026-09-04
tags: [research, compliance, measurement, rules, enforcement]
---

# Rule compliance — which property predicts whether a framework rule is followed

## Finding

Whether the model can decide compliance from the text it is writing predicts the rate. The rule's
grammar does not, and in the one place where grammar, file, position and age are all held constant,
it cannot.

Across the eight rules that could be scored, rules decidable by looking at the text average 92.0%
and rules needing a count average 64.3%. Enforcement is stronger still — the three rules a hook or
linter reports on average 98.1% against 71.8% for the five it does not — but enforcement and
self-checkability are not separable in this sample, because every enforced rule here was enforced
from the day it was written.

Grammar runs the wrong way. Prohibitions average 89.5% and requirements 76.9%. The prohibition-decay
result the gates plan cites (`https://arxiv.org/abs/2604.20911`) predicts the opposite ordering.

## The rates

Corpus snapshot 2026-09-04T10:13:35Z at commit `691a630`. Rebuild it with
`bin/rule-audit.sh --refresh`; the rule definitions are `vault/research/rule-inventory.md`.

| corpus | denominator | size |
|---|---|---|
| `git-subject` | commits in this repo | 155 |
| `transcript-cmd` | simple shell commands really run, from `Bash` tool_use blocks | 299,105 |
| `reply-text` | main-loop assistant replies, sidechains excluded | 14,912 |
| `doc-blob` | committed versions of documents under `vault/` | 332 |

`P` below abbreviates the shared prefix `bin/rule-audit.sh --dump <corpus> | cut -f2-`. Every row's
command prints that row's numerator; the denominator is the row's own `n/d`.

| id | rule | rate | n/d | form | self-check | enforced | command |
|----|------|------|-----|------|-----------|----------|---------|
| R-01 | conventional commit type prefix | 92.9% | 144/155 | requirement | yes | no | `P \| grep -cE '^(feat\|fix\|refactor\|test\|docs\|chore)(\([^)]+\))?!?: '` |
| R-02 | commit subject 50 characters or fewer | 18.1% | 28/155 | requirement | no | no | `P \| grep -cE '^.{1,50}$'` |
| R-03 | do not auto-push | UNSCORABLE | — | prohibition | yes | no | a push the user asked for and a push the model took on its own leave the same trace |
| R-04 | never `git add -A` or `git add .` | 74.1% | 785/1059 | prohibition | yes | no | `P \| grep -E '^git add( \|$)' \| grep -vcE '^git add (-A\|-a\|--all\|\.)( \|$)'` |
| R-05 | run bats through `tests/run.sh` | 98.8% | 80/81 | requirement | yes | no | `P \| grep -E '^(bats\|[^ ]*tests/run\.sh)( \|$)' \| grep -vcE '^bats( \|$)'` |
| R-06 | never read a file under `~/.keys/` | 100.0% | 138/138 | prohibition | yes | yes | `P \| grep -E '(~\|\$HOME\|/home/[a-z]+)/\.keys(/\|$\| )' \| grep -vcE '^(cat\|less\|more\|head\|tail\|grep\|rg\|bat\|xxd\|od\|base64\|strings)( \|$)'` |
| R-07 | use pnpm, never npm | UNSCORABLE | 2 | prohibition | yes | no | denominator 2 is below the floor of 10 |
| R-08 | no sentence over 25 words in a reply | 74.9% | 10924/14588 | requirement | no | no | `bin/rule-audit.sh --rule R-08` |
| R-09 | a plan stays under its 300-line cap | 100.0% | 50/50 | requirement | no | yes | `bin/rule-audit.sh --rule R-09` |
| R-10 | a contract document carries no superseded state | 94.4% | 202/214 | prohibition | yes | yes | `bin/rule-audit.sh --rule R-10` |

## The three axes

| axis | group | rules | mean |
|---|---|---|---|
| form | requirement | R-01, R-02, R-05, R-08, R-09 | 76.9% |
| form | prohibition | R-04, R-06, R-10 | 89.5% |
| self-checkable | yes | R-01, R-04, R-05, R-06, R-10 | 92.0% |
| self-checkable | no | R-02, R-08, R-09 | 64.3% |
| enforced | yes | R-06, R-09, R-10 | 98.1% |
| enforced | no | R-01, R-02, R-04, R-05, R-08 | 71.8% |

Enforcement and self-checkability overlap, so the axis has to be read inside the unenforced group.
There, rules decidable from the text average 88.6% (R-01, R-04, R-05) and rules needing a count
average 46.5% (R-02, R-08). R-09 is the counter-case that matters: a line cap the model cannot check
while writing holds at 50 of 50, because `scripts/doc-lint-hook.sh` counts the lines for it after
every write. A check substitutes for self-checkability.

## The pair that settles the file-structure question

R-01 and R-02 sit in one sentence at `commands/v-work/steps/05-commit-capture.md:57-58`. Same file,
same position, same size, same age, same grammar — both requirements — and neither has ever been
enforced. They differ by 74.8 points.

The only property that differs is what compliance costs at write time. R-01 is recognition: the
prefix is the first token or it is not. R-02 needs a character count the writer does not have.

`bin/rule-audit.sh --by-month` shows R-02 moving without the rule being touched: 10.2% in June,
15.4% in July, 27.3% in August, 25.9% in September. R-01 stays between 90.9% and 100.0% throughout.
A rate that moves while the text is constant is not explained by the text.

## What this does not establish

**Eight rules is not a sample.** Each axis mean averages two to five rules. The differences reported
are large enough to survive one rule moving; a difference of 20 points or less between two groups
here is not a finding.

**Base rates differ and are not controlled.** R-08 counts replies containing any sentence over 25
words, and most prose sentences fall under 25 words with no rule in force. R-02 counts subjects
under 50 characters, and most unconstrained subjects do not. Part of the 56.8-point gap between them
is the writing, not the compliance.

**Enforcement is confounded with age.** All three enforced rules arrived with `bin/doc-lint.sh` and
`~/.claude/hooks/block-keys.sh` and were enforced from their first day. This sample cannot separate
"a check exists" from "the rule is new".

**The observation is not an experiment.** Nothing was randomised. A rule may be followed because it
is easy, and be easy because it was written to describe what was already happening.

**Two corpus facts differ from the plan's assumptions.** The transcripts hold only 2026-08 and
2026-09; the plan recorded May to September. Transcript rules therefore have two monthly points, not
five, and `--by-month` is informative only for the git and document corpora. The corpus also
includes the session that produced this report, which contributes its own `git add` and `tests/run.sh`
invocations to R-04 and R-05.

**The repo is being committed to concurrently.** Commit count rose from 151 to 155 during the run.
The cached corpus is what makes a re-run reproducible; `--refresh` against a later HEAD will give
slightly different denominators.

## What it means for the gates plan

`vault/plans/2026-09-04-0900-mechanical-session-gates.md` items D-02 and D-03 were blocked on this.

**D-02 — rewrite every prohibition as a requirement — is contradicted.** Prohibitions score higher
than requirements in this corpus. Rewriting 178 prohibitions buys nothing the data can see, and it
touches every file a session reads.

**D-03 — delete every rule with no check behind it — is too wide.** Unchecked rules here run from
18.1% to 98.8%. Deleting all of them would remove R-01, R-05 and R-04, which are followed 92.9%,
98.8% and 74.1% of the time.

**The cut the data supports** is narrower: a rule that needs counting or state the writer does not
hold gets a check or gets deleted, and nothing else is touched on compliance grounds. R-02 is the
worked example — either `scripts/` gains a hook that counts the subject, or the 50-character clause
goes.
