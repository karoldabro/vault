---
type: instruction
campaign: {{slug}}
tags: [campaign, defects]
---

# {{slug}} — defects and their fixes

One row per defect and the fix that closed it. The first five columns match
`vault/defect-ledger.md`, so `bin/gate.sh recurrence` grades a campaign the way it grades a session.

A repair with no check that failed before it is a claim. The `test` cell must name a path, and
`recurrences` starts at 0 and rises when the class comes back.

**The column is spelled `test` whatever the adapter calls its check.** `bin/gate.sh` finds it by that
literal name at line 407 and dies without it.

**A defect is filed only after it survives a check against current source.** Disproving a filing is
worth as much as fixing one.

**A credential reaches this file as a path.** The connection string, key or password itself must
stay where it lives.

| id | defect | repair | test | recurrences | verification | rollback | commit |
|----|--------|--------|------|-------------|--------------|----------|--------|
|    |        |        |      | 0           |              |          |        |

`verification` carries the output of the run that proved the fix. Whether a second agent must produce
it depends on the verifier: a command may be re-run by the agent that did the work and by the
orchestrator, and the two must agree; a model always verifies in a separate spawn
(`commands/v-loop/adapters.md`). `rollback` names the exact revert.
