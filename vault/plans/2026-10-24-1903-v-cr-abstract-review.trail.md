---
type: trail
project: vault
plan: 2026-10-24-1903-v-cr-abstract-review
tags: [trail, record]
---

# 2026-10-24-1903-v-cr-abstract-review — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-10-24-1903-v-cr-abstract-review.md`, which carries the current truth only.

## Origin

The operator asked on 2026-10-24 for `/v-cr` to focus on what static analysis cannot detect: repo patterns, architecture correctness and missing tests. Each agent gets one task. The operator also asked how other frameworks give agents an understanding of file relations, including harness-like repos.

Clarify answers, 2026-10-24: the change applies to `/v-cr` only; `correctness` seats on a high-risk trigger.

Panel seating: the framework repo declares no persona pack, so `personas/_resolution.md` §1 falls back. The planning group seats instead, because the deliverable is critic prompts and a script (§2.3 harness trigger). Seated: `planning/harness-engineer`, `consumer`, `planning/codebase-fit`.

## Research

Two researchers ran in parallel on 2026-10-24. Copies: `vault/research/review-agent-splits.md` and `vault/research/review-code-context.md`.

| record | unresolved points carried into the plan |
|---|---|
| review-agent-splits | no controlled study of role split against repeated generalist passes; no benchmark labels architecture or pattern issues; no evaluation of missing-test detection |
| review-code-context | no study of a precomputed map against diff-only review; co-change threshold for a small repo unknown; no measured contradiction check |

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| five single-task seats | repeated identical generalist passes with a merge | the operator asked for one task per agent; repeated passes have better evidence but no owner per question |
| precomputed map | graph tool offered to agents | offered tools went unused in 58% of trials |
| git objects only | install ctags or tree-sitter | ADR-032; nothing installed on the machine |
| `/v-cr` only | shared with `/v-team` §5.2 | operator choice |

## Findings & dispositions

### Round 0 — 2026-10-24

Seated: `consumer`, `planning/harness-engineer`, `planning/codebase-fit`. Verdicts: REQUEST_CHANGES ×3. Full blocks: session scratchpad `critic-consumer.md`, `critic-harness-engineer.md`, `critic-codebase-fit.md`.

| id | sev | grounding | finding | disposition |
|---|---|---|---|---|
| consumer-1, harness-3, fit-10 | MAJOR | confirmed | Test dossier and backlog empty; W items cite cases nobody wrote | applied: dossier with P1–P3, H1 and control; backlog T1–T22 |
| consumer-2 | MAJOR | confirmed | fixture has no PR body, so intent-trace never seats; checkout fixture fires the billing trigger | applied: fixture renamed to report/format/slug; PR body defined in the dossier |
| consumer-3 | MAJOR | confirmed | cross-file finding target and receipt evidence undefined | applied: Decision on target = changed line, off-diff `path:line` in check, `context` row widened (W14) |
| consumer-4 | MAJOR | confirmed | map row schema undefined | applied: `## Map row contract` with six fields and per-relation meaning |
| consumer-5, harness-10 | MAJOR / MINOR | confirmed | `map-status` fields undefined; truncation invisible | applied: status fields defined; `slice` prints `map-status` and `withheld:`; `status` subcommand feeds step 5 |
| consumer-6, fit-1 | MINOR / MAJOR | confirmed | moving the test-file paragraph breaks `tests/unit/cr-coverage.bats:415-418` | applied: W23 retargets it; C2 runs cr-coverage.bats |
| consumer-7 | MINOR | advisory | rule routing names no single seat; cap interaction unstated | applied: §2.4 states the fixed cap; routed rules go to architecture-fit |
| consumer-8 | MINOR | confirmed | slice params differ; `map: []` vs missing key | applied: Interfaces and T9 define both |
| harness-1 | MAJOR | confirmed | a fake run file passes C3 | applied: C3 rebuilds fixtures, re-checks anchors at head, requires a clean control run; T22 tests the scorer |
| harness-2 | MAJOR | confirmed | C2 already passes before any work | applied: C1 and C2 require backlog-id test titles |
| harness-4 | MAJOR | confirmed | evidence rules in three places, two disagree | applied: README evidence table is the only home; T15 forbids restating |
| harness-5, fit-3, fit-11 | MAJOR / MINOR | confirmed | §2.1 testing critic, skeptic, architect and cap rules unscoped for /v-cr | applied: Decision and W13 scope them to /v-team; W18 removes the restatement |
| harness-6 | MAJOR | confirmed | no byte cap or chunk paths for the slice | applied: `--paths` and `VCR_SLICE_BYTES`; T10 |
| harness-7 | MAJOR | confirmed | map excerpts skip the secret scan | applied: `cr_redact_runtime` in build, §2.2 names map rows, T11 |
| harness-8 | MINOR | confirmed | non-forced refspec fails after a force-push | applied: `+` refspec; failure → `Map: not built` |
| harness-9 | MINOR | confirmed | `bin/gate.sh readers` refuses step-file-only identifiers | applied: the artifact is named by the script's `--map` argument; `map-status` and `map:` get their reader in `bin/change-map.sh` |
| fit-2 | MAJOR | confirmed | W12 hard-coded a second GitHub-only fetch | applied: W15/W16 extend `fetch_ref` beyond `--sandbox` |
| fit-4 | MINOR | confirmed | no group contract test | applied: W21 `tests/unit/review-personas.bats`; W29 docs row |
| fit-5 | MINOR | confirmed | `map:` undocumented in the persona template | applied: W11 |
| fit-6 | MINOR | confirmed | critic-panel.md has 3 rule lines of headroom | applied: C4 pins 173 |
| fit-7 | MINOR | confirmed | no env hardening or sanitizer | applied: W3 constraint |
| fit-8 | MINOR | confirmed | reuse row claims to extend check_dead | applied: row is `new` with the search stated |
| fit-9 | MINOR | confirmed | C3 scorer untested | applied: W24, T22 |
| fit-12 | MINOR | advisory | ADR-035 must record partial supersession of ADR-034 | applied: W27 |
| fit-13 | NIT | confirmed | fixture builder shape differs | applied: sourced `vs_mk_repo` |
| fit-14 | NIT | confirmed | indication example names retired seats | applied: W30 |

