---
type: guide
project: vault
slug: cross-project-workspaces
status: current
tags: [v-pm, cross-project]
---

# Cross-project feature workspaces (`/v-pm`)

`/v-pm` plans a feature **once**, project-agnostically. Each project's `/v-team <feature>` session reads
that plan and coordinates through files, so you stop carrying context between sessions by hand.

**Use it only for a feature spanning 2 or more repos worked in separate sessions.** For a single-project
feature `/v-pm` hands straight off to `/v-team`.

### Home & ownership
`~/vault/_features/` is its **own committed vault**, owned by no single project. Each participant project
holds a `features/<feature>` **symlink** into it, gitignored in the project repo (see
`templates/vault.gitignore`).

### Layout
```
~/vault/_features/<feature>/
  requirements.md    business knowledge center — what & why (rules REQ-NN, glossary, variant/state tables) — ONLY /v-pm writes it
  generic-plan.md    project-agnostic plan — how/sequencing + appetite + first slice + options considered — ONLY /v-pm writes it
  contracts.md       structured cross-project interface (the api↔frontend seam); refs rules by REQ-NN
  header.md          participants · status · created · session_opens counter
  conversation/      threads (state encoded in the filename)
  sessions/          planning-session records — v-pm CAPTURE writes the *why* behind the plan
  decisions/         cross-project ADRs extracted at CAPTURE (promotable to a participant vault)
  projects/<proj>/plan.md   each project's self-contained shard (its own /v-team writes it); v-pm seeds only its `## Business rules to satisfy` REQ-NN list and its `## Sessions` appetite line
```

### Business knowledge center (`requirements.md`) — spec → established lifecycle
`requirements.md` is a **SPEC**, aspirational by design. It holds business rules shaped as
`precondition → expected [; edge]`, each with a stable `REQ-NN` id, plus acceptance criteria, a domain
glossary and optional decision or state tables. It grounds rich tests and captures the necessity once.

- **Written for any feature**, one repo or many; `_features/`, `conversation/` and `contracts.md` are
  the delta two or more repos add.
  - **2+ repos:** `requirements.md` in the neutral `_features/<feature>/`, symlinked into each project.
  - **1 repo:** `<project-vault>/requirements/<feature>.md`, with no cross-repo write.
- **Id-traceability chain**, which is what makes the spec *ground* tests rather than describe them:
  `requirements.md` rule `REQ-NN` → `/v-team` LOAD CONTEXT reads it (`00-feature-pickup` §0.2, or the
  `02-load-context` `requirements/` glob) → the `(f2)` test-design fan-out echoes `REQ-NN` into the
  proposed test backlog's `source` → at capture, the **established** `features/<feature>` dossier's
  `## Behaviors & rules` carries the same `REQ-NN`.
- **Spec against established.** `/v-team` and `/v-capture` promote only **built** rules into the dossier;
  the `established, not aspirational` rule (`capture-behaviors-test-shaped`) still governs `features/`.

### Sizing and tracking — a budget, then rows the working session owns
`/v-pm` sets the size and names the starting point; it never enumerates the work, because it does not
read the code it would be slicing.

- **`## Appetite`** (in `generic-plan.md`) — how many sessions the feature is worth in each repo,
  decided before the design is detailed. A **ceiling**: a session that does not fit cuts `[could]` then
  `[should]` rules rather than exceeding it.
- **`## First slice`** — the one cut that runs vertically through the hardest part, so the surprise
  arrives first.
- **`## Sessions`** (in each `projects/<proj>/plan.md`) — the tracker. `/v-pm` seeds the header and the
  appetite; the project's own `/v-team` session writes every row at propose-time `(f3)` and maintains
  it thereafter. Columns: `id · scope · command · status · REQ covered · evidence · last touched ·
  deviation`. `status` is exactly `todo`/`doing`/`done`/`dropped`; `command` is `/v-do`, `/v-work` or
  `/v-team` (never `/v-ask`, which writes nothing and so closes nothing).

The tracker lives in the shard because that is the file the working session already opens. The one
roadmap here that stalled kept its tracker in a separate file nothing forced anyone to read.

**A `done` row without evidence is invalid.** The evidence cell holds a commit or a session-record
path. Four sessions in one feature were once closed as done against a code path that could never run,
because nothing asked for it.

**Expect the rows to be wrong in detail and to say so.** The tracker that worked here shipped all ten
of its sessions and rewrote nearly every row on the way. A recorded deviation is the tracker doing its
job; a row that drifts silently is the defect.

### Status is derived, never hand-kept
A feature's `header.md` `status:` is **rolled up from the session rows** by `/v-capture` Step 4e on the
way out of every session: all `todo` → `planning`; some moving → `in-progress`; all `done` or `dropped`
→ `shipped`. `/v-pm status` reads the rows too, and flags any header that disagrees with them.

Two places once held this field and only one was ever written, which is why nine of twelve features
read `planning` while their own shards read `done`. Derive it; do not maintain a second copy.

`/v-pm`'s **CAPTURE** step — plan mode step 5, and the tail of `reconcile` — writes the planning-session
record, extracts cross-project ADR candidates, and commits the workspace, which is what each project's
LOAD CONTEXT then finds.

There is **no `ledger.md`**. The ledger is a **derived view** computed from thread filenames on read, by
`/v-pm status` and by reconcile. Nothing writes it, so parallel sessions never race on it.

### Conversation protocol
A thread is one Markdown file whose **filename carries its state**. Frontmatter carries `from` / `to` /
`asks`. Template: `templates/_features/THREAD.md`.

| filename | meaning | who moves it |
|----------|---------|--------------|
| `THREAD_<n>_OPEN_→<proj>.md` | question waiting on project `<proj>` | the asker creates it |
| `THREAD_<n>_OPEN_→pm.md` | decision that changes the generic plan / a contract | drained by `/v-pm reconcile` |
| `THREAD_<n>_ANSWERED_<answerer>.md` | answered; waiting for the asker to consume | the answerer renames |
| `THREAD_<n>_RESOLVED.md` | asker consumed the answer | the asker renames |

### How it reaches execution — auto-pickup
When `/v-team` runs with a `<feature>`, or finds the `features/<feature>` symlink, its **Step 0**
(`v-team/steps/00-feature-pickup.md`) runs before ANALYZE. It acts on threads addressed to this project,
surfaces replies, and runs a **deterministic** field-by-field drift check of the project's consumed
contract against `contracts.md` — the model phrases the rationale but never decides whether drift exists.
A new doubt raised mid-session becomes a new thread instead of a message to you.

### Latency contract
There is **no live agent-to-agent channel**. A reply surfaces at the **next open** of the asking
project's session, or immediately through **`/v-pm status`**, the inbox listing every open thread with
its staleness age. `reconcile` flags any thread left OPEN for more than N session-opens.
