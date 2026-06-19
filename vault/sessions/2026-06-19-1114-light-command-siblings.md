---
type: session
project: vault
date: 2026-06-19
topic: light command siblings — /v-ask and /v-do
files_touched: [commands/v-ask.md, commands/v-do.md, commands/README.md, vault-guide.md]
decisions: []
tags: [session, commands, v-work, v-team, lifecycle]
---

# light command siblings — /v-ask and /v-do

## Goal
Add lighter, no-approval-gate variants of the `/v-work`/`/v-team` lifecycle for context-aware
answers and small low-risk jobs.

## Did
- Built two single-file commands (no step subdirs — "light" = whole file loads at once):
  - [[../../commands/v-ask]] — read-only vault Q&A. Cheapest-first context load (OV → claude-mem →
    indications/MOC → graph → Serena → grep), cites sources, **never edits**; hands off to `/v-do`
    or `/v-work` when the answer implies a change.
  - [[../../commands/v-do]] — small change, no propose loop / no approval gate. A scope **guardrail**
    replaces the gate (architecture/schema/auth/billing/cross-repo → `/v-team`; >~5 files or unclear
    blast radius → `/v-work`; destructive → consent). Keeps `/v-work` §4.2 file-edit rules and
    indications-as-binding-constraints; capture offered but **off by default**; no auto-commit.
- Wired docs: `commands/README.md` table + light-sibling note; `vault-guide.md` §11 reference rows.
- `install.sh` auto-symlinked both (any `commands/*.md` is picked up — no install.sh change). Both
  immediately registered as skills.
- Ran dockerized unit suite: **48/48 green, 0 failures**. The command-count assertion
  (`install.bats:31`) is dynamic (`find … | wc -l`), so new files don't break it.
- Committed `55653c1`.

## Learned
- `install.sh` needs no edit to add a command — it globs `commands/*.md` and the subdir loop handles
  step folders. Drop file + re-run.
- `install.bats` counts commands dynamically, not against a hardcoded number — adding commands is
  test-safe by design.
- Design split that mattered: two commands, not one mode-switching command. `/v-ask` is hard
  read-only (no `Edit`/`Write`/`Morph`/`git`); `/v-do`'s safety valve is the escalation guardrail,
  which is what stands in for the dropped approval gate.
- An untracked `vault/plans/2026-06-19-1106-v-cr-command.md` exists in the tree — not from this
  session; left alone.

## Next
- Consider a `/v-ask`→`/v-do`→`/v-work`→`/v-team` escalation ladder note in the README so the four
  tiers read as one spectrum.
- Watch real use: confirm `/v-do`'s ~5-file / domain guardrail is the right escalation threshold.

## Refs
- [[../../commands/v-ask]]
- [[../../commands/v-do]]
- [[2026-06-16-1038-v-team-persona-critique-command]]
