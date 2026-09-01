---
type: project-shard
feature: {{feature}}
project: {{project}}
status: todo   # todo | in-progress | done
---

# {{feature}} — {{project}} plan

This project's detailed plan. **Self-contained** (BMAD): it carries enough context to act without
re-reading everything. Written by this project's `/v-team <feature>` session, not by `/v-pm` — **except
two things `/v-pm` seeds and `/v-team` must preserve: the `## Business rules to satisfy` ids, and the
`## Sessions` appetite line.** `/v-pm` never writes a session row; this project's session owns every one.

## Business rules to satisfy (from requirements.md — REQ-NN id refs)
<!-- SEEDED BY /v-pm (one of the two sections it owns here). The `requirements.md` business-rule ids this
     project is responsible for satisfying — id refs only, never copied rule text (requirements.md is the
     source). /v-team PRESERVES the ids and never overwrites them.
     Coverage is NOT recorded here — it lives in the `## Sessions` table's `REQ covered` column, so one
     fact has one home. Keep these ids OUT of `## Consumed contract` so the Step-0 drift check still
     diffs cleanly. -->
- REQ-NN <!-- , REQ-NN … seeded by /v-pm; /v-team preserves, never removes -->

## Sessions
<!-- The tracker, and it lives HERE — in the shard the executing session already opens — because a
     tracker in a file nobody is made to read stops being updated. /v-pm seeds the appetite line and this
     header only, with NO rows; this project's /v-team session writes and maintains every row.
     Keep this table OUT of `## Consumed contract`: the Step-0 drift check is a mechanical field-by-field
     compare of that section against contracts.md, and a second table inside it produces false drift.

     Appetite: N sessions (from ../../generic-plan.md). It is a CEILING — fit inside it by cutting
     [could] then [should] rules, never by exceeding it.

     status  — exactly one of: todo | doing | done | dropped. No other value.
     command — exactly one of: /v-do | /v-work | /v-team, plus a half-line reason. NOT /v-ask, which
               writes nothing and so can never close a row. Ladder: vault/indications/light-command-siblings.md.
     evidence — a commit hash or session-record path. A `done` row with an empty evidence cell is
               INVALID: that is how four sessions once passed against a code path that could not run.
     last touched — the date the row last changed. This is what makes a stale row visible.
     deviation — scope cut, work added, an item not built, a row that turned out smaller than written.
               Recording the deviation IS the tracker working; a row that drifts silently is the defect.
     Closing a row is governed by commands/_shared/definition-of-done.md. -->

Appetite: <N> sessions.

| id | scope | command | status | REQ covered | evidence | last touched | deviation |
|----|-------|---------|--------|-------------|----------|--------------|-----------|
|    |       |         | todo   |             |          |              |           |

## What this project does for the feature
<!-- This repo's slice of the generic plan. -->

## Consumed contract
<!-- The exact endpoints / enums / shapes from ../../contracts.md this project depends on. The Step 0
     drift check compares THIS against contracts.md — keep it field-accurate. -->

## Constraints & rationale

## Tests to guard the behavior

## Up-links
<!-- → ../../generic-plan.md · → ../../contracts.md · related threads in ../../conversation/. -->
