# Step 0 — FEATURE PICKUP (`/v-work` and `/v-team`, when the task names a feature session)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Connects this session to a `/v-pm` feature plan before ANALYZE: resolve the plan and its tracker,
refuse a session that may not start yet, claim the row, and load the brief as the task. It also
picks up threads addressed to this repo and checks the contract for drift.

Runs when the task holds a locator: `<absolute plan path>#<id>`, or a feature slug with an optional
`S<n>`. No locator → skip this step entirely.

## 0.1 Resolve the plan and its tracker
This section is the one home of tracker resolution; every other reader references it.

1. **Plan.** A `<plan>#<id>` locator names the plan. A feature slug resolves, first hit wins, to
   `<project-vault>/plans/<feature>/plan.md`, then `~/vault/_features/<feature>/plan.md`.
2. **Tracker.** When that `plan.md` exists, its `## Sessions` table is the tracker. When only
   `~/vault/_features/<feature>/` exists, the workspace is in the legacy layout: its tracker is the
   `projects/<this>/plan.md` shard, and its plan is `generic-plan.md`. Say once: "legacy layout —
   `/v-pm reconcile <feature>` converts it". Skip §0.2 to §0.4: read the shard, `generic-plan.md`,
   `requirements.md` and `contracts.md`, then go on to §0.5. The close updates the shard row.
3. **Nothing found** → warn loudly ("no feature plan `<feature>` — proceeding as a plain session") and
   skip the rest of this step.

`<this>` is the current repo's vault slug.

## 0.2 Pick the session and refuse what may not start
Run `$VAULT_FRAMEWORK_PATH/bin/pm-plan.sh order <plan>`. With no id given, take the first line whose
readiness is `runnable` and whose repo is this repo's absolute path; when there is none, print the
order and end the session.

The named session must read `todo` and `runnable`. Otherwise print its line and end the session:
- `waits:<ids>` — name the sessions still open.
- `blocked:<ids>` — a dependency was dropped; `/v-pm reconcile <feature>` re-points it.
- `running` — another session holds it. A row a dead session left `doing` is released with
  `pm-plan.sh set <plan> <id> status=todo` after the operator confirms.

## 0.3 Claim the row
Write `doing` and today's date with the row-write routine of
`$VAULT_FRAMEWORK_PATH/commands/v-work/steps/05-commit-capture.md` §5.1a:
`pm-plan.sh set <plan> <id> status=doing date=<today>`, between a pull and a push of the plan's vault.

## 0.4 Load the brief as the task
Read the brief `briefs/<id>-<slug>.md` beside the plan, then `plan.md`, `requirements.md` and, for a
multi-repo plan, `contracts.md`.
- `## Goal` is the task restatement for ANALYZE §1.1, word for word.
- `## Left to do` names the files; `## Do not touch` binds the session.
- Copy each success criterion the row reaches into the session plan's `## Success criteria`, so the
  close grades it.
- Print the `deviation` cell of every row this session depends on. A deviation that changes this
  session's input is read before PROPOSE.
- The `/v-work` fast path is off for this session. PROPOSE writes
  `session_of: <absolute plan path>#<id>` into the session plan.

## 0.5 Threads addressed here — multi-repo only
For each `conversation/*_OPEN_→<this>.md`: read it, answer or act on it within this session, then
rename it `*_ANSWERED_<this>.md` with the reply appended. A question that needs a decision above this
repo (a contract or plan change) becomes a `*_OPEN_→pm.md` thread instead. For each `*_ANSWERED_*.md`
on a thread this repo opened, surface the reply and rename it `…_RESOLVED.md` once consumed.

## 0.6 Deterministic contracts-drift check — multi-repo only
Diff this repo's shard `## Consumed contract` against `contracts.md` field by field — a mechanical
compare of the tables, not a prose read. On a mismatch, cite the drifted field and raise a
`*_OPEN_→pm.md` thread, or `→<other>` when the other side owns it. The model only phrases the
rationale; it never decides whether drift exists.

## 0.7 New doubts during the session
A cross-repo doubt mid-session becomes a thread, never a question to the operator:
`conversation/THREAD_<n>_OPEN_→<target>.md` from `$VAULT_FRAMEWORK_PATH/templates/_features/THREAD.md`.
Bump this repo's session-open counter in `header.md`.

## Required output
```
Feature: <feature>  ·  Session: <id> (<command>) in <repo>  ·  Plan: <absolute plan path>
Claimed: <id> doing   ·   Upstream deviations: [<id>: <cell>]
Picked up: [threads answered]  ·  Contract drift: [field X drifted → thread raised]
```
Omit a line with nothing to say. A refusal from §0.2 is the whole output.
Then continue into Step 1 (ANALYZE).
