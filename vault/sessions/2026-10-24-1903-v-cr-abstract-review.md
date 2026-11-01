---
type: session
project: vault
date: 2026-10-24
topic: v-cr-abstract-review
files_touched: [bin/change-map.sh, personas/_shared/review/README.md, personas/_shared/review/change-impact.md, personas/_shared/review/test-gap.md, personas/_shared/review/architecture-fit.md, personas/_shared/review/pattern-conformance.md, personas/_shared/review/intent-trace.md, personas/_resolution.md, commands/_shared/critic-panel.md, commands/v-cr/steps/01-detect.md, commands/v-cr/steps/02-gather.md, commands/v-cr/steps/03-review.md, commands/v-cr/steps/05-capture.md, commands/v-cr/adapters.md, tests/unit/change-map.bats, tests/unit/review-personas.bats, tests/fixtures/v-cr-seeded/mk-repo.sh]
decisions: [ADR-035]
tags: [session, v-cr, personas, code-review]
---

# v-cr-abstract-review

## Goal
Make `/v-cr` review what static analysis cannot see: cross-file impact, missing tests, architecture, repo patterns and the ticket. Each reviewer gets one task and a precomputed map of how the changed files relate to the rest of the repo.

## Did
- Researched how review tools split agents and how agents get code context; records in `vault/research/review-agent-splits.md` and `vault/research/review-code-context.md`.
- Added the review group `personas/_shared/review/` (five seats) and the `/v-cr` seat rule `personas/_resolution.md` §2.4; `/v-team` keeps its seats (operator choice).
- Wrote `bin/change-map.sh build|slice|status`: six relations from git objects only, through `probe_git`, excerpts scrubbed by `cr_redact_runtime`.
- Step 1 now fetches `refs/vcr/<n>` and `refs/vcr/<n>-base` through `fetch_ref` outside `--sandbox`; step 2 §2.4a builds the map; step 3 gives each seat its slice.
- C3 delivery run: ten seat spawns on a seeded fixture and a clean control; the scorer re-checks every anchor against rebuilt fixtures. Commits `3bcb85d` (plan, checks) and `15d7155` (implementation).

## Learned
- The test container's `awk` is busybox; it ends a record at NUL, so `git grep -z` output must pass through `tr '\0' '\t'` first. The host's mawk hid this.
- `core.quotePath=false` still C-quotes paths with `"`, `\`, tab or newline; only `-z` keeps them raw.
- A clean control fixture is hard to write: the test-gap seat found the control's untested `bin/report.sh`, a real gap in the fixture, not a false positive.
- architecture-fit and change-impact both claimed "a changed contract's consumers"; the seeded run showed the double vote, and the mandate was narrowed.
- `tests/run.sh` takes one target; a check that passes several files runs only the first.
- `bin/gate.sh all` rejects `--run`, although `commands/v-work/steps/05-commit-capture.md` §5.0 tells the reader to add it.

## Behaviors & rules
- A persona file reaches `bin/change-map.sh slice` without a `map:` key → exit 2 naming the persona; edge: `map: []` prints only the `map-status` line.
- A function body changes → its enclosing definition is a changed symbol. Each whole-word use at head is a `caller` row; edge: a deleted file yields callers from its base definitions.
- A git query fails after the refs resolve → `map-status` reads `partial` with the query named; edge: a `git grep` exit 1 (no match) is not a failure.
- A partner changed with the file in ≥3 commits at confidence ≥0.5 and is missing from the diff → a `co-change` row. It grounds advisory findings only; edge: commits over 30 files add no support.
- A moved file's own definition line is not a `caller` row of the old path.

## Next
- Operator: run `/v-cr --no-post` on one real pull request; no forge path ran this session.
- Bump `.claude-plugin/plugin.json` to 1.15.0 for release (`make release-check` fails only on it).
- The adapters do not say how a renamed file appears in `$CR_CHANGED_FILES`.
- The last code-review fixes (base ref per `Local match` value, `-z` path lists, moved-file caller skip) had no further review.
- The uncommitted `bin/gate.sh` and `tests/unit/gate.bats` edits predate this session and are untouched.

## Refs
- [[../decisions/ADR-035-v-cr-single-task-review-seats]] — the decision this session made.
- [[../plans/2026-10-24-1903-v-cr-abstract-review]] — the plan, every criterion MET.
- [[../features/v-cr]] — the dossier this session updated.
- [[../research/review-agent-splits]], [[../research/review-code-context]] — the research behind the seats and the map.
