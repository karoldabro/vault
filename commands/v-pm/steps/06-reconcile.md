# reconcile mode — `/v-pm reconcile <feature>`

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Fold what execution learned back into the plan, drain the threads addressed to the planner, and
convert a workspace planned before `plan.md` existed.

## R.1 Load
Resolve the feature and its tracker as `$VAULT_FRAMEWORK_PATH/commands/_shared/feature-pickup.md` §0.1
does. Read `plan.md`, `contracts.md`, every brief, and the thread filenames under `conversation/`.

## R.2 Convert a legacy workspace — only when it has no `plan.md`
Such a workspace holds `generic-plan.md` and shard trackers in `projects/*/plan.md`, and their shapes
differ: column order, status words, session ids, and a `## Session tracker` heading in place of
`## Sessions`. Never convert blind.

1. Build a mapping table: each shard row → a `plan.md` Sessions row (id, repo path, scope, command,
   status, depends, req, evidence). Map a status outside `todo | doing | done | dropped` and an id
   outside `S<n>` by proposal, one line each.
2. Show the operator the table and ask once: convert as shown, edit, or leave the workspace as it is.
3. On "convert": write `plan.md` from `$VAULT_FRAMEWORK_PATH/templates/feature-plan.md`, one brief per
   row that is not `done`, and fold `generic-plan.md` into `plan.trail.md`. Remove the tracker sections
   from the shards. A legacy workspace has no operator success criteria, so ask for them per
   `01-intake.md` §1.2 before the plan is written.
4. Run `$VAULT_FRAMEWORK_PATH/bin/pm-plan.sh check <plan>` until it exits 0.

## R.3 Drain `to: pm` threads
Each `THREAD_*_OPEN_→pm.md` is a decision that changes the plan or a contract. Resolve it; when it
needs the operator, ask (`AskUserQuestion`). Apply it to `plan.md`, `contracts.md` and the affected
briefs, then rename the thread `…_RESOLVED.md` with the disposition appended.

## R.4 Fold execution learning
Read each row's `deviation` cell. A deviation that changes a later session's scope, contract or
dependency is written into that session's row and brief. A contract that proved wrong is fixed in
`contracts.md`, the source of truth, and in every brief that quotes it. Re-run `pm-plan.sh check`.

## R.5 Staleness
An `OPEN` thread older than N session-opens (default 3, tracked in `header.md`), or a `doing` row
whose `date` is old enough to look abandoned, gets one line: "waiting on `<proj>`, untouched in N
opens". A row a dead session left `doing` is released with `pm-plan.sh set <plan> <id> status=todo`
once the operator confirms.

## R.6 Capture
Read `05-capture.md` and run it: the trail records what changed, ADR candidates, commit, run order.

## Required output
```
Converted: <no legacy layout | n rows → plan.md, operator-confirmed>
Drained (to: pm): [threads → decisions applied]
Plan changes: [rows, briefs, contracts that moved]
Stale: [threads or rows waiting N+ opens]
Captured: [trail + ADRs + commit]
```
