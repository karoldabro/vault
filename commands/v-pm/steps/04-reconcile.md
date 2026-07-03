# reconcile mode — `/v-pm reconcile <feature>`

Fold what execution learned back into the source of truth, and drain the PM's inbox. Run this when a
project raised a `to: pm` thread, or after a project session changed the seam.

## R.1 Load
Read `~/vault/_features/<feature>/` — `generic-plan.md`, `contracts.md`, and the **derived ledger**
(scan `conversation/` filenames for state; there is no ledger file).

## R.2 Drain `to: pm` threads
For each `THREAD_*_OPEN_→pm.md`: it is a decision that mutates the generic plan or a contract — the one
class auto-pickup can't route. Resolve it; if it needs the user, ask (`AskUserQuestion`, hard-block on a
no-safe-default fork). Apply the decision to `generic-plan.md` / `contracts.md`, then rename the thread
`…_RESOLVED.md` with the disposition appended.

## R.3 Fold execution learnings
If a project discovered the contract was wrong (a `→pm` thread or a contracts-drift flag), update
`contracts.md` — the source of truth — not just the consuming project's copy. Note the change in
`header.md` so the other projects' next pickup sees it.

## R.4 Staleness flag
Any `OPEN` thread older than **N session-opens** (default 3, tracked in `header.md`) that hasn't been
picked up → surface it: "waiting on `<proj>`, not picked up in N opens." Degrade to asking the user
rather than letting it stall silently.

## Required output
```
Drained (to: pm): [threads → decisions applied]
Contract/plan changes: [what moved in generic-plan / contracts]
Stale: [threads waiting on <proj> for N+ opens]
```
