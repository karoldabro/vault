<!-- Master-plan sections. Append all four after `## Sequencing & dependencies` of a plan built from
     templates/plan.md when the scope splits into two or more sessions that each write their own plan
     file, in this order: Goal fit, Goal cases, Sessions, Cross-session contracts. Add
     `goal_fit: required` to the plan's frontmatter. `bin/gate.sh master <plan>` and
     `bin/gate.sh goal <plan>` read them; a plan is a master when `## Sessions` holds a table with `id`
     and `status` columns. This file owns the rules below; steps and plans point here. Keep every
     comment line free of a leading heading marker, since the gate reads the first line that starts a
     new section as the end of a table.

     Opt-in: every rule marked [goal_fit] applies only when the frontmatter holds
     `goal_fit: required`. A master without the key gets one `note` line from `gate.sh goal` and
     nothing else. -->

## Goal fit
<!-- [goal_fit] Whether finishing every session meets the operator's goal. One row per field; every
     value is filled before approval. `bin/gate.sh goal` refuses a missing row or a bad value.

     goal             — value: the id of one `## Success criteria` row, the operator's goal.
                        evidence: the command that decides it, in backticks. The same command appears
                        in the criterion text, and its first word is no document path (.md .json
                        .yaml .yml .csv .txt). With a `how` column the row reads `command`; with a
                        `kind` column it reads `delivery`.
     runtime limit    — value: `<number> min` or `<number> h`, set by the operator at intake: the most
                        one run of the goal command, with the runs it needs first, may take.
     runtime estimate — value: same form. evidence: where the estimate comes from (a measured run, a
                        per-case time times the case count). An estimate over the limit is refused;
                        cut the goal or raise the limit, and say which in `## Open & deferred`.
     failure paths    — value: the number of paths. evidence: at least two paths separated by `;`,
                        each naming a session id, a criterion id or a `path:line` it rests on. Written
                        as a hunt for how the finished plan still misses the goal; no percentage.
     baseline         — the first run of the goal command: its date and exit code. Written by the
                        session that first builds the command; empty until then. -->

| field | value | evidence |
|-------|-------|----------|
| goal | | |
| runtime limit | | |
| runtime estimate | | |
| failure paths | | |
| baseline | | |

## Goal cases
<!-- [goal_fit] Every case the goal command needs, or one row per group of cases that do not exist
     yet. `bin/goal-trace.sh <plan>` prints `owned N/M` from the counts; `gate.sh goal` refuses below
     100%.

     id     — G-<n>, unique.
     case   — the case or the group, in words the goal command's output uses.
     count  — how many cases the row stands for; a positive whole number.
     owner  — the session id that builds the row, a row of `## Sessions` whose status is not
              `dropped`. A case the operator does by hand is owned by `operator` and has a row in
              `## Open & deferred`. Empty means unowned.
     status — `todo` or `pass`. A session changes only the rows it owns. -->

| id | case | count | owner | status |
|----|------|-------|-------|--------|
|    |      |       |       | todo   |

## Sessions
<!-- One row per session. Each session writes its own plan and names this file in its frontmatter:
     `session_of: <this file name>#<id>`, or an absolute path. The master file is the authoritative
     copy of every row.

     status  — one of todo | doing | done | dropped. Only `done` means the session produced its
               contracts. The closing session sets its own row to `done` and fills `evidence`.
     depends — ids of sessions that must finish first, separated by commas or spaces; empty when none.
               This column is the only source of dependencies. `## Sequencing & dependencies` holds
               order and external waits, never a second copy of `depends`.
     Optional columns, read by name, used by a /v-pm feature plan (templates/feature-plan.md):
     repo      — the absolute path of the repo the session's command runs in.
     req       — the REQ-NN ids of requirements.md this session satisfies. Only /v-pm writes it.
     deviation — scope cut, work added, or a row smaller than written. The executing session writes
                 it; a recorded deviation is the tracker working.
     A dependency needs a contract row: produced by the depended-on session, consumed by this one.
     A row has the same number of cells as the header.

     [goal_fit] Deferred work. A `scope` cell of a row that is not `done` or `dropped` may not hold
     these phrases, matched without regard to case: `append rows`, `for the rest`, `the rest of the`,
     `remaining cases`, `remaining rows`, `basic version`, `skip for now`, `wired later`,
     `placeholder for`. A phrase passes when `for <id>`, `owned by <id>` or `→ <id>` follows it and
     names another session whose status is `todo` or `doing`.

     [goal_fit] Session size. Each row of a brief's `## Left to do` table is one change; one row may
     cover many files through a glob, such as `docs/**/*.md`, when it makes the same edit in each.
     Two `todo` sessions of one repo, with no other open or done row of that repo between them, are refused when their
     changes add up to at most `session_max_changes` (the repo's `VAULT.md`, default 15): merge them.
     A plan whose frontmatter says `tier: small` and which has two or more sessions is refused unless
     every session after the first carries `split: <reason>` in its scope. The same `split:` text lets
     a pair pass the merge check. Reasons: `other repo`, `outside wait`, `over limit`, `risk apart`.
     Sessions without briefs are not size-checked. -->

| id | scope | command | status | depends | date | evidence |
|----|-------|---------|--------|---------|------|----------|
|    |       |         | todo   |         |      |          |

## Cross-session contracts
<!-- What one session hands to another, fixed now so the consumer does not redefine it. The producing
     session may add to a shape and never renames or drops part of it.

     id          — C-<n>, unique in this plan.
     contract    — the artifact or interface, in words a consumer recognises.
     produced by — session ids, separated by commas or spaces.
     consumed by — session ids, separated by commas or spaces.
     shape       — the exact path, command, columns or format, copied from the producer's scope. A
                   placeholder is a defect: the consumer builds against this cell.

     Every id in `produced by` and `consumed by` is a row of `## Sessions`. A session that consumes a
     contract starts after its producer is `done`: `bin/gate.sh master` on that session's own plan
     refuses otherwise, naming the contract, the producer and its status.
     With no dependencies the table keeps its header and holds no rows. -->

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
|    |          |             |             |       |

<!-- Row for `## Artifact lifecycles` of the master plan. Copy it and fill the paths. The row is indented so the gate does not read it as a contract.

    | the `## Cross-session contracts` table of this plan | `bin/gate.sh master` reads it, and each session's own plan meets it at step (a) | the PROPOSE session that writes the plan or splits the sessions | `bin/gate.sh master`, and the PROPOSE session of each later session | a dependency with no row exits 1 naming the pair; a contract naming a missing session exits 1 naming it |
-->
