# Step 5 — CAPTURE (plan mode; also the tail of reconcile)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Planning is where the cross-project decisions are made — record them, or they evaporate. This is v-pm's
own `/v-capture`, scoped to the feature workspace and cross-project. Runs after SEED WORKSPACE (plan
mode) and at the end of `reconcile`.

**Single-repo mode (1 participant):** capture against the **project vault**, not `_features/` — write the
planning-session into `<project-vault>/sessions/`, push the requirements.md glossary + rules to OV, and
commit the **project vault** (which now holds `requirements/<feature>.md`). Skip the ADR-into-neutral-
workspace default (§5.2) — any ADR is this one project's, so it lands in `<project-vault>/decisions/`.
Then tell the user to run `/v-team`/`/v-work` in that repo. The rest below is the multi-repo path.

## 5.1 Write the planning-session record
Into `~/vault/_features/<feature>/sessions/YYYY-MM-DD-HHMM-<slug>.md` (from
`$VAULT_FRAMEWORK_PATH/templates/_features/planning-session.md`): the necessity, participants, the panel's
**critique trail** (what each critic raised; applied / rejected / deferred), the decisions and trade-offs,
and links to `requirements.md` + `generic-plan.md` + `contracts.md`. This is the *why* behind the plan —
the part the committed artifacts don't hold.

## 5.2 Extract cross-project ADR candidates
Scan the plan + panel decisions for decision-shaped statements (`chose X over Y`, `going with`, `rejected
… in favor of`, sequencing calls, contract-shape decisions). Present each as a one-line candidate; for
each the user confirms:
- Write `~/vault/_features/<feature>/decisions/ADR-<n>-<slug>.md` (from
  `$VAULT_FRAMEWORK_PATH/templates/decision.md`) — cross-project ADRs live in the **neutral workspace** by
  default, not scattered into one participant's vault.
- **Offer to promote** an ADR into a specific participant's vault (`~/vault/<proj>/decisions/`) when it's
  really that one project's call rather than a shared one.
Don't manufacture ADRs — only genuine decisions the planning actually made.

## 5.3 Make the knowledge findable
The committed `requirements.md` **is** the durable record — domain glossary, business rules (REQ-NN)
and the variant/state tables. Keep those tables in the file, not only the glossary and rules: they are
the test-design fan-out's primary input, and grep over the vault is how each project's `/v-team` LOAD
CONTEXT (`02-load-context.md` §2.1) finds them. claude-mem auto-captures on session end — no action.

## 5.4 Commit + push
Commit the whole `~/vault/_features/<feature>/` (workspace + planning-session record + any ADRs) with
**explicit paths** — `_features/` is its own committed vault, and a cross-project plan that never
leaves this machine is useless to the other participants:

```bash
$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh push ~/vault/_features -m "plan <feature>" ~/vault/_features/<feature>
```

Single-repo mode pushes the **project vault** instead, same call. Never raw `git`, never `git add -A`.
Exit codes and what each means: `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`. Exit 5 (no
upstream) matters more here than anywhere else — say plainly that the other projects cannot see the
plan yet.

## Required output

**Multi-repo:**
```
Planning session: _features/<feature>/sessions/<file>.md
ADR candidates: <N found, M written>   (promoted to <proj>: [...] | none)
Committed: _features/<feature>/  (<shortsha>)
```
Mark CAPTURE `completed`. Plan mode complete — tell the user the workspace is ready and to run
`/v-team <feature>` in **each** project.

**Single-repo:**
```
Requirements: <project-vault>/requirements/<feature>.md
Planning session: <project-vault>/sessions/<file>.md
ADR candidates: <N found, M written> (in <project-vault>/decisions/ | none)
Committed: <project-vault>  (<shortsha>)
```
Mark CAPTURE `completed`. Plan mode complete — the knowledge center is written; tell the user to run
`/v-team` (or `/v-work`) in **that** repo to build it.
