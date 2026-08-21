---
type: plan
project: vault
slug: doc-lint-skip-and-type
repos: [vault]
status: executed
tags: [plan]
---

# doc-lint-skip-and-type — plan

## Task

Make every `bin/doc-lint.sh` check suppressible by name, and stop the type resolver from corrupting
type names. Keywords: `doc-lint`, `SIZE1`, `DOC_LINT_SKIP`, `.doc-lint`, `cap_for_type`.

## Open & deferred

- Open, needs the operator: `tests/unit/document-standard.bats:306` ("an unrecognised type is
  reported") fails, and failed before this change. The test wants the "unknown type" note on a
  document with no other finding; `bin/doc-lint.sh` deliberately prints it only alongside a real
  finding, because a notice on a clean file is the noise that gets a linter switched off. One of the
  two is wrong and the choice is a design call, not a repair. Across the vaults ~60 documents carry
  a type `is_known_type` does not list, so printing on clean files is not a rare event.
- Open: `tests/unit/document-standard.bats:348` (`--compare` names `VP8X`) fails, and failed before
  this change. `prohibitions()` in `bin/doc-lint.sh` lowercases every line it reports, so the
  "restore this constraint" output names `vp8x` — an identifier the reader cannot grep for in the
  code it refers to. Fix is to keep the original case for display and lowercase only for matching.
- Deferred: `runbook` is not in `is_known_type`, so `vault/runbooks/*.md` and `type: runbook` docs
  take the fallback cap 400 and print the "unknown type" note. Four such docs exist across the
  vaults. Adding a `runbook` cap is a separate decision about what that cap should be.
- Deferred: `type: analysis`, `type: strategy`, `type: reference` and 20 other one-off types are
  unknown to `is_known_type` and take cap 400. Same separate decision.

## Verified current state

- `SIZE1` fires regardless of `--skip SIZE1`, `DOC_LINT_SKIP=SIZE1`, or a `.doc-lint` line ·
  reproduced on a 203-line `type: indication` file · 2026-08-21.
- `DUP1` and `LONG1` have the same defect · `--skip DUP1` on a file with a 4× repeated line still
  exits 1 · 2026-08-21.
- `check_patterns` is the only caller that consults `is_skipped`, at `bin/doc-lint.sh:221`.
- `doc_type="${doc_type%s}"` at `bin/doc-lint.sh:375` strips a trailing `s` from every type, from
  frontmatter and folder name alike. It corrupts `process` → `proces` and `corpus` → `corpu`.
- The `process` cap of 250 has therefore never been applied to any document · a 303-line
  `type: process` file exits 0 today · 2026-08-21.
- 11 `type: process` documents exist across `~/vault` and this repo; the longest is 227 lines, so
  restoring the 250 cap produces zero new findings · counted 2026-08-21.
- 5 `type: requirements` documents rely on plural→singular folding to reach the `requirement` cap;
  the replacement map must keep that mapping.

## Decisions

- Guard inside `finding()` rather than at each call site — one place cannot be forgotten by the next
  check that gets added.
- `finding()` also calls `header`, replacing the four `header; finding` call-site pairs — a skipped
  finding must not leave a header line behind.
- Replace the blind `%s` strip with an exact plural→singular table — the string operation cannot
  tell a plural folder name from a singular type ending in `s`.
- The table maps folder names and frontmatter values alike, and passes anything unlisted through
  unchanged — an unknown type keeps its real name in the "unknown type" note.

## Scope & non-goals

Covers `bin/doc-lint.sh` and its test file. Does not change the pattern table, the caps themselves,
`is_known_type`, the hook, or `.doc-lint`.

## Work items

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
| W1 | `bin/doc-lint.sh` | `finding()` returns early when `is_skipped "$1"`, before incrementing `violations`; it calls `header` itself | Edit | must not exit under `set -e` when `is_skipped` returns 1 | `--skip SIZE1` on a 203-line indication exits 0 | DONE |
| W2 | `bin/doc-lint.sh` | delete the four `header` calls that precede `finding` (lines 226, 238, 255, 419) | Edit | a file whose only finding is skipped prints nothing | skipped-only file produces empty output | DONE |
| W3 | `bin/doc-lint.sh` | replace `doc_type="${doc_type%s}"` with a `singularize_type()` case table | Edit | keeps `requirements`→`requirement`, `plans`→`plan`, `decisions`→`decision`, `indications`→`indication`, `features`→`feature`, `sessions`→`session`, `processes`→`process`, `runbooks`→`runbook`, `trails`→`trail`, `adrs`→`adr`, `logs`→`log` | `type: corpus` reports `corpus`; `type: process` gets cap 250 | DONE |
| W4 | `tests/unit/document-standard.bats` | add the four regression tests below | Write | each must fail against the current script | `tests/run.sh` green | DONE |

## Rollback

`git revert` of the single commit. Nothing persists outside the two files; no state, no migration.

## Test plan

Harness: bats-core inside the container, `tests/run.sh` (never on the host).
Location: `tests/unit/document-standard.bats`, beside the existing exemption tests.

| # | scenario | asserts |
|---|----------|---------|
| T1 | 203-line `type: indication` with `--skip SIZE1`, then `DOC_LINT_SKIP=SIZE1`, then a sibling `.doc-lint` carrying `SIZE1` | exit 0 each time, and exit 1 with no exemption |
| T2 | file whose only finding is a skipped `SIZE1` | output is empty — no orphan header line |
| T3 | `--skip DUP1` on a 4× repeated long line; `--skip LONG1` on a 40-word sentence | exit 0 each |
| T4 | `type: corpus` with `--force` | the "unknown type" note names `corpus`, not `corpu` |
| T5 | 303-line `type: process` | exit 1 with `SIZE1` and `cap 250` |

Fault named for each pass case: T1 passes vacuously if the file were under cap, so it is 203 lines
against a cap of 80. T5 passes vacuously if `process` were unknown, so it asserts the number 250.

## Refs

- `commands/_shared/document-standard.md` — the rules this linter enforces; unchanged here.
- `vault/decisions/ADR-023-document-writing-standard.md` — the decision that created the linter and
  named per-repo exemption with a reason as a shipping requirement.
- `vault/indications/document-writing-standard.md` — "precision before coverage": a check that
  cannot be exempted is the failure mode that gets the tool switched off.
- `.doc-lint` — this repo's own exemption file, the mechanism defect 1 breaks.
