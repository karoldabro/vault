# Step 5 — CAPTURE (plan mode; also the tail of reconcile)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Record the planning decisions, commit the plan, and hand the operator the first runnable sessions.

## 5.1 The trail is the planning record
`plan.trail.md` already holds the research, the options rejected, and each round's findings with
their dispositions. Add the session's need, participants and tier at its top. A single-repo run also
writes a one-line session note into `<project-vault>/sessions/` that links the plan folder.

## 5.2 Extract ADR candidates
Scan the plan and the trail for decision-shaped statements: `chose X over Y`, a sequencing call, a
contract shape. Present each as one line; for each the operator confirms, write it from
`$VAULT_FRAMEWORK_PATH/templates/decision.md`:
- multi-repo → `~/vault/_features/<feature>/decisions/ADR-<n>-<slug>.md`, the neutral workspace. Offer
  to promote one into `~/vault/<proj>/decisions/` when it binds only that repo.
- single-repo → `<project-vault>/decisions/`.

## 5.3 Commit and push
```bash
$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh push <plan vault> -m "plan <feature>" <plan folder> <requirements file>
```
The plan vault is `~/vault/_features` for multi-repo and the project vault for single-repo. Never raw
`git`, never `git add -A`. Exit codes: `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`. On exit
5 (no upstream) say plainly that sessions on another machine cannot see the plan yet.

## 5.4 Hand over the run order
```bash
$VAULT_FRAMEWORK_PATH/bin/pm-plan.sh order <plan>
```
Print the waves, then the run line of every `runnable` session, copied from its brief's
`## Next command`. Sessions in one wave may run at the same time; a later wave waits.

## Required output
```
Plan: <absolute plan path>   (<n> sessions, <w> waves)
ADR candidates: <N found, M written>
Committed: <plan vault> (<shortsha>)   · pushed: <yes | no — reason>
Run now:
  <run line of each wave-1 session>
```
Mark CAPTURE `completed`. Plan mode ends here; `/v-pm` implements nothing.
