---
type: persona-group
group: review
tags: [persona, shared, review]
---

# review — the /v-cr seat group

`/v-cr` seats these five lenses (`personas/_resolution.md` §2.4). Each owns one question a linter cannot
answer. Each receives the diff, the task when one exists, and its slice of the change's relation map:
`bin/change-map.sh slice --map <map> --persona <lens file>`. The script header defines every map row.

A slice opens with a `map-status` line. `capped` or `partial` there, or a closing `withheld: <n> rows`,
means the slice is incomplete: a missing row then proves nothing. A seat reads an off-diff file at the
head ref with `git show <head>:<path>` when no checkout of the head exists.

## Seats, in priority order

| seat | owns | does not own |
|---|---|---|
| [[change-impact]] | callers, referrers and companion files the change leaves wrong | whether the changed code itself is correct → `correctness` |
| [[test-gap]] | changed behaviour with no test; changed tests that pass for the wrong reason | test style and level → the testing group under `--sandbox` |
| [[architecture-fit]] | layer, dependency direction, file placement, a contract change the repo's records forbid | how sibling files do the same job → pattern-conformance; whether each consumer still works → change-impact |
| [[pattern-conformance]] | whether new code follows the way sibling files already do the same job | layering → architecture-fit; reuse of a symbol → evidence kind 1 of `commands/_shared/critic-panel.md` (e) |
| [[intent-trace]] | each task requirement against the diff; behaviour the task never asked for | whether delivered behaviour is bug-free → `correctness` |

## Evidence table

A finding is `confirmed` only with the evidence in its seat's row. Without it, the finding is `advisory`
and at most MINOR. This table replaces the four design-evidence kinds of `commands/_shared/critic-panel.md`
(e) for these seats.

| seat | confirmed with |
|---|---|
| change-impact | the affected `path:line` at head, plus the changed line it now disagrees with. A `co-change` row grounds an advisory finding only. |
| test-gap | a `test … none` row plus a cited `git grep -w <symbol> <head> -- <test dirs>` that prints nothing; or a test line and its subject line that show the wrong reason |
| architecture-fit | an architecture record, ADR or indication `path:line`, or an analyzer row, plus the changed line that breaks it |
| pattern-conformance | two `path:line` outside the changed lines that show the pattern, plus the changed line that departs from it |
| intent-trace | the requirement quoted from the task, plus a diff anchor, or a cited grep that shows the requirement's absence |

## Where a finding points

A finding's `target` is a changed line, because a forge refuses an inline comment outside the diff. The
off-diff `path:line` goes in `check`. A file a seat reads in full outside the changeset gets a `context`
row in `FILES_EXAMINED`.

## Exclusions

Every seat drops:
- an issue on a line the diff neither changed nor made wrong;
- style, naming and formatting;
- anything a static-output line already reports;
- a speculative "this may break something" with no named code path.

## Overlays

A resolved stack pack's architect persona becomes the architecture-fit overlay: its checklist and analyzer
add to the seat. With no pack resolved, the five seats run without overlays.
