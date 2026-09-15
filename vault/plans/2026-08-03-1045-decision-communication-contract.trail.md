---
type: trail
project: vault
plan: 2026-08-03-1045-decision-communication-contract
personas: [ad-hoc: framework-architect, quality, skeptic, exec-communication]
rounds: 2
convergence: capped-at-round-cap   # 0 open blockers; plan rounds 2, diff-review rounds 1
tags: [trail, record]
---

# 2026-08-03-1045-decision-communication-contract — process record

Contract document: `vault/plans/2026-08-03-1045-decision-communication-contract.md`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Rewrite the user-facing output blocks at `v-work/steps/03-propose.md:158-176` and `v-team/steps/03-propose-loop.md:153-165` | Add a presentation layer on top of the existing output mandate | The draft targeted `§3a.4` and `§(g)`, which control no user-facing output; net effect was **+4 blocks on an unchanged 16-line mandate** |
| Delete `commands/v-ask.md:55` outright, no stub | Keep it beside the new contract | Two brevity rules already existed; the contract would have been a third source of truth |
| Keep `v-cr/steps/03-review.md:47` | Delete it as a duplicate of the contract | It governs comments posted to the forge, read by teammates, not by this user |
| Bound R-04 to well-structured domains | Apply the over-explaining penalty unconditionally | The effect does not hold in ill-structured domains, and framework design is one |
| Print `/config` → Output style → *director* in the installer | Print `/output-style` | `/output-style` was removed in Claude Code v2.1.91 |
| Label step 16 a drift detector for the output block | Ship it as a behavioral golden test | Neither test image ships a `claude` CLI and the repo mounts read-only |
| Scope the omit-when-empty rule to green states | Omit every empty field unconditionally | It would have suppressed the four amber warnings whose whole purpose is gate visibility |
| Put the ≤15-line cap in `commands/_shared/communication.md` | Leave it in one step file | The number that most limits what the user reads had no test guarding it |

## Findings & dispositions

### Round 0 — draft

13 steps · 9 contract sections · installer "reuses the existing loop" · critic output exempted ·
all tests file-contract greps.

### Round 1 — 30 findings (21 MAJOR / 8 MINOR / 1 NIT), 28 confirmed. All four: REQUEST_CHANGES.

Applied 29, noted-no-change 1, rejected 0. Clusters:

- output-block retargeting — skeptic-1 + comms-2 + quality-1
- subagent coverage — arch-8 + skeptic-2 + quality-4 + skeptic-9
- installer reality — arch-1 + arch-2 + quality-3
- path form — arch-5

Headline findings:

- **skeptic-1 / comms-2 / quality-1** — v0 targeted anchors that don't control user-facing output
  (`§3a.4`, `§(g)` — the latter emits none at all). Net effect would have been **+4 blocks on an
  unchanged 16-line mandate**. → step 4 retargeted to real line ranges as a net deletion.
- **comms-1 / comms-2** — two of the user's stated complaints were **not covered at all**: "assumes I
  know what it saved to the files" and "mentions things that are working". → two new contract sections.
- **arch-4** — `/output-style` was **removed in Claude Code v2.1.91**; the installer would have printed
  a dead command. (This also corrected what I had told the user at the clarify gate.)
- **skeptic-3** — R-04's expertise-reversal caveat was dropped; the effect does **not** hold in
  ill-structured domains, and framework design is one. → R-04 bounded, c-t14 added.
- **skeptic-4** — "bats guards mitigate prose decay" was circular. → downgraded; golden file added.
- **skeptic-6/7/8, R-12/R-16/R-19** — four research rows over-read their sources or laundered the
  researcher's own synthesis into vendor attribution. → corrected or moved.
- **quality-2** — two brevity rules already existed; the contract would have been a third source of
  truth. → delete outright (no stubs).

### Round 2 — 15 findings (6 MAJOR / 7 MINOR / 2 NIT), 13 confirmed.

Verdicts: architect **APPROVE_WITH_NITS** · quality **APPROVE_WITH_NITS** · exec-communication
**APPROVE_WITH_NITS** · skeptic **REQUEST_CHANGES**. All 15 applied.

