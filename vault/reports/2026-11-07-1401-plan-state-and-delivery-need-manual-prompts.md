---
type: report
project: vault
slug: plan-state-and-delivery-need-manual-prompts
date: 2026-11-07
status: open
severity: major
found_by: operator, running the device-sync-tests master plan session by session
found_in: digitally-core device-sync-tests plan, ~/vault/digitally-core/plans/device-sync-tests/plan.md and its page https://claude.ai/artifact/GUQCb5PiXLSo6gtCv51zTE
files: [commands/v-work/steps/05-commit-capture.md, commands/_shared/feature-pickup.md, commands/_shared/human-plan.md, bin/pm-plan.sh, bin/render-human.sh]
tags: [report, master-plan, artifact, delivery, automation]
---

# plan-state-and-delivery-need-manual-prompts — report

## What is wrong
After each session of a master plan, the operator must ask by hand for three things: update the master plan, republish its operator page, and merge the session branch into `main`.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `commands/v-work/steps/05-commit-capture.md` | the close sets the master row (`pm-plan.sh set ... status=done`) but neither rebuilds nor republishes the master plan page; it says "Leave pushing to the operator" and has no merge step |
| `commands/_shared/human-plan.md` | covers one plan's human page; a master plan's operator page has no owner, so each session edits or skips it by hand |
| `bin/render-human.sh` | renders a session plan, not a master plan with waves, briefs and results |
| `commands/_shared/feature-pickup.md` | claims the row at start; nothing at close updates the result line, the done pill or the wave readiness the operator reads |

## Consequence
The operator page goes stale after every session unless the operator asks; results, commits and wave readiness on it lag behind `plan.md`. Session branches pile up unmerged (device-tests had `feat/s5a-inventory` merged through `feat/s5b-gotchas`). Two sessions republishing the same page by hand collide: on 2026-11-07 a publish was refused because another session had published in between. Every session costs the operator three extra prompts.

## Cause
The master plan page is a hand-made HTML file with no renderer and no step that owns it. The delivery contract stops at commit and treats the merge as the operator's job, with no command that does it after approval.

## How to see it
Close any session of `~/vault/digitally-core/plans/device-sync-tests/plan.md`: `plan.md` shows the row `done`; the page at https://claude.ai/artifact/GUQCb5PiXLSo6gtCv51zTE does not change until someone republishes it.

## Repair
`/v-work` on the framework:
1. `bin/render-master.sh <plan>` renders the master page (waves from `pm-plan.sh order`, one card per brief, result per done row, reference tables) from `plan.md` and `briefs/`.
2. The close step in `05-commit-capture.md` runs it and republishes to the plan's `human_plan` URL, merging onto the live version when a publish is refused.
3. A close-time delivery step: when the repo's `VAULT.md` declares `delivery_command` and a merge target, ask once at approval whether the session may merge its branch into that target after its checks pass; on yes, merge and push at close. Approval of the plan covers it.

## Not now because
Found at the end of a digitally-core session; the framework is a separate repo.

## Closes when
Closing a master-plan session updates the operator page and, when approved at the gate, merges the branch, with no operator prompt after approval.
