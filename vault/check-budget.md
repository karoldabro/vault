---
type: process
project: vault
slug: check-budget
status: current
tags: [gates, measurement]
---

# Check budget — how often each gate check is wrong

**A check that fires wrongly more than one time in ten is fixed or deleted.** `bin/gate.sh budget`
reads this file and refuses above that line.

The number is not tidiness. Google launches a Tricorder analyzer only below a 10% false-positive
rate and disables one that climbs above it; their whole platform runs under 5%. A check people stop
trusting is not ignored selectively — it is switched off wholesale, and every other check goes with
it. `GATE=off` is this framework's version of that switch, so one noisy check costs all of them.

## How a row gets updated

Add one to `fires` each time the check refuses. Add one to `wrong` when the thing it refused is
correct in the working system: the check matched the text and misread the state. Only the operator
sets `wrong`; a session never scores its own refusal.

## Check budget

| check | fires | wrong | note |
|-------|-------|-------|------|
| criteria | 0 | 0 | |
| coverage | 0 | 0 | `cmd_coverage`; refuses only on a criterion no work item's `covers` cell names |
| verdict | 0 | 0 | |
| readers | 0 | 0 | |
| config | 0 | 0 | |
| budget | 0 | 0 | |
| recurrence | 0 | 0 | |
| arch | 0 | 0 | `cmd_arch`; the contract is `commands/_shared/architecture-spec.md` |
| human | 0 | 0 | `cmd_human`; the contract is `commands/_shared/human-plan.md` |
| master | 0 | 0 | `cmd_master`; refuses a dependency with no contract row and a session that consumes an unproduced contract; the contract is `templates/master-plan.md` |
| completion-hook | 0 | 0 | |
| staging-hook | 0 | 0 | |
| rule-coverage | 0 | 0 | `cr_rule_coverage`; refuses only on a routed rule nobody decided |
| anchor-check | 0 | 0 | `cr_anchor_check`; refuses a citation whose token is not on the line it names |
| v-method-SC-3 | 0 | 0 | the routing table: a blank cell, a shifted row, under eight rows, or a judgement-shaped property |
| v-method-SC-4 | 0 | 0 | prohibitions outnumbering requirements in either `/v-method` file |
| v-method-SC-5 | 0 | 0 | a `/v-method` file restating a rule `lib/shared-module-rules.tsv` lists |
| plugin-manifest | 0 | 0 | `cmd_add`; refuses a directory with no `extend/plugin.tsv` |
| plugin-point-file | 0 | 0 | `cmd_add`; refuses a declared point whose file is absent or not executable |
| plugin-point-unknown | 0 | 0 | `vault_plugin_check_points`; refuses a point this framework does not implement |
| plugin-symlink | 0 | 0 | `assert_no_symlink`; refuses a path that resolves through a symlink |
| plugin-duplicate-name | 0 | 0 | `vault_plugin_list`; refuses a registry holding two rows with one name |
| plugins-two-lines | 0 | 0 | `plugin_keys`; refuses a `VAULT.md` carrying more than one `plugins:` line |
| plugin-dod-key | 0 | 0 | `plugin_keys`; refuses a key a listed plugin declares and the repo omits |
| handoff-SC-1 | 0 | 0 | refuses `/v-handoff` missing a core section, a mode, a refusal, or a template that puts an optional section above a core one |
| handoff-SC-2 | 0 | 0 | refuses `/v-report` missing a field or a mode, and a report template naming the finder in its body |
| handoff-SC-3 | 0 | 0 | refuses when the context load, the vault scaffold, a `vault-guide.md` section, the README or this file does not name both commands |
| handoff-SC-4 | 0 | 0 | refuses a `handoff` or `report` type unregistered in `cap_for_type`, `is_known_type`, `is_document_folder`, `singularize_type` or `--list-caps` |

## How a guard row is counted

The seven `plugin-*` and `plugins-*` rows above are incremented by the refusing function itself, not
by the operator. Every other row here follows the rule at the top of this file, where a session
observes the refusal and the operator judges it. These refuse inside `bin/vault-plugin.sh` and
`bin/gate.sh config`, which a plugin author runs directly, so nobody is watching to score them.

**Until that counter is written, these rows stay at zero and the one-in-ten rule does not reach
them.** A row that cannot move is a row nobody can act on.