### Round 1 — 2026-10-24

Same seats. Verdicts: REQUEST_CHANGES ×3. Round-0 findings honoured except harness-1, harness-5 and fit-2 (partly). Full blocks: session scratchpad `critic-*-r1.md`. Round cap reached; the dispositions below were applied without a further round.

| id | sev | grounding | finding | disposition |
|---|---|---|---|---|
| consumer-r1-1, harness-r1-3 | MAJOR | confirmed | control run has no PR body, so intent-trace never seats and C3 fails | applied: both runs get the PR body |
| consumer-r1-2 | MAJOR | confirmed | the five evidence rows are never written | applied: W4 constraint lists one row per seat; T15 asserts them |
| consumer-r1-3, harness-r1-1 | MAJOR / MINOR | confirmed | body-only edits yield no caller row | applied: symbol = enclosing definition of any changed line; T1 is body-only |
| consumer-r1-4, harness-r1-4 | MAJOR / MINOR | confirmed | keyword lenses could evict intent-trace | applied: only correctness and security join; keyword bullet scoped to /v-team; T19 |
| consumer-r1-5 | MINOR | confirmed | seats read the working tree, not the head ref | applied: seats get repo root and head ref, read with `git show` |
| consumer-r1-6 | MINOR | confirmed | slice order and status format undefined; not-built line has no writer | applied: order and format defined; step 5 writes the not-built line |
| consumer-r1-7 | MINOR | advisory | routed rules match all five seats | applied: all routed rules go to architecture-fit |
| harness-r1-2 | MAJOR | confirmed | merged findings shape fails C3 | applied: run file = Spawned line + post-verify §(d) blocks |
| harness-r1-5, fit-r1-3 | MAJOR | confirmed | fetch target repo unnamed; conflicts with sandbox.md S2 | applied: fetch only into a local repo whose remote names the base repo; Decision states why S2 holds |
| harness-r1-6 | MINOR | confirmed | unanchored dirty control passes C3 | applied: control counts every confirmed BLOCKER/MAJOR |
| harness-r1-7 | MINOR | confirmed | co-change ratio undefined | applied: commits reachable from base, creation counts, fixture commits spelled, T4 = 4/4 |
| harness-r1-8 | MINOR | confirmed | malformed-map and missing-status exits untested | applied: T9, T12 |
| fit-r1-1 | MAJOR | confirmed | pattern question already owned by quality.md | applied: W10a boundary line; reuse row |
| fit-r1-2 | MAJOR | confirmed | acceptance criteria already owned by correctness.md | applied: W10 boundary line; task text to intent-trace only |
| fit-r1-4 | MINOR | confirmed | adapter purpose cell describes only sandbox | applied: W16 two cells |
| fit-r1-5 | MINOR | confirmed | ref leaks when step 3 stops | applied: deletion armed at fetch |
| fit-r1-6 | MINOR | confirmed | guarded strings in other bats files unrun | applied: D1 full suite against `92f56f7`; W13/W14 name the guards |
| fit-r1-7 | NIT | confirmed | ADR-033 shape has a Superseded clauses section | applied: W27 |
| fit-r1-8 | NIT | confirmed | human page missing | applied at the approval gate |

