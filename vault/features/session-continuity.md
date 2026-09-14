---
type: feature
project: vault
slug: session-continuity
status: in_progress
owners: []
tags: [feature, handoff, report]
---

# session-continuity

## Scope

Two commands carry work across the boundary of a single session. `/v-handoff` writes what the next
session must continue into `<project-vault>/handoffs/`; `/v-report` writes a problem found during
other work into `<project-vault>/reports/`, so the session that found it does not have to fix it.

Non-goals: promoting a report into a plan, sweeping reports across coupled projects, and writing
either file without the operator asking for it.

## Contracts

| surface | shape |
|---------|-------|
| `commands/v-handoff.md` | modes: write (default), `/v-handoff resume [<slug>]`, `/v-handoff list` |
| `commands/v-report.md` | modes: `/v-report <what>`, `/v-report list [--open]`, `/v-report close <slug> --fixed\|--rejected <reason>` |
| `templates/handoff.md` | `type: handoff`; keys `status` (`open`/`resumed`), `session`, `plan`, `continues`. Eight core sections above six optional ones |
| `templates/report.md` | `type: report`; keys `status` (`open`/`planned`/`fixed`/`rejected`), `severity`, `found_by`, `found_in`, `files`. Eight sections |
| `bin/doc-lint.sh` | `handoff` cap 150, `report` cap 120, both contract class, registered in `cap_for_type`, `singularize_type`, `is_known_type`, `is_document_folder` and the `--list-caps` list |
| `bin/vault-init.sh` | scaffolds `handoffs/` and `reports/` in the standard folder loop |
| `commands/v-work/steps/02-load-context.md` §2.6a | the read path: lists open handoffs and open reports, and prints them as `Handoffs:` and `Reports:` |
| `commands/v-work/steps/05-commit-capture.md` §5.3a | the write path: offers `/v-report` for a problem found outside the task's scope |
| `commands/v-capture.md` | offers `/v-handoff` when work is unfinished |

## Behaviors & rules

- A handoff whose `## Left to do` table is empty → `/v-handoff` refuses and names `/v-capture`.
- `/v-handoff resume` with no `status: open` file → say so and stop; edge: never fall back to a
  `resumed` file, which is work somebody already picked up.
- A handoff picked up by `resume` → its `status` becomes `resumed`, so the next run does not select
  the same work twice.
- `continues:` names the previous open handoff → `resume <slug>` walks it backwards and prints the
  chain; edge: a link naming a missing file ends the walk and is reported, never passed over.
- A problem inside the current plan's scope → it stays in that plan's `## Open & deferred`;
  `reports/` holds only a problem outside the scope of the work that found it.
- A report's finder → `found_by` in frontmatter, never a key in the body; edge: prose explaining the
  rule is allowed, because only the key form is matched.
- `/v-report list` → ordered by `severity`; edge: a value that is none of blocking, major or minor
  sorts last and prints verbatim rather than being dropped.
- A file whose frontmatter reads `type: handoff` or `type: report` → graded at cap 150 or 120 with no
  unknown-type note; edge: a file in `handoffs/` with no frontmatter at all is still a document.
- A repo whose vault predates these folders → the command creates the folder, warns once, and
  continues; it never halts.

## Coupling

None across repos. Both commands read one resolved vault and write inside it.

## Gotchas

- **Three places can hold open work.** A plan's `## Open & deferred`, a handoff's `## Left to do`,
  and `reports/`. `vault-guide.md` §6 states the split; without it the same item lands in two of them
  and one goes unread.
- **`reports/` is not `vault/defect-ledger.md`.** The ledger counts whether a repaired defect class
  came back; a report is the stage before any repair exists. A report closed as fixed in this repo
  adds a ledger row by hand.
- **A handoff is a contract, a session capture is a record.** The handoff states what is still true
  and is read before the next session starts; the capture states what happened.
- **The optional six sections are deleted when empty, never filled with "none".** Writing "none"
  under six headings is the volume that makes the first eight go unread.
- **Both folders are standard, not `add_folders` opt-ins.** `/v-work` reads them on every context
  load, so a folder the lifecycle reads unconditionally has to exist unconditionally.

## Sessions

- [[../sessions/2026-09-14-1904-handoff-and-report-commands]]
