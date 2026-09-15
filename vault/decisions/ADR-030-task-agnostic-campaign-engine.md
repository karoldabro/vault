---
type: decision
project: vault
slug: task-agnostic-campaign-engine
status: accepted
date: 2026-09-15
tags: [decision, campaign, engine, adapter, command]
supersedes: [ADR-027-autonomous-test-fix-loop]
---

# ADR-030 — the campaign loop is the command; the task is an adapter

## Status

Accepted, 2026-09-15. Supersedes decisions 1 and 2 of
[[ADR-027-autonomous-test-fix-loop]]; its decisions 3 to 10 stand unchanged.

## Context

ADR-027 built `/v-loop` from two campaigns, and both were testing campaigns: a Laravel feature under
Playwright and PHPUnit, a Flutter app on a phone over adb. It recorded the convergence of those two
as evidence the rules were general. Convergence across one domain is not that evidence.

A third campaign ran on 2026-09-15 against a task with no tests, no browser and no running
application: rewriting this repo's own document corpus until each file passes `bin/doc-lint.sh`.
21 cases, 17 documents, 100 violations, 0 failures, both control cases byte-identical
(`vault/campaigns/2026-09-15-0933-doc-corpus/`). It ran the same loop and needed five rules changed.

## Decision

1. **`/v-loop` is a loop engine, and the task is an adapter.** `commands/v-loop.md` holds enumerate →
   work → verify → repair → re-verify → stop. What a case is, who works it and what decides it live
   in `commands/v-loop/adapters/<name>.md` against the contract in `commands/v-loop/adapters.md`.
2. **Two adapters are the floor.** One adapter is indistinguishable from no adapter layer, so
   `checks/v-loop-adapter-slots.sh` refuses below two, refuses an adapter missing any of the six
   slots, and refuses two adapters that verify the same way.
3. **The precondition is two facts, never a judgement.** The operator names the arena in words, and
   names the command that restores it; the session **runs that command at intake and re-reads the
   arena**. "Is this destructive?" is a question a session talks itself out of at hour four, and a
   name it was never given is not. `git checkout -- <path>` leaves every untracked file in place, so
   a restore nobody has run is a guess.
4. **The discriminator belongs to the adapter.** A test carries its contrary condition on the case
   row. A document rewrite cannot: its contrary condition is a different input file, therefore a
   different case, so `document-corpus` uses control rows that must come back unchanged. The shared
   contract asks only that a campaign be able to fail.
5. **Verification is conditional on the verifier.** ADR-027 decision 4 required a second agent
   because a model grading itself skews positive. Where the verifier is a command, the working agent
   may run it and the orchestrator re-runs it, and the two must agree. The verifier must be the most
   deterministic thing available; a model is the answer only when nothing deterministic exists.
6. **The definition of done is the verifier plus any clause citing a written rule.** A verifier reads
   what it reads and no more, so a case may carry work no finding can name. Each such clause names
   the rule it cites; a clause resting on judgement is recorded as a finding, not worked. This also
   binds enumeration: a backlog built from the verifier alone answers how much the tool can see, not
   how much work there is.
7. **A brief carries commands, never results.** Every count an orchestrator writes into a case brief
   carries the command that produced it, and the agent runs that command. Three briefs in the
   document campaign carried a wrong number, and each was caught only because the agent went to the
   source; a line number is stale the moment anyone edits above it.
8. **A conflict scope names every path the unit of work writes.** Thirteen cases each wrote two
   files, and a scope keyed on the case's own file would have let a second agent take the sidecar.
9. **A verdict expires when its case changes.** The ledger is append-only and the last line for an id
   wins, so a re-verified case appends a row. An agent that reworks a case after reporting says so,
   and the orchestrator re-runs the verifier before the row stands.

## Consequences

- `commands/v-loop/campaign-rules.md` keeps only what binds any agent acting on a live system.
  Executable tests, injections, browser assertions, the red-case decision table, `artisan test`
  pinning, queue-worker restarts and case-id teardown all move to
  `commands/v-loop/adapters/test-and-repair.md`. `checks/v-loop-SC-5.sh` searches the engine and
  every adapter, so a rule that survives its move is still enforced and one that survives nowhere
  fails the gate.
- `templates/campaign/TESTER-BRIEF.md` becomes `AGENT-BRIEF.md`, and the ledger's `injection` field
  becomes `discriminator`, empty for an adapter that proves failure with control rows instead.
- `templates/campaign/defects.md` keeps its column spelled `test` whatever an adapter calls its
  check, because `bin/gate.sh:407` finds it by that literal name and dies without it.
- `prompts/on-device-e2e-campaign.md` stays where it is, read by the testing adapter for a device run.
- **Still adapter-local, still unconfirmed:** the conflict-scope taxonomy and the browser rules come
  from the web campaign alone. The document campaign used neither.
- **Watch:** whether `/v-loop` is invoked where `/v-do` would do. ADR-027 recorded that `/v-team`
  reached 78% of runs because its entry condition excluded almost nothing, and this decision widens
  what `/v-loop` accepts. The routing table in `commands/v-loop.md` now refuses a backlog under ten
  cases and a task with no adapter; if invocations rise anyway, the answer is a check rather than
  another sentence.