### Execute — 2026-10-24

- Tests T1–T12 were written after `bin/change-map.sh`, then proven to fail: all 12 failed against a stub that prints only `map-status`.
- `tests/unit/v-cr.bats` T17–T21 were appended with a shell heredoc, against `commands/v-work/steps/04-execute.md` §4.2.
- C3 seeded run: all four planted findings found by their owning seats (change-impact, test-gap, pattern-conformance; intent-trace also caught the missing tests). architecture-fit also flagged the stale caller, so its mandate was narrowed to contract changes the repo's records forbid.
- C3 first control run failed on a real fixture gap: `bin/report.sh` had no test and accepted a missing unit (test-gap, confirmed MAJOR). The control fixture gained a guard and `tests/report.bats`, and the five control seats ran again; the second control run has no confirmed BLOCKER or MAJOR. First-run blocks: session scratchpad `c3/out-b1/`.
- Code review round 1 (`deploy-review-panel`, the no-pack fallback) confirmed four MAJORs in `bin/change-map.sh`: lost `git grep` failures, deleted files without callers, colon and non-ASCII paths, and an unfetched base ref. It also found a Python call read as a definition, slow siblings, a build failure that stopped the review, and a T10 that could pass on an error. All were fixed and T23–T27 added. Report: session scratchpad `code-review.md`.
- Code review round 2 confirmed M1–M3, W2–W4 and S1–S6 fixed. It found two new MAJORs in the step files. The `Local match: yes` path had no base ref. A changed-path mismatch check in step 2 §2.4a dropped correct maps on renames and unreferenced files. Both were fixed, the check removed. Paths with a quote or backslash now go through `-z`. A moved file is no longer its own caller, and T28 covers both. The review cap was reached, so these last fixes have no third review. Report: session scratchpad `code-review-r2.md`.
- The container's awk is busybox, which ends a record at NUL; `git grep -z` output is turned into tabs with `tr` before awk.
- Full suite: 7 failing tests now, all failing on `92f56f7` as well; one test failing there passes now.

## Metrics

| round | confirmed BLOCKER/MAJOR new | advisory | previously-confirmed dropped |
|---|---|---|---|
| 0 | 12 | 2 | 0 |
| 1 | 9 | 1 | 0 |

## Advisory test hints

- consumer-t1: `slice` with `map: []`, missing key and malformed map → T9.
- consumer-t2: `map-status` capped counts → T7.
- consumer-t3: off-diff target rule and widened `context` evidence → T17.
- harness-t1: fabricated run with a wrong anchor fails C3 → T22.
- harness-t2: slice byte cap and `--paths` → T10.
- harness-t3: `ghp_` token in a caller line → T11.
- fit-t1: retarget the cr-coverage ownership test → W23.
- fit-t2: review-personas.bats group contract → T13–T16.
- fit-t3: tab, control byte and inherited `GIT_DIR` → T11.
- consumer-r1-t1, harness-r1-t1: body-only edit yields a caller row → T1.
- consumer-r1-t2, fit-r1-t1: evidence row per seat and boundary lines → T15.
- consumer-r1-t3, harness-r1-t2: control without intent-trace, unanchored dirty control → T22.
- harness-r1-t3: only two joiners → T19.
- fit-r1-t2: fetch target and not-built line → T18.
- fit-r1-t3: full suite → D1.
