---
type: session
project: vault
date: 2026-10-12
topic: v-pm-planning-loop
files_touched: [personas/_shared/planning/, personas/_resolution.md, templates/feature-plan.md, templates/master-plan.md, templates/handoff.md, bin/pm-plan.sh, commands/v-pm.md, commands/v-pm/steps/, commands/_shared/feature-pickup.md, commands/_shared/elicitation.md, commands/v-work.md, commands/v-work/steps/05-commit-capture.md, commands/v-team/steps/03-propose-loop.md, docs/cross-project-workspaces.md]
decisions: [ADR-033]
tags: [session, v-pm, planning, personas]
---

# v-pm-planning-loop

## Goal
Rework `/v-pm` into a read-only planner that runs a parallel critique loop with planning reviewers and ends with a plan split into sessions, each with a paste-ready run line.

## Did
- Researched seven reviewer areas online; notes kept in `vault/research/v-pm-planning-lenses/`.
- Ran `/v-team` on the change: two review rounds, four reviewers each; plan `vault/plans/2026-10-12-0944-v-pm-planning-loop.md`.
- S1 `5d8e9b4`: eight lenses in `personas/_shared/planning/` plus README (tiers, grounding); `_resolution.md` §2.3.
- S2 `1e652b8`: `templates/feature-plan.md`, brief keys on `templates/handoff.md`, `bin/pm-plan.sh check|order|set`, fixtures and tests.
- S3 `a12c16e`: `/v-pm` steps rewritten — success-criteria refusal, scale tier, read-only code orientation, parallel panel, approval gate.
- S4 `b08a3a9` + `1d9adca`: `commands/_shared/feature-pickup.md` as Step 0 of `/v-work` and `/v-team`; close step 5.1a; step `(f3)` deleted.
- S5 `ceabdc2`: retired `generic-plan.md`, `planning-session.md` and the shard tracker; ADR-033; indication `pm-plans-sessions`.

## Learned
- `tests/run.sh` runs only its first argument; pass one bats file per call.
- `awk -v` strips a backslash before `|`; pass values through `ENVIRON` to keep `\|` escapes.
- `git add` with one missing path stages nothing; the staging hook refuses `--amend`, so a follow-up commit was needed for S4.
- zsh does not word-split `set -- $s`; run such loops under `bash`.
- 11 unit tests fail on `e292f48`, before this work; the full suite after it fails the same 11.

## Behaviors & rules
- No operator success criterion → `/v-pm` intake refuses with a drafted WHEN/SHALL line; edge: an explicit yes counts, silence does not.
- A plan row without exactly one brief, or a run line naming another repo or command → `bin/pm-plan.sh check` exits 1.
- A contract whose consumer does not list its producer in `depends` → `check` exits 1, so `order` and `gate.sh master` agree.
- A session whose dependency is not `done` → feature pickup ends it; edge: a dropped dependency reads `blocked`.
- Two concurrent `pm-plan.sh set` calls on one plan → both rows land (`flock`).

## Next
- Operator: SC-7 — paste one run line from `tests/fixtures/pm/valid/briefs/` (after replacing `@DIR@`) and confirm Step 0 fires.
- `~/vault/_features` has no upstream; claims and closes stay local until it gets one.
- Legacy workspaces (`empty-feed-activation`, `feature-requests`, `city-location-gating`, `ask-digitally`) convert only through `/v-pm reconcile`.

## Refs
- [[../plans/2026-10-12-0944-v-pm-planning-loop]] — the plan, graders and verdicts.
- [[../decisions/ADR-033-v-pm-planning-loop]] — the decision and every superseded clause.
- [[../indications/pm-plans-sessions]] — the tracker rule.
- [[../features/v-pm]] — the rewritten dossier.