All three non-skeptic critics independently verified every round-1 finding as **genuinely resolved in
the text, not merely acknowledged in the trail** — including a re-check of the corrected research rows
against the raw source notes, which found no new over-read.

| persona | id | sev | issue | disposition |
|---------|----|-----|-------|-------------|
| skeptic | skeptic-10 | MAJOR | **`Impact` (blast radius) fell into neither layer** — the user would authorize a 17-file change from a summary that never says which files move | **applied** → step 4 user layer, c-t5 |
| skeptic | skeptic-11 | MAJOR | The omit-when-empty rule was unconditional and would have **suppressed the four amber warnings** (`research: unavailable`, `(f2)` skip, `CONVERGENCE: capped`, safe-default flags) whose whole purpose is gate visibility | **applied** → omit scoped to green states, c-t7 |
| skeptic | skeptic-12 | MAJOR | Deleting `03-review.md:47` removes the only brevity rule on **forge comments read by teammates**, under a contract scoped to a reader who isn't them | **applied** → rule kept, outward-facing clause added, c-t11 exempt, c-t19 |
| skeptic | skeptic-13 | MINOR | `Open trade-offs / escalations` unassigned by the split — the minority-flag surface | **applied** → user layer |
| skeptic | skeptic-14 | MINOR | comms-3 marked "applied" while the plan grew 149→214 lines; the tables never moved | **applied** → tables actually moved to step 11 in v2 |
| skeptic | skeptic-15 | NIT | §(e) rewrite endangers `tests/unit/v-team.bats`'s ADR-017 tokens | **applied** → steps 6 + 9 |
| architect | arch-10 | MAJOR | The golden file is **unrunnable as specced** — no `claude` CLI in either image, repo mounted read-only, `kind: e2e` excluded from `make test` | **applied** → step 16 redefined + honestly relabelled |
| architect | arch-11 | MAJOR | `install.bats`'s "unrelated symlink" test uses a target that **exists**, so a `prune_stale` that drops the prefix guard still passes | **applied** → step 8c, c-t10b |
| architect | arch-12 | MINOR | One of the 15 `## Required output` headings is suffixed; an exact-match enumeration silently drops it | **applied** → prefix match, count asserted |
| architect | arch-13 | NIT | All retargeted anchors verified correct | **noted** |
| quality | quality-7 | MAJOR | c-t11's negative grep has no exception for the contract file — it would **forbid the contract from stating its own rule** | **applied** → `--exclude` |
| quality | quality-8 | MAJOR | `tests/golden/` is a directory no Makefile target walks | **applied** → `tests/unit/` |
| quality | quality-9 | MAJOR | A committed recording with nothing that regenerates it is circular one file removed | **applied** → re-record header + honest relabel |
| quality | quality-10 | MAJOR | The `ln -sfn` re-link branch has **zero coverage**; an extraction that inverts it goes green | **applied** → characterisation test before refactor |
| quality | quality-11/12/13 | MINOR/NIT | c-t10 bundles an unwritable assertion; scope note untested; c-t16 merges two properties | **applied** |
| comms | comms-7 | MINOR | The ≤15-line cap — the number that most limits what he reads — lived in one step file with no must-test | **applied** → contract + c-t2 |
| comms | comms-8 | MINOR | The newly-capped synthesizer path still hands him `BLOCKER`/`persona`/`convergence`/`grounding` — complaint 2 leaking through | **applied** → banned-vocab list, c-t18 |
| comms | comms-9 | MINOR | (= skeptic-14) | **applied** |
| comms | comms-10 | NIT | Nothing says what to cut when the 15-line cap binds; the easiest thing to drop is the consequence he asked for | **applied** → cut order |

**Coverage of the user's stated complaints (exec-communication critic, round 2): 12 of 12 covered.**
The two that were NOT COVERED in v0 each now have a named contract section and a `must` test.

**Research tables.** The draft marked comms-3 "applied" while still carrying the full R-01..R-20
evidence tables and the eight reconciled contradictions in the plan body. Step 11 moved them to
`vault/research/decision-communication.md`; the plan now cites by id only.

