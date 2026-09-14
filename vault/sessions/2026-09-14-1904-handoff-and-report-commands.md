---
type: session
project: vault
date: 2026-09-14
topic: /v-handoff and /v-report — stop a session without losing it, file what you found
files_touched: [commands/v-handoff.md, commands/v-report.md, templates/handoff.md, templates/report.md, checks/handoff-SC-1.sh, checks/handoff-SC-2.sh, checks/handoff-SC-3.sh, checks/handoff-SC-4.sh, tests/unit/handoff-report.bats, bin/doc-lint.sh, bin/vault-init.sh, vault-guide.md, docs/cross-project-workspaces.md, README.md, commands/v-work/steps/02-load-context.md, commands/v-work/steps/05-commit-capture.md, commands/v-capture.md, vault/check-budget.md, tests/integration/vault-init.bats, tests/unit/communication-contract.bats, tests/unit/v-pm.bats]
decisions: []
tags: [session, handoff, report, commands]
---

# /v-handoff and /v-report — stop a session without losing it, file what you found

## Goal

Add two commands so a long or late session can hand its direction to the next one, and a problem
found mid-task can be filed instead of derailing the work.

## Did

- Wrote `commands/v-handoff.md` and `commands/v-report.md`, with `templates/handoff.md` and
  `templates/report.md`.
- Registered `handoff` (cap 150) and `report` (cap 120) as contract types in `bin/doc-lint.sh`, in
  five places: `cap_for_type`, `singularize_type`, `is_known_type`, `is_document_folder` and the
  `--list-caps` literal list.
- Added `handoffs` and `reports` to the scaffold loop in `bin/vault-init.sh`.
- Added §2.6a to `commands/v-work/steps/02-load-context.md`, which lists every open handoff and open
  report before the first edit, plus two rows to its `### Required output` block.
- Added §5.3a to `commands/v-work/steps/05-commit-capture.md`, the one-line offer to file a report
  for a problem found outside the task's scope, and one line to `commands/v-capture.md` offering
  `/v-handoff` when work is unfinished.
- Moved `vault-guide.md` §13 into `docs/cross-project-workspaces.md`, leaving a pointer. The guide
  sat at exactly its 600-line cap with no room for the new rows; it is now 518 lines.
- Wrote four check scripts and `tests/unit/handoff-report.bats`. Ran the unit suite in Docker: 755
  tests, 4 failures, all four also failing at HEAD `e32a921`.
- Wrote this session's own handoff with the new command:
  `vault/handoffs/2026-09-14-1904-handoff-and-report-commands.md`.

## Learned

- **`bin/doc-lint.sh` prints its header only alongside a finding.** A probe file that lints clean is
  silent, so a check asserting "no unknown-type note appears" passes identically before and after a
  type is registered. `checks/handoff-SC-4.sh` now plants an over-long sentence in its probe to force
  the header, then reads the cap back from it.
- **`grep | head -1` under `set -o pipefail` returns 141 on a large file and 0 on a small one.** head
  closes the pipe, grep takes SIGPIPE, and the pipeline status becomes a failure. The same shape on
  the consuming side — `sed ... | grep -q` — kills the producer when the match is early. Both made
  `checks/handoff-SC-3.sh` pass on the host and fail in the test container, and pass for a match near
  the end of a section while failing for one near the start.
- **A dynamic regex in `awk` is not portable.** `awk -v p="^## 2\\." '$0 ~ p'` matched on the host's
  gawk and silently matched nothing under the container's awk. `grep -m1 -n` plus `sed -n 'a,bp'`
  behaves the same in both.
- **`grep -qF '--open'` is parsed as a grep option.** Any check matching a flag name needs `grep -qF --`.
- **A `*.md` glob over an empty folder aborts the whole command line in zsh**, so the walk that looks
  for open handoffs uses `find ... -exec grep -l`.
- **Another session's `git add <path>` swept an uncommitted edit of this session into its commit.**
  `commands/v-work/steps/02-load-context.md` §2.6a landed in `e32a921`, whose message is about plugin
  defects. `scripts/staging-hook.sh` blocks `git add -A` and `git commit -am`, which is defect D-006
  in `vault/defect-ledger.md`; a named-path add of a file two sessions both touched is not covered.
- **`vault-guide.md` was at 600 lines against a 600-line cap**, so any addition to it failed the
  `PostToolUse` doc-lint hook until §13 moved out.

## Behaviors & rules

- A handoff whose `## Left to do` table is empty → `/v-handoff` refuses and names `/v-capture`;
  edge: a session that finished its work writes only the capture.
- `/v-handoff resume` with no `status: open` file → say so and stop; edge: never fall back to the
  newest `resumed` file, which is work somebody already picked up.
- A handoff's frontmatter `continues:` names the previous open handoff → `resume <slug>` walks it
  backwards and prints the chain; edge: a link naming a missing file ends the walk and is reported.
- A problem inside the current plan's scope → it stays in that plan's `## Open & deferred`;
  `reports/` holds only a problem outside the scope of the work that found it.
- A report's finder → `found_by` in frontmatter, never a key in the body; edge: prose explaining the
  rule is allowed, because only the key form is matched.
- A `/v-report` list → ordered by `severity`; edge: a value that is none of blocking, major or minor
  sorts last and prints verbatim rather than being dropped.
- A file with `type: handoff` or `type: report` → graded at cap 150 or 120 with no unknown-type note;
  edge: a file in `handoffs/` with no frontmatter is still treated as a document.

## Next

- **SC-5 has no verdict and `./bin/gate.sh all <plan> --phase close` refuses on it alone.** It asks
  whether a fresh session resumes from the handoff rather than re-deriving the task, which this
  session cannot observe about itself. Procedure and the plan path are row 1 of
  `vault/handoffs/2026-09-14-1904-handoff-and-report-commands.md`.
- Four test failures predate this work and are unfixed: `tests/unit/document-standard.bats:308`
  (asserts an unknown-type note on a file that produces no finding, so nothing prints),
  `tests/unit/document-standard.bats:350`, `tests/unit/plugin-install.bats:113`
  (`commands/v-reconcile.md` has no frontmatter `description`), `tests/unit/research-clarify.bats:108`.
- `./bin/rule-count.sh` reports 177 rule lines against a budget of 173. Nothing calls it, so it
  refuses nothing.
- `./tests/run.sh tests/integration` was never run; `tests/integration/vault-init.bats` gained an
  assertion this session.

## Refs

- [[../plans/2026-09-14-1642-handoff-and-report-commands]] — the plan, all 21 work items `DONE`,
  SC-1 to SC-4 `MET`.
- [[../handoffs/2026-09-14-1904-handoff-and-report-commands]] — what the next session carries on.
- [[../indications/artifact-has-a-named-consumer]] — the rule that put the read path in §2.6a rather
  than leaving two folders nobody opens.
- [[../indications/unreadable-is-not-no]] — the class the pipefail 141 belongs to: a check that
  cannot read the question must not answer "no".
- [[../defect-ledger]] — D-006, the staging defect a named-path add still reaches around.
