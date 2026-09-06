---
type: instruction
campaign: {{slug}}
tags: [campaign, defects]
---

# {{slug}} — defects and their fixes

One row per defect and the fix that closed it. The first five columns match
`vault/defect-ledger.md`, so `bin/gate.sh recurrence` grades a campaign the way it grades a session.

A repair with no test that failed before it is a claim. The `test` cell must name a path, and
`recurrences` starts at 0 and rises when the class comes back.

**A defect is filed only after it survives a check against current source.** Disproving a filing is
worth as much as fixing one.

**A credential reaches this file as a path.** The connection string, key or password itself must
stay where it lives.

| id | defect | repair | test | recurrences | verification | rollback | commit |
|----|--------|--------|------|-------------|--------------|----------|--------|
|    |        |        |      | 0           |              |          |        |

`verification` carries the output of the run that proved the fix, produced by an agent other than
the one that wrote it. `rollback` names the exact revert.
