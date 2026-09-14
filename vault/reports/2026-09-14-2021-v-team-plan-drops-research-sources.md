---
type: report
project: vault
slug: 2026-09-14-2021-v-team-plan-drops-research-sources
date: 2026-09-14
status: open
severity: major
found_by: /v-work, building /v-handoff and /v-report
found_in: taking a baseline test run at HEAD to separate pre-existing failures from new ones
files: [commands/v-team/steps/03-propose-loop.md, commands/v-work/steps/03-propose.md, tests/unit/research-clarify.bats]
tags: [report]
---

# v-team-plan-drops-research-sources

## What is wrong

`/v-team` requires its PROPOSE step to research the approach online and cite the sources, and then
names no place for those citations to land. Its Layer 2 block sends "research that did not survive
into the plan" to the trail sidecar and never says the surviving sources go in the plan.
`tests/unit/research-clarify.bats:108` fails looking for that instruction.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `commands/v-team/steps/03-propose-loop.md` | the Layer 2 block at lines 249-257 lists work items, decisions, verified state, open work, the test dossier, the test backlog and vault writes — and no research sources |
| `commands/v-work/steps/03-propose.md` | line 257 does carry it: "The artifact carries: research sources + takeaways". The two lifecycles disagree about the same artifact |
| `tests/unit/research-clarify.bats` | the assertion at line 108 is `tr '\n' ' ' < "${PROPOSE_LOOP}" \| grep -qi 'research *sources'` |

## Consequence

Already happening on every `/v-team` run. The shared PROPOSE gate at §3a.0b tells the session to cite
title, URL and takeaway "so the design is auditable, not asserted", and `/v-team` then writes a plan
with nowhere to put them. The citation is either dropped or filed in the trail sidecar, which is the
process record nobody reads when acting on the plan. A later session cannot check what the approach
was grounded in.

## Cause

The requirement is stated in the shared research gate and in `/v-work`'s own Layer 2 line, and was
never mirrored into `/v-team`'s Layer 2 block. The trail sidecar's line about research that did *not*
survive reads like coverage of the same subject and is the opposite case.

## How to see it

```bash
grep -n 'research sources' commands/v-work/steps/03-propose.md
grep -n 'research' commands/v-team/steps/03-propose-loop.md
```

The first returns line 257. The second returns only the §3a.0b pointer and the trail's
"research that did not survive into the plan".

## Repair

Add research sources to the plan-artifact list in `commands/v-team/steps/03-propose-loop.md` Layer 2,
in the same words `commands/v-work/steps/03-propose.md:257` uses, so the two lifecycles describe one
artifact the same way. Run it with `/v-do`: one line in one file, and
`tests/unit/research-clarify.bats:108` is the test.

Check while there whether `templates/plan.md` has a section for them. If it does not, the sources have
no row to land in and that is a second line of work.

## Not now because

It is a `/v-team` contract change found by a `/v-work` session doing something else, and the template
question above may widen it.

## Closes when

```bash
./tests/run.sh tests/unit/research-clarify.bats
```

passes, and `grep -c 'research sources' commands/v-team/steps/03-propose-loop.md` returns at least 1.
