---
type: feature
project: vault
slug: v-loop
status: in_progress
owners: []
tags: [feature, command, campaign, qa]
---

# v-loop

## Scope
`/v-loop` — an autonomous test-and-fix campaign against a feature already built and running. It
takes every operator decision in one opening exchange, enumerates a case backlog, turns each case
into an executable test in the project's own framework, runs it against a disposable stack, files
what fails, fixes it, and hands the retest to a different agent. Non-goals: it builds nothing (that
is the `/v-do` → `/v-work` → `/v-team` ladder), it installs no unattended runner, and it starts
against no stack the operator has not named as disposable.

## Contracts
- **Command**: `commands/v-loop.md` (dispatcher, precondition, intake, resume, both shapes) +
  `commands/v-loop/campaign-rules.md` (the rules binding every spawned agent). Linked by
  `link_tree` at `install.sh:106`, which globs `commands/*.md` and every immediate subdirectory.
- **Precondition**: a disposable stack the operator names in words. A session that has no such name
  stops and says what is missing. Rule: [[../indications/campaign-evidence-from-the-running-system]].
- **Templates**: `templates/campaign/{STATE,ledger,result,defects,TESTER-BRIEF}.md`, instantiated
  into `<project-vault>/campaigns/YYYY-MM-DD-HHMM-<feature-slug>/`. `STATE.md` carries `rounds_used`,
  which is what makes the round cap survive a usage limit.
- **Ledger**: `ledger.jsonl`, append-only, last line per id wins. Fields `id`, `surface`, `kind`,
  `title`, `injection`, `conflicts_on`, `file`, `status`, `reason`, `run_at`, `evidence`. Terminal
  statuses `pass`, `fail`, `blocked`; a `blocked` row carries the exact unblock action.
- **Caps**: `loop_max_rounds` (3) and `max_fix_attempts` (3), both stated in the intake exchange.
- **Adapters**: `prompts/on-device-e2e-campaign.md` for a campaign against a device.
- **Checks**: `checks/v-loop-SC-1.sh` (precondition, intake, caps, resume, envelope, templates
  exist), `SC-2` (doc-lint over every shipped file), `SC-3` (no rule restated from any of the seven
  `commands/_shared/` modules), `SC-4` (requirements outnumber prohibitions), `SC-5` (all twelve
  safety rules survive), `SC-6` (the staging guard). Tests: `tests/unit/v-loop.bats`.
- **Staging guard**: `scripts/staging-hook.sh` denies `git add -A`, `git add .`, `git commit -a`,
  `git commit -am`, a pathspec-less `git commit`, `git commit --amend` and `git reset --hard`.
  Registered as a `PreToolUse` entry on `Bash`. Tests: `tests/unit/staging-hook.bats`.

## Behaviors & rules
- Invocation with no disposable stack named → the session stops and names the missing precondition;
  edge: a stack inferred from `docker-compose.yml` does not satisfy it. [ADR-027]
- A `campaigns/` directory holding a `STATE.md` with a non-empty retest queue or never-run list →
  the session resumes that campaign and carries `rounds_used` forward; edge: two open campaigns →
  the session asks which. [ADR-027]
- Two testers dispatched together → their `conflicts_on` sets are disjoint; edge: a `global` scope
  runs alone. [ADR-027]
- A case whose injected condition produces the same outcome as the normal one → verdict `BLOCKED`,
  not `PASS`. [ADR-027]
- A fix landing → its retest verdict is produced by an agent other than the one that wrote it.
  [ADR-027]
- `rounds_used` reaching `loop_max_rounds` → the session stops, reports every case still failing,
  and escalates; it does not continue. [ADR-002, ADR-027]
- A single defect reaching `max_fix_attempts` → recorded as deferred with what was tried; the loop
  continues on the rest. [ADR-027]
- The first result file being written → `campaigns/*/results/` is present in the project vault's
  `.gitignore`. [ADR-027]

## Coupling
- Reads `commands/_shared/{communication,agent-conduct,document-standard,vault-sync,elicitation}.md`
  and restates none of them; `checks/v-loop-SC-3.sh` refuses a restatement.
- Writes into a project vault through `bin/vault-sync.sh` only; `tests/unit/vault-sync.bats`
  enumerates the command files bound by that rule and lists this one.
- `bin/gate.sh recurrence` grades a campaign's `defects.md`, which shares the
  `vault/defect-ledger.md` column set.

## Gotchas
- The conflict-scope taxonomy and the browser rules come from the web campaign alone; the device
  diagnostics from the mobile one. A third stack confirms or deletes them.
- The batch shape's first unattended tick is unproven. Claude Code's permission classifier refuses
  `crontab` edits and refuses to spawn `claude -p` from Bash, so `/v-loop` hands the operator two
  commands rather than installing anything.
- No `bin/campaign.sh` exists. The concurrency rule is worded so a session decides it from the
  ledger row it is writing, which removed the only rule that needed a counter.
- `checks/v-loop-SC-3.sh` matches the shared modules' literal wording, so a reworded duplicate
  passes. A green run is not proof of no duplication.

## Sessions
- [[../sessions/2026-09-06-1053-v-loop-autonomous-campaign]]