## What the checks do not cover

`checks/v-loop-SC-3.sh` and `checks/v-method-SC-5.sh` match the shared modules' literal wording,
from the list in `lib/shared-module-rules.tsv`. A rule reworded rather than copied passes both, so a
green run means no verbatim duplicate rather than no duplicate.

No check reads a written method file. `/v-method`'s rules about what every stage row carries — the
command, the seats, the tools, the exit evidence and a kill criterion naming its field — are prose
until a method file exists to read. `checks/v-method-SC-1.sh` only confirms the command states them.

`cr_rule_coverage` measures the rules a changed-file glob could reach. Two buckets are outside it and
are printed rather than counted as clean: `no-match`, a rule whose globs reached nothing in this diff,
and `unroutable`, a rule whose index cell is prose no router can read. A rule about a contract between
files or repos names no changed path and lands in one of them on every diff: 42 of 44 rows
(`bin/indication-route-audit.sh ~/vault/givore/indications/cross-repo/_index.md`). Nobody verdicts
those rules, and a summary that folds them into a coverage number reports thoroughness it did not
have.

`bin/rule-count.sh` counts the `/v-team` corpus. The campaign files — `commands/v-loop.md`, its rules
file, the adapter contract and every adapter — are counted apart, by `checks/v-loop-SC-4.sh`, because
a campaign is a separate read set: no session loads both, and a session loads one adapter rather than
all of them.
Counting them together would raise a budget that is already over, which hides the overrun instead of
recording it.

## The /v-loop gates

Counted here because the budget tracks what a session pays for, and these run on every campaign
change. Six existed and went unregistered; the seventh ships with the engine/adapter split.

| check | what it refuses | why it is not prose |
|-------|-----------------|---------------------|
| `checks/v-loop-SC-1.sh` | an engine missing either refusal, the intake, a cap, resume, the envelope, or its adapters — and any task vocabulary leaking back into it | 34 assertions over one file, all greppable |
| `checks/v-loop-SC-2.sh` | a shipped campaign file that fails `bin/doc-lint.sh` | the linter already exists |
| `checks/v-loop-SC-3.sh` | a rule restated from a `commands/_shared/` module, across the engine, the contract and every adapter; and an adapter deferring to nothing | patterns live in `lib/shared-module-rules.tsv`, shared with `checks/v-method-SC-5.sh` |
| `checks/v-loop-SC-4.sh` | prohibitions outnumbering requirements in any of the five prose files | same grammar as `bin/rule-count.sh` |
| `checks/v-loop-SC-5.sh` | a safety rule that survives nowhere after its move to an adapter | searches the whole read set, so a rule that moved still counts |
| `checks/v-loop-SC-6.sh` | a staging guard that denies one verb of an action and not its siblings | wraps `tests/unit/staging-hook.bats` |
| `checks/v-loop-adapter-slots.sh` | fewer than two adapters, an adapter missing any of the six slots, a slot filled with nothing, and two adapters verifying the same way | the slot headings are the contract, so reading them back is exact |

`checks/v-loop-SC-3.sh` and `checks/v-method-SC-5.sh` match the shared modules' literal wording, so a
rule reworded rather than copied passes both.

## Rules kept as prose

Rules with no check behind them. This list stays short: every entry is a rule the framework asks a
session to remember, and compliance falls as that count rises.

| rule | where | why no check |
|------|-------|--------------|
| read the communication contract before writing output | `commands/_shared/communication.md` | no hook fires before a model writes prose; `bin/output-lint.sh` measures the reply afterwards instead |
| a criterion decided by observation | `vault/architecture/session-gates.md` | no artifact carries the signal; the operator decides it against the failing condition the row names |
| leave pushing to the operator | `commands/v-work/steps/05-commit-capture.md` | unmeasurable as written: a push the operator asked for and a push taken unprompted leave the same trace, so no check can separate them |
| the campaign operating rules | `commands/v-loop/campaign-rules.md` and `commands/v-loop/adapters/*.md` | a campaign runs against an arena that is not this repo, so nothing here can observe whether a rule held. The one rule that needed a counter — a cap on concurrent agents — was reworded to "two agents together only when the conflict sets are disjoint", which a session decides from the ledger row it is writing. Revisit when a run violates one |
