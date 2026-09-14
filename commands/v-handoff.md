---
description: Write what the next session needs to carry on this one — what is left, what not to touch, what is unverified, and the exact command to run first. Resume reads it back.
argument-hint: "[resume [<slug>] | list]"
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here.

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs the handoff file this command writes.

# /v-handoff — hand the work to the next session

`/v-handoff` writes one file into `<project-vault>/handoffs/` holding what the next session needs to
carry on: what is left, what it must not touch, what was done but never proven, and the exact command
to run first. `/v-handoff resume` reads that file back and states the next command.

**What it is for.** A session that has run long, or has run into the night, stops without losing the
part of its context that is not in the repo. The repo holds the code; this file holds the direction,
the unproven claims and the settled judgement calls that would otherwise be re-derived or re-argued.

**What it is not.** It is not a session capture. `/v-capture` records what happened; this records what
is still true. A session with nothing left to do has no handoff to write.

---

## Two refusals

| condition | what the command does |
|-----------|----------------------|
| The repo has no resolved vault | say so, name `/v-init` as the command that creates one, and stop. Nothing is written outside a vault |
| Nothing is left to do | refuse, and name `/v-capture` instead. A handoff whose `## Left to do` table is empty is a session record under another name, and it will be read as unfinished work by every later session |

---

## Step 0 — Resolve the vault

Resolve the vault path per `$VAULT_FRAMEWORK_PATH/vault-guide.md` §1.1: `<repo-root>/VAULT.md` →
`vault_path`, then `~/vault/_global/config.md`, then `~/vault/<slug>/`. Below, `<vault>` is that path.

Create `<vault>/handoffs/` when it is absent, warn once that the folder was missing, and carry on.
Never halt for a missing folder.

Unless carried `behaviour.vault_autosync` is `false`, pull first:
`$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh pull <vault>`. Branch on the exit code per
`$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`. A failed pull never blocks the write.

---

## Mode 1 — write (the default)

### Step 1 — Collect the eight core sections

These are written every run, in this order, above everything optional. Pull each from the
conversation, not from the repo — the repo is not what gets lost.

| section | what goes in it | where it comes from |
|---------|-----------------|---------------------|
| `## Left to do` | one row per item: action, exact file path, and what makes it done. Ordered, first row first | the plan's open work items, plus anything this session found and did not finish |
| `## Do not touch` | files, branches, running processes and data the next session must leave alone, each with a checkable reason | a stash, a half-applied migration, another session working in the same repo, a stack someone else is using |
| `## Unverified` | what was done and not proven, each line naming what would settle it | a change nobody ran, a test not executed, a claim resting on an assumption |
| `## Goal` | one sentence: what the finished work looks like | the task restatement |
| `## Task` | what was assigned, in the words it was assigned in | the operator's own message |
| `## Requirements` | the constraints the work must satisfy, one per line, each naming the file it comes from | `indications/`, the plan, `CLAUDE.md`, a contract |
| `## Next command` | the exact command with its arguments | the first row of `## Left to do` |
| `## Blockers` | what stops progress and who unblocks it | anything waiting on a person, a service or a decision |

**`## Unverified` is the section a tired session skips and the next session pays for.** Write it
before `## Done`. A handoff that reports work as finished when it was never run sends the next
session to build on it.

### Step 2 — Add the optional six, only when this session has them

`## Success criteria` · `## Plan` · `## Method` · `## Done` · `## Direction` · `## Notes`.

Delete a heading you would leave empty. Writing "none" under six headings is the volume that makes the
first eight sections go unread.

- `## Done` carries **how** the work was carried out as well as what: the command or tool that made
  each change, so the next session repeats the method instead of inventing a second one.
- `## Direction` carries judgement calls already taken and the reason for each. Without it the next
  session re-opens a settled question and answers it the other way.

### Step 3 — Write the file

Instantiate `$VAULT_FRAMEWORK_PATH/templates/handoff.md` into
`<vault>/handoffs/YYYY-MM-DD-HHMM-<slug>.md`. Set the frontmatter:

- `status: open`.
- `session:` the session doc path once `/v-capture` has run, otherwise empty.
- `plan:` the plan file this work runs against, otherwise empty.
- `continues:` the slug of the newest handoff that is still `status: open` before this one is
  written, otherwise empty. This is what lets `/v-handoff resume <slug>` walk backwards through the
  earlier handoffs of a task that spans several nights.

Then run `$VAULT_FRAMEWORK_PATH/bin/doc-lint.sh <the file>` and fix what it reports.

### Step 4 — Offer the capture

A handoff is not a capture. Offer `/v-capture` in one line and drop it on a no.

---

## Mode 2 — `/v-handoff resume [<slug>]`

1. **Select.** With no slug, take the newest file in `<vault>/handoffs/` whose frontmatter reads
   `status: open`. With a slug, take that file. A file carrying no `status:` key is unreadable rather
   than absent — list it as unreadable and keep going, never skip it silently.
2. **Refuse cleanly when there is nothing open.** Say so and stop; do not fall back to the newest
   `resumed` file, which is work somebody already picked up.
3. **Read the chain.** Follow `continues:` backwards and print each earlier handoff's slug and goal,
   newest first. Stop at an empty key. A link naming a file that is not there ends the walk and is
   reported — a broken chain is stated, never passed over.
4. **Load what it points at.** The `plan:` file, the `session:` doc, and every file named in
   `## Left to do` and `## Do not touch`.
5. **Set `status: resumed`** in the frontmatter of the file you picked up, so the next run does not
   select the same work twice.
6. **State the next command**, from `## Next command`, and the top three rows of `## Left to do`.

**Ask the operator nothing the file answers.** Re-asking for the goal, the constraints or the next
step means the handoff failed and the file is the thing to fix.

---

## Mode 3 — `/v-handoff list`

One line per file in `<vault>/handoffs/`, newest first: slug, `status`, the goal, and the count of
rows left in `## Left to do`. Open ones first.

---

## Required output — to the user

```
Handoff: <path to the file>
Left: <N> items, first is <the first row's action>
Do not touch: [each item, one line — never omitted, never summarised]
Unverified: [each item, one line — never omitted]
Blockers: [what stops the work, and who unblocks it]
Next: <the exact command>
```

**Omit any line with nothing to say.** The omit rule cuts good news and keeps every warning: `## Do
not touch`, `## Unverified` and `## Blockers` are surfaced in full whenever they carry anything, and
a handoff written without the vault syncing says so.

On `resume`, print the same block plus the chain of earlier handoffs, and nothing else.