### EXECUTE diff-review — round 1 (against the real code)

Same four critics, review posture, run on the staged diff (47 files, +1545/−103) with analyzers first
(`bash -n install.sh`, `make test`, live installer runs on a throwaway HOME, and **seeded mutation
testing**). Verdicts: architect **APPROVE_WITH_NITS** · quality **REQUEST_CHANGES** · skeptic
**REQUEST_CHANGES** · exec-communication **REQUEST_CHANGES**. 19 findings, 17 applied.

All four independently confirmed every prior recommendation had landed **in the code**, not just in
the plan. The highest-value findings were about *this change's own tests* — three of mine were
vacuous and would never have failed:

| id | sev | issue | disposition |
|----|-----|-------|-------------|
| quality-14 | BLOCKER | Suite was red — the contract was 121 lines against its own ≤120 cap | **applied** — compressed to exactly 120 with every rule intact |
| quality-15 | MAJOR | Three golden tests loop over a fixture section; emptying it made the loop body never run and the test pass green | **applied** — `golden_section` now fails loudly on an empty result |
| quality-16 | MAJOR | The ALLOWED-field check was an unanchored substring match, so deleting `Recommendation:`, `Impact:`, `Open:` or `Ask:` went undetected (4 of 6 fields unprotected) | **applied** — anchored to `^ *field:`; all six deletions now fail |
| skeptic-16 | MAJOR | The panel-vocabulary test asserted the banned words were **present** — inverted polarity. Deleting the entire translation rule left it green | **applied** — inverted to assert absence from the layer-1 block, plus a separate positive check that the rule still exists |
| skeptic-17 | MAJOR | The artifact-field-leak guard ran only against v-work, but `Converged plan` / `Proposed test backlog` only ever existed in v-team's block | **applied** — loop now covers both files |
| comms-1 | MAJOR | `05-commit-capture.md` §5.6 — the last thing the user reads each session — was never bound and still mandated `Tests: [all passing]` / `Review: [PASS]`, exactly what the contract bans | **applied** — bound + rewritten; green lines omitted, failures/skips/warnings always printed |
| arch-14 | MINOR | The output-styles prune sat inside `if [ -d STYLES_DIR ]`, so dropping the tree would leave symlinks dangling forever | **applied** — prune made unconditional, symmetric with the commands tree |
| arch-16 | NIT | Activation banner gated on the source file, not the link, so a REFUSED run still advertised the style | **applied** — gated on the installed symlink |
| comms-2 | MINOR | "cuts green, never amber" — a 27-word sentence opening with an undefined traffic-light metaphor, in the section banning metaphors | **applied** — "cuts good news, never warnings" everywhere |
| comms-3 | MINOR | "blast radius" prescribed as the definition of a user-facing field, in a contract banning metaphors | **applied** — "what this touches" |
| comms-4 | MINOR | Section heading said "Assume **he** has read nothing" | **applied** — "the user" |
| comms-5 | MINOR | "Progressive disclosure" is a UX term of art used as a heading in the file that bans jargon | **applied** — "Verdict first, detail on request" |
| comms-6 | NIT | The 15-line cap didn't say whether table chrome counts | **applied** — header/separator rows excluded |
| skeptic-18 | MINOR | Style said "about 15 lines", contract said "capped at 15 lines" — the duplicates had already drifted | **applied** — aligned, plus a new cross-file parity test (one probe per contract section) |
| skeptic-19 | MINOR | A capped run with several minority flags cannot satisfy both the 15-line cap and the always-surface list; no rule said which wins | **applied** — impact + warnings are never cut; the cap yields |
| skeptic-20 | MINOR | Plan said "11 sections" then listed 12, and labelled step 4 "net deletion" when the file grew 43 lines | **applied** — count fixed; label now says the deletion is in what the *user reads* (13 fields → 6) |
| skeptic-21 / quality-18 | NIT | The style dropped the verdict-first disclosure rule and buried the outward-facing clause under an unrelated heading | **applied** — both restored, parity test extended to 12 probes |
| quality-17 | MINOR | `grep -qi '15'` was subsumed by `grep -qi '15 lines'`, so the ~15-word average rule was unguarded | **applied** — pinned to the actual rule |
| quality-19 | MINOR | The fixture's `ALWAYS-EMITTED` section was never read by any test — tokens were duplicated as literals | **applied** — driven from the fixture |
| quality-20 | NIT | Binding blockquote sits above the H1 in dispatchers, below it in step files | **not applied** — cosmetic, byte-identical everywhere, no functional impact |
| quality-21 | NIT | Staged index was behind the working tree during review | **applied** — re-staged and re-run before commit |

