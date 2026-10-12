# status mode — `/v-pm status`

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

The cross-feature inbox. One sweep so nothing orphans. It writes only the done lines of S.4.

## S.1 Sweep — threads
For every `~/vault/_features/*/` (skip `_done/`), scan `conversation/` filenames — state is encoded in
the name, so no file needs opening:
- `*_OPEN_→<proj>.md` — a question waiting on project `<proj>`.
- `*_OPEN_→pm.md` — a decision waiting on you (`/v-pm reconcile <feature>`).
- `*_ANSWERED_<answerer>.md` — a reply the asking side may not have seen yet.

Also sweep each participant's `<project-vault>/plans/*/plan.md` for single-repo feature plans.

## S.2 Sweep — progress
Resolve each feature's tracker as `$VAULT_FRAMEWORK_PATH/commands/_shared/feature-pickup.md` §0.1 does.

- **`plan.md` present** → run `$VAULT_FRAMEWORK_PATH/bin/pm-plan.sh order <plan>` and
  `$VAULT_FRAMEWORK_PATH/bin/pm-plan.sh check <plan>`. Keep each `REFUSED pm` line.
- **Legacy workspace** → read each `projects/*/plan.md` `## Sessions` table and count rows by
  `status`, leaving out a row with an empty `id`. Run `$VAULT_FRAMEWORK_PATH/bin/gate.sh master <shard>`
  and keep each `REFUSED master` line. Add one line: `legacy layout: /v-pm reconcile <feature>`.

Open only features whose rows are not all `done`. Derive per feature: progress `<done>/<total>` plus
`dropped`; the runnable sessions; REQ coverage from the `req` cells of `done` rows.

## S.3 Flag what is wrong, not what is normal
One line each; everything else stays silent:
- **Header disagrees with its rows** — `header.md` says one thing, the rows another. Name both.
- **Never started** — every row `todo`. Say how long it has sat.
- **Done without evidence** — a `done` row with an empty `evidence` cell.
- **Plan defect** — a `REFUSED pm` or `REFUSED master` line, grouped under the repo whose session
  writes the fix.

## S.4 Close the feature's done lines
When every row of a `plan.md` is `done` or `dropped`, fill the `state` and `evidence` of DD-2 to DD-4
from the rows' evidence, and each success criterion's `verdict` from the session plans that graded it.
Write them with one commit through `bin/vault-sync.sh push`. A criterion with no verdict stays open
and is printed.

## S.5 Staleness
Age each OPEN thread and each `doing` row by its `date` cell (fall back to file mtime).

## S.6 Print one digest
```
FEATURE            PROGRESS   RUNNABLE   WAITING ON   THREAD / FLAG                        AGE
csv-export         1/3        S2         api          admin: pagination fields missing     2 opens
csv-export         —          —          pm           contract: enum values?               1 open
public-events      0/4        S1         —            never started                        14 days
saved-filters      —          —          —            legacy layout: /v-pm reconcile       —
```
Lead with `→pm` (your action), then the file-level flags of S.3, then stale `→<proj>` threads. If
nothing is open and nothing is flagged: "No open threads across N features."
