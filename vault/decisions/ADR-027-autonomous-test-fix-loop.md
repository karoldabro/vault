---
type: decision
project: vault
slug: autonomous-test-fix-loop
status: accepted
date: 2026-09-06
tags: [decision, campaign, qa, autonomous, command]
---

# ADR-027 — a campaign command that refuses without an arena the operator agreed to lose

## Status

Accepted, 2026-09-06.

## Context

Two campaigns ran on this machine and produced the same method independently. The web campaign
(`~/vault/digitally-core/processes/autonomous-test-fix-loop.md`, 159 lines) tested a Laravel feature
with Playwright and PHPUnit. The mobile campaign (`prompts/on-device-e2e-campaign.md`, 213 lines,
committed 2026-09-05) tested a Flutter app on a real phone over adb. Neither could be reached by any
existing command: `/v-work` and `/v-team` build, and nothing verified what was already built by
running it.

They converge on nine rules: durable state as the only session handoff, an injection per case, a
blocked case is not a failed one, the backlog enumerated first as the denominator for done, a test
is never weakened to turn a red green, a defect verified before it is filed, evidence only from the
running system, a bounded batch so a kill costs only the batch, and a report led by what is
unresolved. Convergence across two stacks is what makes those general rather than local.

`/v-team` is the warning. Documented as high-stakes only, it reached 78% of lifecycle runs at twice
the cost for the same completion rate, because its entry condition excluded almost nothing
(ADR-015). A soft precondition is how a command becomes the default.

## Decision

1. **The precondition is set by [[ADR-030-task-agnostic-campaign-engine]] decision 3.** `/v-loop`
   refuses without an arena the operator names in words, and without a restore command the session
   runs at intake and proves by re-reading the arena.
2. **The command's scope is set by [[ADR-030-task-agnostic-campaign-engine]] decision 1.** `/v-loop`
   runs whatever task an adapter defines, and still sits outside the `/v-do` → `/v-work` → `/v-team`
   ladder: that ladder decides and builds, this works a backlog against something already running.
3. **The loop carries a round cap and a per-defect retry cap, and the round count lives in
   `STATE.md`.** A cap reset by a usage limit never fires, which is how an uncapped loop spends a
   session on one defect.
4. **The agent that writes a fix does not produce its retest verdict when the verifier is a model.**
   A model grading its own work skews positive. Where the verifier is a command, ADR-030 decision 5
   applies instead.
5. **Concurrency is expressed as disjoint conflict sets, not as a number**, each scope naming every
   path its unit of work writes (ADR-030 decision 8). "Three agents at a time" is a count no session
   keeps; "two agents together only when the conflict sets are disjoint" is decidable from the ledger
   row being written. The campaigns disagree on the number anyway.
6. **Every campaign rule names the sanctioned action rather than the forbidden one, and
   `checks/v-loop-SC-4.sh` holds the engine, the shared rules and every adapter to requirements
   outnumbering prohibitions.** The reason
   is the budget, not compliance: `bin/rule-count.sh --assert` already fails at 150 prohibitions
   against 25 requirements, and a new file writing prohibitions pushes it further from a ratio the
   framework asserts. This repo's own measurement runs the other way — prohibitions score 89.5% and
   requirements 76.9% (`vault/research/rule-compliance.md`) — so the form buys no compliance here,
   and it costs nothing only because these rules are being written for the first time.
7. **`commands/v-loop/campaign-rules.md` restates no rule a shared module owns.** 16 of the web
   campaign's rules already had a home and 6 partly did; `checks/v-loop-SC-3.sh` refuses a
   restatement and refuses a `commands/_shared/` module it does not cover.
8. **The case ledger is append-only JSONL; state and defects stay markdown.** The ledger is written
   constantly under kill risk, where a truncated last line costs one case and a rewritten file costs
   the campaign.
9. **Two shapes.** One session when the backlog fits a usage window; a host timer firing a fresh
   session per batch when it does not. The unattended runner is built and handed over, and no
   session installs it.
10. **The staging guard is extended and registered.** `scripts/staging-hook.sh` denied `git add -A`
    and returned clean on `git commit -am`, which reaches the same outcome. It now denies a
    pathspec-less commit, a `-a` sweep, an amend and a hard reset.

## Consequences

- Campaign artifacts live in `<project-vault>/campaigns/<slug>/`, and `/v-loop` appends
  `campaigns/*/results/` to the project vault's `.gitignore` before the first result is written.
  Evidence drawn from real data stays off the vault remote.
- No `bin/campaign.sh` ships. Decision 5 removed the only rule that needed a counter; the rest are
  prose, recorded as such in `vault/check-budget.md`.
- `prompts/on-device-e2e-campaign.md` gains a consumer. It stays the mobile adapter and is read by a
  campaign against a device.
- **Adapter-local, not general:** the conflict-scope taxonomy and the browser rules come from the web
  campaign alone, and the device diagnostics from the mobile one. The third campaign
  (`vault/campaigns/2026-09-15-0933-doc-corpus/`) used neither, so both stay adapter-local and both
  now live in `commands/v-loop/adapters/test-and-repair.md`.
- **Unproven:** the batch shape's first unattended tick. The permission classifier refuses `crontab`
  edits and refuses to spawn `claude -p` from Bash, so the runner is handed to the operator.
- **A contradiction stays open.** `bin/rule-count.sh` cites an external study where prohibitions
  fall from 73% compliance at turn 5 to 33% by turn 16, and this repo measured the reverse: 89.5%
  against 76.9% across eight scorable rules. `vault/indications/rules-the-model-can-check.md`
  obligation 3 therefore forbids rewording existing rules to chase compliance, and this decision
  does not reword any. Which measurement holds for a multi-hour campaign is untested, and a campaign
  is the first thing this framework runs that reaches turn 16 routinely.
- **Watch:** whether `/v-loop` is invoked without an arena being named, and whether it is reached for
  where `/v-do` would do. ADR-030 carries both watches.
