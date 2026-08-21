---
type: session
project: vault
date: 2026-08-21
topic: doc-lint-skip-and-type
continues: [[2026-08-21-1015-document-writing-standard]]
files_touched:
  - bin/doc-lint.sh
  - tests/unit/document-standard.bats
  - vault/plans/2026-08-21-1400-doc-lint-skip-and-type.md
decisions: [ADR-023]
tags: [session]
---

# doc-lint-skip-and-type

## Goal

Fix the two defects that made `bin/doc-lint.sh` unusable on a real project: the size cap could not
be exempted, and the type resolver corrupted type names.

## Did

- Reproduced both defects against `HEAD` before touching anything, and found each was wider than
  reported: `DUP1` and `LONG1` were unsuppressible too, and the trailing-`s` strip also broke
  `process`, not only `corpus`.
- Moved the exemption guard into `finding()` in `bin/doc-lint.sh` — the one function every check
  calls — and made `finding()` print the header itself, so the four `header; finding` call-site pairs
  collapsed to one place.
- Replaced `doc_type="${doc_type%s}"` with `singularize_type()`, an exact plural-to-singular case
  table. Unlisted names pass through unchanged.
- Counted every `type: process` document across `~/vault` and this repo before restoring the cap:
  11 documents, longest 227 lines against a cap of 250, so the restoration added no findings.
- Added six tests to `tests/unit/document-standard.bats`; each fails against the pre-change script.
- Ran the full suite in the container. 413 pass, 12 fail — the identical 12 that fail at `b013cd4`.
- Committed `cb537b2` and pushed to `origin/main`.

## Learned

- The `process` line cap of 250 had never applied to a single document since the linter shipped.
  `${doc_type%s}` turned `process` into `proces`, which matches no cap and no known type, so every
  process document silently took the 400-line fallback and the header advised setting a `type:` that
  was already set.
- The bug hid behind its own symptom: the corrupted type also triggered the "unknown type" note, so
  the header looked like an author error rather than a linter error.
- `is_skipped` was called from `check_patterns` only, which is why exempting a pattern check worked
  and exempting anything else did not. A guard at the call site is a guard the next check forgets.
- Two tests in `tests/unit/document-standard.bats` fail on unmodified `HEAD` and are unrelated to
  this work. `bin/doc-lint.sh` deliberately withholds the "unknown type" note on a file with no other
  finding, while the test at line 306 demands it — the script and its test disagree about the design.
  The test at line 348 wants `--compare` to name `VP8X`, but `prohibitions()` lowercases everything
  it reports, so the output says `vp8x`.
- `set -e` does not kill a function on `is_skipped "$1" && return 0` when the guard is false: bash
  exempts every command in an AND list except the one after the final `&&`.

## Behaviors & rules

- A check code passed to `--skip`, `DOC_LINT_SKIP` or a `.doc-lint` line suppresses that check →
  `bin/doc-lint.sh` exits 0 and prints nothing for it; edge: when it was the file's only finding, no
  header line is printed either.
- A document whose every finding is exempted → output is empty, not a header with nothing under it.
- A type name that ends in `s` and is not a listed plural → the type is reported under its own name;
  edge: `corpus` stays `corpus`, `process` stays `process` and reaches its 250-line cap.
- A document with no frontmatter `type:` in a plural folder → the folder name folds to its singular
  type; edge: `indications/` gives cap 80, `requirements` gives `requirement`.

## Next

- Decide whether `bin/doc-lint.sh` should print the "unknown type" note on an otherwise-clean file.
  The test at `tests/unit/document-standard.bats:306` says yes, the script says no, and ~60
  documents across the vaults carry a type `is_known_type` does not list, so the choice decides
  whether a clean run stays silent.
- Fix `prohibitions()` in `bin/doc-lint.sh` to keep the original case for display and lowercase only
  for matching, so `--compare` names an identifier the reader can grep for.
- Decide caps for `runbook` and the other unlisted types, or accept the 400-line fallback.

## Refs

- [[../plans/2026-08-21-1400-doc-lint-skip-and-type]] — the plan this executed, carrying the two open
  items above as its blockers.
- [[../decisions/ADR-023-document-writing-standard]] — the decision that created the linter and made
  per-repo exemption with a stated reason a shipping requirement; defect 1 broke that mechanism.
- [[../indications/document-writing-standard]] — "precision before coverage": a check that cannot be
  exempted is what gets the whole tool switched off.
- [[2026-08-21-1015-document-writing-standard]] — the session that built the linter these defects
  shipped in.
