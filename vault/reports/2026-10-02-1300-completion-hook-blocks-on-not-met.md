---
type: report
project: vault
slug: completion-hook-blocks-on-not-met
date: 2026-10-02
status: open
severity: major
found_by: /v-work in agent-control
found_in: closing S1 of the givore-video-loop plan while operator credentials were still missing
files: [scripts/completion-hook.sh, bin/gate.sh]
tags: [report, hooks, gate]
---

# completion-hook-blocks-on-not-met — report

## What is wrong

`scripts/completion-hook.sh` blocks every stop when any criterion of the newest touched approved plan is not `MET`. Its header says it blocks only when a `DONE` work item's covering criterion has no verdict.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `scripts/completion-hook.sh` | runs `bin/gate.sh verdict <plan>` on the whole plan and exits 2 on any gate exit 1; it never filters by `DONE` work items or empty verdicts; the refusal text says "recorded no verdict" even when the verdict is `NOT MET` |
| `bin/gate.sh` | `cmd_verdict` refuses any row whose verdict is not `MET`, which is the close-phase rule, not the "verdict missing" rule the hook claims |

## Consequence

Already happened. In `~/workspace/agent-control`, plan `~/vault/agent-control/plans/2026-10-02-1500-givore-video-loop.md` has `how: observed` rows SC-2 and SC-4 honestly `NOT MET` with evidence, because the operator had not stored credentials. The hook refused at the end of every following turn, including turns that only answered questions. The only exits are faking `MET`, starting a new session, or `COMPLETION=off`. A hook that rewards a false `MET` defeats its own purpose.

## Cause

The hook reuses `gate.sh verdict`, whose contract is "every criterion is MET with evidence" (`bin/gate.sh:15`). The hook's own contract (header lines 11–13) needs "a criterion covered by a `DONE` work item has an empty verdict cell". `stop_hook_active` only prevents a second block within one stop; each new user turn blocks again.

## How to see it

```bash
F=~/.claude/plugins/cache/kdabro-vault/vault/1.11.0
$F/bin/gate.sh verdict ~/vault/agent-control/plans/2026-10-02-1500-givore-video-loop.md; echo $?
# REFUSED SC-2 is NOT MET ... exit 1 → completion-hook.sh exits 2 on every stop
```

## Repair

`/v-do` in `~/workspace/vault`: add a `gate.sh verdict --recorded` mode, or a hook-side filter. It refuses only rows covered by a `DONE` work item whose `verdict` or `evidence` cell is empty. A `NOT MET` row with evidence counts as recorded. Point `scripts/completion-hook.sh` at that mode. Add a test: plan with all work items `DONE`, one `how: observed` row `NOT MET` with evidence → hook exits 0; same row with empty verdict → hook exits 2.

## Not now because

The defect is in the vault framework, outside the agent-control video-loop work that hit it.

## Closes when

The hook exits 0 on a plan whose only non-`MET` rows are `NOT MET` with evidence. It exits 2 when a `DONE`-covered row has an empty verdict. Both cases pass as tests in the framework suite.
