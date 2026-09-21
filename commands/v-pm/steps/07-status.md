# status mode — `/v-pm status`

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

The cross-feature inbox. One sweep so nothing orphans. **No writes.**

## S.1 Sweep — threads
For every `~/vault/_features/*/` (skip `_done/`), scan `conversation/` filenames — state is encoded in
the name, so no file needs opening for status:
- `*_OPEN_→<proj>.md` — a question waiting on project `<proj>`.
- `*_OPEN_→pm.md` — a decision waiting on you (`/v-pm reconcile <feature>`).
- `*_ANSWERED_<answerer>.md` — a reply the asking side may not have seen yet.

## S.2 Sweep — progress, from the shard rows
Read each `projects/*/plan.md` `## Sessions` table and count rows by `status`, leaving out a row with an empty `id`. **The shard rows are the
truth.** Do not report progress from `header.md`: that field is written once at seeding and goes stale,
which is exactly how a feature reads `planning` while its own shards read `done`.

Bound the read — open shards only for features whose row rollup is not already `done`. A feature whose
every row is `done` needs no further reading.

Run `$VAULT_FRAMEWORK_PATH/bin/gate.sh master <shard> 2>&1` on each shard you open. Drop the `master: ok`
line and the `gate: N refusal(s)` line, and keep each line that starts `REFUSED master`. Exit 2 gives one
line naming the shard. A shard whose Sessions header has no `depends` column gives one line,
`Contract gap: <feature>/<proj> has no depends column; its /v-team session adds it`.

Derive per feature:
- **Progress** — `<done>/<total>` rows, plus how many are `dropped`.
- **REQ coverage** — which `REQ-NN` ids from `## Business rules to satisfy` appear in a `done` row's
  covered-ids field, and which appear in none.
- **Not started** — every row `todo`, or no rows at all against a non-zero appetite.

## S.3 Flag what is wrong, not what is normal
Four exceptions earn a line each; everything else stays silent:
- **Header disagrees with its shards** — `header.md` says one thing, the rows say another. Name both.
  This is a defect in the file, not in the work: `/v-capture` rolls the field up on the way out, so a
  disagreement means a session closed without capturing.
- **Never started** — a feature with an appetite and no row past `todo`. Say how long it has sat.
- **Done without evidence** — a `done` row whose evidence field is empty. It cannot be trusted as done.
- **Contract gap** — a `REFUSED master` line from S.2: a dependency with no contract row, or a name the
  Sessions table lacks. Group it under `→<proj>`: that project's `/v-team` session writes the row.

## S.4 Staleness
Age each OPEN thread and each `doing` row by its `last touched` date (fall back to file mtime).

## S.5 Print one digest
```
FEATURE            PROGRESS   REQ COVERED   WAITING ON   THREAD / FLAG                        AGE
saved-filters      3/7        8/11          api          frontend: pagination fields missing  2 opens
saved-filters      —          —             pm           contract: enum values?               1 open
team-billing       5/5        12/12         —            header says planning, rows say done  —
public-events      0/4        0/9           —            never started                        14 days
saved-filters      —          —             api          Contract gap: S3 depends on S2 …     —
```
Group by feature; lead with `→pm` (your action), then the file-level flags from S.3, then stale
`→<proj>` threads. If nothing is open and nothing is flagged: "No open threads across N features."
This is the human-out-of-the-bus surface — run it whenever you want to know what is blocked without
opening every session.
