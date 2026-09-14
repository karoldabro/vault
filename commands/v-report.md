---
description: File a problem you found while doing something else — what is wrong, what it breaks, what caused it, which files, and the repair — so it can be fixed in a later session instead of derailing this one.
argument-hint: "<what is wrong> | list [--open] | close <slug> --fixed|--rejected <reason>"
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here.

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs the report file this command writes.

# /v-report — file it now, fix it later

`/v-report` writes one file into `<project-vault>/reports/` describing something that is failing,
stale, outdated or plainly wrong, so the session that found it can carry on with the work it was
doing. The report carries enough for a later session to act without re-finding the problem.

**Where a problem goes.** A problem inside the current plan's scope stays in that plan's `## Open &
deferred` section, which is the one place open work for that plan lives. This folder holds only a
problem **outside** the scope of the work that found it. A defect this repo has already repaired goes
to `vault/defect-ledger.md`, which counts whether a repaired class came back; a report is the stage
before any repair exists.

---

## Refusals

| condition | what the command does |
|-----------|----------------------|
| The repo has no resolved vault | say so, name `/v-init` as the command that creates one, and stop |
| The problem is inside the scope of the work in progress | say so, and put it in that plan's `## Open & deferred` instead. Two places holding the same open item is how one of them goes unread |

---

## Step 0 — Resolve the vault

Resolve the vault path per `$VAULT_FRAMEWORK_PATH/vault-guide.md` §1.1. Create `<vault>/reports/`
when it is absent, warn once, and carry on. Never halt for a missing folder.

---

## Mode 1 — file a report (the default)

### Step 1 — Establish the facts before writing anything

Verify the problem against the live files. A report is acted on by a session that will not re-check
it, so a premise that was true last month and is false now costs that session its whole run.

### Step 2 — Fill the three keys and the eight sections

Frontmatter keys, because a name inside a contract body reads as one person's opinion:

| key | what goes in it |
|-----|-----------------|
| `found_by` | the session, command or person that hit it — `/v-work`, `bin/gate.sh`, a test run, the operator |
| `found_in` | what was being done when it surfaced, in one clause. A problem found under a workflow that no longer exists is stale, and this is the only field that shows it |
| `severity` | `blocking`, `major` or `minor` |

Sections:

| section | what goes in it |
|---------|-----------------|
| `## What is wrong` | one sentence, the defect as current truth. Name the thing and the verb |
| `## Files` | every path involved, exact, one row each, with what is wrong in that file. Never "the resources" |
| `## Consequence` | what breaks and who notices, and whether it has already happened or is still latent |
| `## Cause` | why it is this way. When the cause is genuinely **unknown**, write `unknown:` and what you checked that came back empty — an invented cause sends the repair at the wrong target |
| `## How to see it` | the command, path or steps that show the problem, so nobody takes the file on trust |
| `## Repair` | the suggested fix and the command that would run it: `/v-do` small, `/v-work` normal, `/v-team` for architecture, schema, auth, billing or cross-repo. Name the files it would touch |
| `## Not now because` | why it was not fixed when found. A later reader uses this to decide whether the reason still holds |
| `## Closes when` | the observable condition that ends the report — a command that exits 0, a test that passes, a file that stops existing |

### Step 3 — Write the file

Instantiate `$VAULT_FRAMEWORK_PATH/templates/report.md` into
`<vault>/reports/YYYY-MM-DD-HHMM-<slug>.md` with `status: open`, then run
`$VAULT_FRAMEWORK_PATH/bin/doc-lint.sh <the file>` and fix what it reports.

---

## Mode 2 — `/v-report list [--open]`

One line per report: slug, `status`, `severity`, the first sentence of `## What is wrong`, and
`found_in`. **Order by `severity`** — blocking, then major, then minor — and within a severity, newest
first. A value that is none of the three sorts last and is printed as written, so nothing is dropped.
`--open` filters to `status: open`. A file with no `status` key is listed as unreadable, never
skipped.

## Mode 3 — `/v-report close <slug> --fixed|--rejected <reason>`

Set `status: fixed` or `status: rejected` and append the reason to `## Not now because` under the
label `closed:`. `--fixed` requires the condition in `## Closes when` to be observed now — say what
was run and what it returned. `--rejected` requires a reason; a report closed without one is
indistinguishable from one nobody read.

When the repair landed in this framework repo, add the matching row to `vault/defect-ledger.md` by
hand, naming the test that failed before the repair.

---

## How another command offers a report

Any command that hits a failing, stale or incorrect thing **outside the scope of the work it is
doing** shall offer one line and drop it on a no:

```
Found outside this task's scope: <one sentence>. File it as a report? (y/N)
```

The offer is made once per problem, at the point it is found or at the session close, whichever comes
first. Nothing is written without a yes. A command that fixed the problem instead does not offer.

---

## Required output — to the user

```
Report: <path to the file>
Wrong: <the one sentence>
Breaks: <the consequence, and whether it has already happened>
Files: [exact paths]
Repair: <the suggested fix> — run <command>
Cause: [or "unknown", with what was checked]
```

**Omit any line with nothing to say.** An unknown cause and an unreproducible problem are warnings,
not empty fields, and are always printed.
