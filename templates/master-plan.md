<!-- Master-plan sections. Append both after `## Sequencing & dependencies` of a plan built from
     templates/plan.md when the scope splits into two or more sessions that each write their own plan
     file. `bin/gate.sh master <plan>` reads them; it treats a plan as a master when `## Sessions`
     holds a table with `id` and `status` columns. This file owns the rules below; steps and plans
     point here. Keep every comment line free of a leading heading marker, since the gate reads
     the first line that starts a new section as the end of a table. -->

## Sessions
<!-- One row per session. Each session writes its own plan and names this file in its frontmatter:
     `session_of: <this file name>#<id>`, or an absolute path. The master file is the authoritative
     copy of every row.

     status  — one of todo | doing | done | dropped. Only `done` means the session produced its
               contracts. The closing session sets its own row to `done` and fills `evidence`.
     depends — ids of sessions that must finish first, separated by commas or spaces; empty when none.
               This column is the only source of dependencies. `## Sequencing & dependencies` holds
               order and external waits, never a second copy of `depends`.
     A dependency needs a contract row: produced by the depended-on session, consumed by this one.
     A row has the same number of cells as the header. -->

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