**Mutation testing (the strongest evidence in this session).** Every previously-surviving mutant was
re-run after the fixes and is now killed: emptying the fixture's ALLOWED section · deleting `Impact:`
from the layer-1 template · changing the 15-word average to 40 · deleting the style's outward-facing
clause · re-adding a `Convergence:` field to the v-team user layer. Earlier rounds also killed:
removing a contract section, reintroducing a duplicate brevity rule, making the style delegate,
dropping the installer's prefix guard, and breaking `ln -sfn`.

**Stop condition:** no new confirmed BLOCKER/MAJOR remained after the fixes; `team_max_review_rounds`
not exhausted (1 of 2 used).

## Metrics

| round | findings | confirmed / advisory | applied | rejected | new confirmed BLOCKERs | sycophancy flag |
|---|---|---|---|---|---|---|
| plan round 1 | 30 (21 MAJOR / 8 MINOR / 1 NIT) | 28 / 2 | 29 | 0 | — | none |
| plan round 2 | 15 (6 MAJOR / 7 MINOR / 2 NIT) | 13 / 2 | 15 | 0 | 0 | none |
| diff review round 1 | 19 (1 BLOCKER / 8 MAJOR / 7 MINOR / 3 NIT) | 19 / 0 | 17 (1 not applied, cosmetic; 1 superseded) | 0 | 0 after fixes | none |

| metric | value |
|---|---|
| findings-delta, plan round 1 → 2 | 30 → 15 (−50%) |
| persona overlap, plan round 2 | 1 cluster (skeptic-14 = comms-9) |
| sycophancy check, plan round 2 | no previously-confirmed finding dropped or relabelled; three critics actively re-verified round-1 resolutions rather than assenting |
| sycophancy check, diff review | three of four critics held REQUEST_CHANGES against work they had already approved at plan stage; the majority of findings targeted the author's own tests rather than the design |
| tests after diff review | 215 → 218 unit + 50 integration, all green |
| convergence, plan rounds | round cap reached with 0 open blockers |
| totals across both plan rounds | 4 critics, 45 findings, 44 applied |

## Advisory test hints

Round-1 and round-2 PROPOSED_TESTS were reconciled into the plan's `## Proposed test backlog`, which
is the only authoritative list. Ids `c-t1`..`c-t20` carry the source persona in their `source` column.

## Rejected / deferred

- **A presentation layer on top of the existing output mandate.** The draft would have *added*
  blocks rather than replacing fields, so total text would have grown. Replaced by the two-layer
  split in step 4.
- **Deleting `v-cr/steps/03-review.md:47`.** Live until skeptic-12 showed it is the only brevity
  rule on forge comments, whose reader is a teammate, not this user.
- **`tests/golden/` as the fixture home.** No Makefile target walks that directory, so the test
  would never run on the PR-blocking path. Moved to `tests/unit/`.
- **A real dry-run behavioral test for the output block.** Neither test image ships a `claude` CLI
  and the repo mounts read-only, so it cannot run in CI. Replaced by the template-drift golden file.
- **Four research rows (R-12, R-16, R-19 and one more) as first drafted.** They over-read their
  sources or attributed the researcher's own synthesis to a vendor. Corrected or moved before v2.
- **Scope check.** The plan grew from 13 steps to 17, including an installer refactor and three
  existing test files. All growth is confirmed-finding-driven; the architect's scope check would
  drop nothing further.
- **A third plan-stage review pass.** The round cap is 2 and it was reached, so 15 round-2 findings
  (6 MAJOR) went in without re-critique. The EXECUTE diff review covered the resulting code instead.
