---
type: guide
project: vault
slug: cross-project-workspaces
status: current
tags: [v-pm, cross-project]
---

# Feature plans and cross-project workspaces (`/v-pm`)

`/v-pm` plans a feature once, read-only, and splits it into sessions. Each session runs through
`/v-work` or `/v-team` from a pasted run line, so you stop carrying context between sessions by hand.
The command steps are in `commands/v-pm.md`; this guide describes the files they leave behind.

### Homes
- **1 repo** → `<project-vault>/plans/<feature>/`, with `requirements.md` at
  `<project-vault>/requirements/<feature>.md`.
- **2+ repos** → `~/vault/_features/<feature>/`, its **own committed vault**, owned by no single
  project. Each participant holds a `features/<feature>` **symlink** into it, gitignored in the project
  repo (`templates/vault.gitignore`).

### Layout
```
<plan home>/
  plan.md            the feature plan (templates/feature-plan.md) — success criteria, done lines, decisions, Sessions, contracts
  plan.trail.md      the planning record: research, rejected options, review findings (templates/trail.md)
  briefs/<id>-<slug>.md   one per session, a templates/handoff.md instance with `plan` and `id`
multi-repo only, in ~/vault/_features/<feature>/:
  requirements.md    business knowledge center — rules REQ-NN, glossary, variant/state tables
  contracts.md       structured interface between the repos; refs rules by REQ-NN
  header.md          participants · derived status · session_opens counter
  conversation/      threads (state encoded in the filename)
  decisions/         cross-project ADRs extracted at capture (promotable to a participant vault)
  projects/<proj>/plan.md   each repo's consumed contract, constraints and tests — no tracker
```

`bin/pm-plan.sh check <plan>` refuses a plan that is not normalized; `bin/pm-plan.sh order <plan>`
prints the run order. Rules for each table: `templates/feature-plan.md` and `templates/master-plan.md`.

### Business knowledge center (`requirements.md`) — spec → established lifecycle
`requirements.md` is a **SPEC**, aspirational by design. It holds business rules shaped as
`precondition → expected [; edge]`, each with a stable `REQ-NN` id, plus a domain glossary and optional
decision or state tables. The success criteria are not here: they live in `plan.md`, stated by the
operator, and `requirements.md` links them.

- **Id-traceability chain**: rule `REQ-NN` → the Sessions row's `req` cell names it → the session's
  test backlog echoes it in `source` → at capture, the **established** `features/<feature>` dossier's
  `## Behaviors & rules` carries the same `REQ-NN`.
- **Spec against established.** `/v-capture` promotes only **built** rules into the dossier; the
  `established, not aspirational` rule (`capture-behaviors-test-shaped`) still governs `features/`.

### Running a session
Paste the brief's `## Next command` line into a shell:
```
cd <repo> && claude --add-dir <plan folder> "<command> <absolute plan path>#<id>"
```
or run `/v-work <feature> [S<n>]` / `/v-team <feature> [S<n>]` in the repo. Step 0 of both,
`commands/_shared/feature-pickup.md`, refuses a session whose dependencies are not `done`, marks the
row `doing`, and loads the brief as the task. The close, step 5.1a of
`commands/v-work/steps/05-commit-capture.md`, marks it `done` with the code commit as evidence.
Sessions that `order` puts in one wave may run at the same time.

**A `done` row without evidence is invalid.** **Expect rows to be wrong in detail and to say so**: a
session may correct its own row's scope and `deviation`, and may append a row with its brief. A
recorded deviation is the tracker working; a row that drifts silently is the defect.

### Status is derived, never hand-kept
A feature's `header.md` `status:` is **rolled up from the session rows** by `/v-capture` Step 4e on the
way out of every session: all `todo` → `planning`; some moving → `in-progress`; all `done` or `dropped`
→ `shipped`. `/v-pm status` reads the rows too, flags a header that disagrees, and fills the plan's
done lines once every row is closed.

There is **no `ledger.md`**. Thread state is a **derived view**, computed from filenames on read, by `/v-pm status` and by
reconcile. Nothing writes it, so parallel sessions never race on it.

### Legacy workspaces
A workspace planned before `plan.md` existed holds an older generic plan file and session tables in its
shards. Its readers keep working as before. `/v-pm reconcile <feature>` converts it into a `plan.md`
after the operator confirms the mapping of each row.

### Conversation protocol
A thread is one Markdown file whose **filename carries its state**. Frontmatter carries `from` / `to` /
`asks`. Template: `templates/_features/THREAD.md`.

| filename | meaning | who moves it |
|----------|---------|--------------|
| `THREAD_<n>_OPEN_→<proj>.md` | question waiting on project `<proj>` | the asker creates it |
| `THREAD_<n>_OPEN_→pm.md` | decision that changes the plan or a contract | drained by `/v-pm reconcile` |
| `THREAD_<n>_ANSWERED_<answerer>.md` | answered; waiting for the asker to consume | the answerer renames |
| `THREAD_<n>_RESOLVED.md` | asker consumed the answer | the asker renames |

Feature pickup acts on threads addressed to this repo and runs a **deterministic** field-by-field drift
check of the repo's consumed contract against `contracts.md`; the model phrases the rationale but never
decides whether drift exists.

### Latency contract
There is **no live agent-to-agent channel**. A reply surfaces at the **next open** of the asking
repo's session, or immediately through **`/v-pm status`**, the inbox listing every open thread with
its staleness age. `reconcile` flags any thread left OPEN for more than N session-opens.
