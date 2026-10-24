---
type: plan
project: vault
slug: 2026-10-24-1903-v-cr-abstract-review
repos: [vault]
status: proposed
process_record: 2026-10-24-1903-v-cr-abstract-review.trail.md
arch_spec: 2026-10-24-1903-v-cr-abstract-review.arch.md
human_plan: https://claude.ai/artifact/LtEk15UXqFJ8QAqyWrXqZA
session_of:
session:
tags: [plan, v-cr, personas, code-review]
---

# 2026-10-24-1903-v-cr-abstract-review — plan

## Task

`/v-cr` seats five single-task reviewers, each owning one question no linter answers. A relation map of the change, built by the new `bin/change-map.sh`, feeds each reviewer.

Keywords: `v-cr`, `review seats`, `change-map`, `pattern-conformance`, `change-impact`, `test-gap`, `intent-trace`, `architecture-fit`.

## Open & deferred

- needs the operator: run `/v-cr --no-post` on one real pull request after C3 is MET. C3 runs the seats on local fixtures, and no forge path runs in this session.
- accepted: the C3 run files are saved by the implementing session. `checks/v-cr-abstract-review-C3.sh` re-verifies every cited anchor against a rebuilt fixture and requires a clean control run, but it cannot prove the spawns happened.
- accepted: the last review's fixes were applied after the review limit was reached, so no reviewer has re-read them. They touch the map contract, §2.4 joiners, the fetch target, the run-file shape and the C3 control count.
- accepted: the Test backlog was written from the design reviewers' test proposals and the dossier, without the separate test-design agents.
- accepted: no study measures whether a precomputed relation map beats diff-only review. C3 is the only measurement this plan makes.
- accepted: co-change rows ground advisory findings only. At ROSE's settings co-change was about 50% precise and caught about 4% of omissions (`vault/research/review-code-context.md` item 8).
- deferred: `/v-team` §5.2 keeps architect, `quality` and `correctness`. Seating the review group there is a separate change.
- deferred: a pairwise model check for contradictions between instruction files. No measured method exists.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| C1 | WHEN `tests/unit/change-map.bats` runs THE SYSTEM SHALL pass every Test-backlog case of `bin/change-map.sh`, each named by its backlog id | behaviour | command | `checks/v-cr-abstract-review-C1.sh` | 0 | | |
| C2 | WHEN the review-group contract tests run THE SYSTEM SHALL pass `tests/unit/review-personas.bats`, `tests/unit/v-cr.bats`, `tests/unit/cr-coverage.bats` and `tests/unit/v-cr-abstract-review-c3.bats`, with every backlog id T13–T22 present as a test title | behaviour | command | `checks/v-cr-abstract-review-C2.sh` | 0 | | |
| C3 | WHEN the five seats review the seeded repo and the clean control repo of `tests/fixtures/v-cr-seeded/mk-repo.sh` THE SYSTEM SHALL return confirmed findings whose anchors resolve at the seeded head for the stale caller in `bin/report.sh`, the untested `slug_make` and the missing `_need_args` guard, and no confirmed BLOCKER or MAJOR on the control | delivery | command | `checks/v-cr-abstract-review-C3.sh` | 0 | | |
| C4 | WHEN `bin/rule-count.sh` runs after `commands/_shared/critic-panel.md` changes THE SYSTEM SHALL report at most 173 rule lines | behaviour | command | `checks/v-cr-abstract-review-C4.sh` | 0 | | |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| D1 | `./tests/run.sh tests/unit` fails no test that passes on `92f56f7` | | |
| D2 | `./bin/doc-lint.sh --changed` reports no finding on the new and changed Markdown files | | |
| D3 | `./bin/gate.sh verdict <plan> --run` exits 0 | | |
| D4 | `make release-check` fails only on the unbumped `.claude-plugin/plugin.json` version | | |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E1 | `/v-cr` seats the review group by `personas/_resolution.md` §2.4 | OPEN | `tests/unit/v-cr.bats` T19 guards the rule text; C3 checks the `Spawned:` line |
| E2 | each seat receives only the map relations its frontmatter `map:` key lists, capped by bytes | OPEN | `bin/change-map.sh slice`; T7–T10 |
| E3 | a seat's finding is confirmed only with the evidence its row of the `personas/_shared/review/README.md` evidence table lists | OPEN | step 3 verify; C3 re-checks the anchors |
| E4 | map excerpts pass the secret scrub before any prompt | OPEN | `cr_redact_runtime` in `bin/change-map.sh`; T11 |

## Verified current state

- `personas/_resolution.md` §2 seats architect, `quality` and `correctness` for `/v-cr` and `/v-team` diff review, with the cap `team_max_parallel_critics` default 3 · read 2026-10-24.
- `personas/_resolution.md` §1 already resolves a group-qualified id `review/<id>` to `personas/_shared/review/<id>.md` · read 2026-10-24.
- `commands/v-cr/steps/01-detect.md` §1.6 resolves the PR head through the adapter `fetch_ref` op, today only under `--sandbox` · read 2026-10-24.
- `tests/unit/cr-coverage.bats:415-418` greps `owns every changed test file` in `commands/v-cr/steps/03-review.md`; `tests/unit/communication-contract.bats:161` guards the forge-comment brevity rule there · read 2026-10-24.
- `bin/rule-count.sh` prints `rule lines 170 (budget 173)`; `commands/_shared/critic-panel.md` is in its corpus · run 2026-10-24.
- `cr_redact_runtime` in `lib/cr-sandbox.sh` is a pure text scrubber; `probe_sanitize` in `lib/probe-emit.sh` turns tabs and control bytes into spaces · read 2026-10-24.
- `bin/gate.sh readers` greps non-markdown files only, so an identifier read only by step files is refused · run 2026-10-24.
- ADR-032 removed the code-graph tool; Serena is the only optional developer tool · read 2026-10-24.
- `git grep -n -w <name> <ref>` and `git log --name-only` answer every map relation without a checkout · measured 0.07 s and 0.10 s on this repo, 2026-10-24.
- ctags, ast-grep, semgrep, tree-sitter, lychee and vale are not installed on this machine · `command -v` 2026-10-24.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| the change applies to `/v-cr` only; `/v-team` §5.2 keeps its seats | the operator chose `/v-cr` only | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| five seats, one question each: change-impact, test-gap, architecture-fit, pattern-conformance, intent-trace | a split by owned question guarantees each check runs; maintainability is about 68% of verified review issues and models score lowest there | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| for `/v-cr`, §2.4 replaces the architect, `skeptic`, testing-group (§2.1) and cap rules of §2; `team_max_parallel_critics` does not apply | one selection rule per caller; the seat set is fixed at five | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| only `correctness` (on the §2 high-risk list) and `security` (on the §2 auth keywords) join a `/v-cr` run; a joining lens takes a free seat, then the bottom seat, never change-impact or test-gap; the §2 keyword-lens bullet is `/v-team` only | the operator chose trigger seating; a keyword lens would evict intent-trace | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| on `/v-cr` the task's acceptance criteria belong to intent-trace and the repo-pattern question to pattern-conformance; `correctness.md` and `quality.md` each gain a boundary line | one question per seat | local |
| every routed project rule goes to architecture-fit | all five seats hold every path, so a path names no single seat | local |
| intent-trace seats only when step 2.3 fetched a task or the PR body is non-empty; otherwise its seat is free | it has nothing to compare without requirements | local |
| the map is precomputed and handed to each seat, never offered as a tool | 58% of trials never called an offered graph tool | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| the map reads git objects only and installs nothing; the PR head comes from the adapter `fetch_ref` op | ADR-032 bars a prescribed code graph; one fetch path keeps the trust gate | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| without `--sandbox`, step 1 fetches `refs/vcr/<n>` only into a local repo with a remote whose URL names the base `<owner>/<repo>`; otherwise `Map: not built, no local clone of <owner>/<repo>` | a fetch into `refs/vcr/` writes objects and one ref, and never touches the working tree, the index or a branch, so `commands/v-cr/sandbox.md` S2's ban on running code in the working repo still holds | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| step 1 arms the `refs/vcr/<n>` deletion when it creates the ref; step 5 runs it on the normal path | a review that stops in step 3 must not leave the ref | local |
| each seat gets the repo root and the head ref, and reads an off-diff file with `git show <head>:<path>` when no head checkout exists | map line numbers are at the head ref, which may exist only as `refs/vcr/<n>` | local |
| map rows carry `path:line` and a one-line excerpt, never a file body | 100-line windows scored 18.0% against 12.7% for full files | local |
| each persona owns its slice through a frontmatter `map:` key | the slice rule sits beside the lens that uses it | local |
| the evidence table in `personas/_shared/review/README.md` is the only home of the seats' confirm rules; `critic-panel.md` (e) defers to it for a `/v-cr` caller | one rule, one place | local |
| a cross-file finding targets the changed line and cites the off-diff `path:line` in `check`; a map target read in full is a `context` receipt row | GitHub refuses inline comments outside the diff; `cr_coverage` counts `read` rows on unchanged files as `extra` | local |
| co-change rows ground advisory findings only | low recall and about 50% precision | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` |
| a resolved pack's architect block becomes the architecture-fit overlay; with no pack, the five seats run without overlays | the seats need repo evidence, not a stack pack | local |
| test-gap replaces the testing group for `/v-cr` and gives a test file to the testing group only under `--sandbox`, as evidence | the testing lenses need mutation and coverage runs that a static review lacks | local |

## Scope & non-goals

Covers `/v-cr` step 1 (head ref), step 2 (map build and scrub), step 3 (seats, slices, evidence) and step 5 (map counts).

Non-goals: `/v-team` and `/v-work` review seats; posting format in `commands/v-cr/steps/04-post.md`; GitLab; a vector index or graph database; a contradiction checker for instruction files.

## Map row contract

`bin/change-map.sh` header owns this contract once shipped; `personas/_shared/review/README.md` links to it.

A row has six tab-separated fields: `relation`, `changed`, `symbol`, `target`, `line`, `excerpt`. `changed` is a path in the diff. `symbol` is `-` unless the relation names one. `line` is a 1-based line number at the head ref, or `-`. `excerpt` is that line, trimmed, sanitized by `probe_sanitize`, scrubbed by `cr_redact_runtime`, and cut at 160 bytes.

| relation | a row means | symbol | target and line |
|---|---|---|---|
| `referenced-by` | a file at head mentions the changed path, or a Markdown file's stem as `[[stem` | `-` | the mentioning file and line |
| `references` | the changed file at head mentions a path that exists at head | `-` | the mentioned path; line is the line in the changed file |
| `caller` | a line at head uses a changed definition as a whole word, outside its own definition line | the enclosing definition of any added or removed line: the nearest definition at or above it, in head for an added line and in base for a removed one | the using file and line |
| `test` | a test file at head mentions the changed file's base name (file name with extension) or a changed symbol | the symbol, or `-` for a path match | the test file and line; when nothing matches, target `none`, line `-`, excerpt `-` |
| `co-change` | a file outside the diff changed with the changed file in at least 3 commits reachable from base, with confidence at least 0.5; the commit that created the file counts | `-` | the partner; line `-`; excerpt `<together>/<commits of changed>` |
| `sibling` | a file at head, outside the diff, in the same directory with the same extension, at most 5, most recently committed first | `-` | the sibling; line of its first definition or heading |

A test file sits under `tests/`, `test/`, `spec/` or `__tests__/`, or has `test` or `spec` in its base name. Definitions are read from `name()` and `function name` (sh), `function name` (php, js, ts), `def name` (py) and `func name` (go).

`build` prints rows grouped by changed path, then by relation in the table's order. Its last line is `map-status`, tab-separated: `map-status`, `complete` | `capped` | `partial`, a reason or `-`, then one `<relation>=<rows>/<withheld>` field per relation. `partial` means a git query failed after the refs resolved; the reason names it.

`slice` prints the `map-status` line first, then its rows, then `withheld: <n> rows` when the byte cap cut any. `status` prints `map_status: <state> <reason>` and one `map_<relation>: <rows>/<withheld>` line per relation.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| head ref `refs/vcr/<n>` | `bin/change-map.sh build --head` | `commands/v-cr/steps/01-detect.md` §1.6 via the adapter `fetch_ref` op with refspec `+<ref>:refs/vcr/<n>`, into the local repo whose remote names the base repo | `bin/change-map.sh build` | no such repo, `unsupported` or a failed fetch → step 2 prints `Map: not built, <reason>`; the deletion `git update-ref -d refs/vcr/<n>` is armed at fetch and run in step 5 |
| map file (`bin/change-map.sh build` stdout, passed back as `slice --map`) | `bin/change-map.sh slice --map` in `commands/v-cr/steps/03-review.md` §3.1 | `bin/change-map.sh build` from `commands/v-cr/steps/02-gather.md` §2.4a | `bin/change-map.sh slice`; `bin/change-map.sh status` | absent → seats run diff-only and step 3 prints `Map: not built, <reason>`; malformed → `slice` exits 2 and step 3 stops |
| seat slice (rows plus `map-status`, then `withheld: <n> rows` when cut) | the seat's mandate in `personas/_shared/review/<seat>.md` | `bin/change-map.sh slice --map --persona [--paths]` | the spawned seat | no rows → the slice still prints `map-status`, so an empty slice is visible |
| frontmatter `map:` key | `bin/change-map.sh slice --persona` | each file in `personas/_shared/review/` and `personas/_shared/correctness.md` | `bin/change-map.sh slice`; `tests/unit/review-personas.bats` | key absent → `slice` exits 2 naming the persona; `map: []` → only `map-status` |
| seat rule `personas/_resolution.md` §2.4 | `commands/_shared/critic-panel.md` (b) for a `/v-cr` caller | this plan | `commands/v-cr/steps/03-review.md` §3.1 | an unknown seat id → `personas/_resolution.md` §3 spawns `Explore` with the block |
| evidence table in `personas/_shared/review/README.md` | `commands/_shared/critic-panel.md` (e) for a `/v-cr` caller | this plan | each seat; the step 3 verify | a finding without the listed evidence is set to `advisory` |
| coverage-block map lines | `commands/v-cr/steps/05-capture.md` §5.1 | `bin/change-map.sh status`; with no map, step 5 writes `map_status: not built <reason>` from step 2's `Map:` line | the session record reader | `status` on a file with no `map-status` line exits 2 and step 5 records `map_status: unreadable` |
| `vault/plans/2026-10-24-1903-v-cr-abstract-review.c3-run.md` and `.c3-control-run.md`: the `Spawned:` line, then each seat's `commands/_shared/critic-panel.md` §(d) block with `grounding` as set by the (e) verify | `checks/v-cr-abstract-review-C3.sh` | the EXECUTE session from W26 | the C3 check | absent → exit 2; a merged `Confirmed actionable:` list without PERSONA blocks scores nothing and exits 1 |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W1 | `tests/fixtures/v-cr-seeded/mk-repo.sh` | sourced functions `vs_mk_repo <dir>` and `vs_mk_clean_repo <dir>`, each setting `VS_BASE`; layout in the Test design dossier | Write | shape of `tests/fixtures/sandbox-probe/mk-repo.sh`; fixed author and dates; no network | C1 C3 | T1–T6 build on it | TODO |
| W2 | `tests/unit/change-map.bats` | write T1–T12, test titles starting with their ids, and prove them red | Write | runs in the bats container | C1 | fails before W3 | TODO |
| W3 | `bin/change-map.sh` | subcommands `build`, `slice`, `status` per the Map row contract | Write | ≤280 lines; header holds the row contract; unsets `GIT_*` and keeps absolute `PATH` entries as `bin/probe-panel.sh:24-31`; sources `lib/probe-emit.sh` and `lib/cr-sandbox.sh`; reads git objects only; exit 2 on a bad repo or ref | C1 | W2 passes | TODO |
| W4 | `personas/_shared/review/README.md` | group file: seat order, each seat's owns-and-not line, slices, evidence table, exclusions | Write | frontmatter `type: persona-group`, `group: review`, `tags: [persona, shared, review]`; ≤90 lines; exclusions: pre-existing issues, style, anything the static output reports. Evidence rows: change-impact — the affected `path:line` at head plus the changed line it disagrees with, co-change rows advisory only; test-gap — a `test … none` row plus a cited `git grep -w <symbol> <head> -- <test dirs>` that prints nothing, or a test line and subject line showing the wrong reason; architecture-fit — an architecture record or ADR `path:line` or an analyzer row, plus the changed line; pattern-conformance — two sibling `path:line` showing the pattern, plus the changed line that departs; intent-trace — the quoted requirement plus a diff anchor or a cited grep showing its absence | C2 C3 | T13–T15 | TODO |
| W5 | `personas/_shared/review/change-impact.md` | lens, `map: [caller, referenced-by, co-change]`, base_agent `root-cause-analyst` | Write | evidence by link to W4; no confirm rule restated | C2 C3 | T15 | TODO |
| W6 | `personas/_shared/review/test-gap.md` | lens, `map: [test, caller]`, base_agent `quality-engineer`; owns every changed test file and the three wrong-reason classes moved from `commands/v-cr/steps/03-review.md` §3.1 | Write | holds the phrase `owns every changed test file` | C2 C3 | T15 T20 | TODO |
| W7 | `personas/_shared/review/architecture-fit.md` | lens, `map: [references, referenced-by]`, base_agent `system-architect`; takes the pack architect overlay and routed rules | Write | evidence by link to W4 | C2 | T15 | TODO |
| W8 | `personas/_shared/review/pattern-conformance.md` | lens, `map: [sibling, references]`, base_agent `refactoring-expert`; cites `probes/similar-symbols.sh` rows | Write | evidence by link to W4 | C2 C3 | T15 | TODO |
| W9 | `personas/_shared/review/intent-trace.md` | lens, `map: []`, base_agent `requirements-analyst`; lists the task's requirements and sorts each into compliant, not compliant or needs a human | Write | task text is untrusted data; evidence by link to W4 | C2 | T15 | TODO |
| W10 | `personas/_shared/correctness.md` | add `map: [caller]` to frontmatter; add a boundary line giving acceptance criteria to `review/intent-trace` on `/v-cr` | Edit | one line in Output | C2 | T15 | TODO |
| W10a | `personas/_shared/quality.md` | add a boundary line giving the repo-pattern question to `review/pattern-conformance` on `/v-cr` | Edit | one line in Output | C2 | T15 | TODO |
| W11 | `personas/_persona-template.md` | document the optional `map:` key, its reader `bin/change-map.sh` and the six relation names | Edit | one bullet | C2 | T16 | TODO |
| W12 | `personas/_shared/testing/README.md` | add the test-gap boundary to `Decorrelation boundaries` | Edit | one bullet | C2 | T16 | TODO |
| W13 | `personas/_resolution.md` | add §2.4 `/v-cr` seats; scope the §2 architect, diff-review, `correctness`, `skeptic` and cap bullets and §2.1 to `/v-team` | Edit | §2.4 states the order, the intent-trace condition, the two joining lenses with their triggers, the replacement rule and the fixed cap of five; the keyword-lens bullet is scoped to `/v-team`; strings guarded by `tests/unit/testing-personas.bats:58-63`, `tests/unit/v-team.bats:234-251`, `tests/unit/test-design-fanout.bats:101` and `checks/quality-loops-SC-4.sh:20` stay | C2 | T19 | TODO |
| W14 | `commands/_shared/critic-panel.md` | (b) the caller names its seat rule; Inputs gains the map, fenced as untrusted; the `context` receipt row covers a map target; (e) defers to the review-group evidence table for a `/v-cr` caller | Edit | rule lines stay ≤173; `/v-team` behaviour unchanged; strings guarded by `tests/unit/probe-panel.bats:66` and `tests/unit/v-team.bats:292` stay | C2 C4 | T17 C4 | TODO |
| W15 | `commands/v-cr/steps/01-detect.md` | §1.6 resolves `fetch_ref` for every run with a forge PR; outside `--sandbox` it fetches with `+<ref>:refs/vcr/<n>` into the local repo whose remote names the base repo, and arms the ref deletion | Edit | `--sandbox` path unchanged; no such repo → `Map: not built, no local clone of <owner>/<repo>` | C2 | T18 | TODO |
| W16 | `commands/v-cr/adapters.md` | `fetch_ref` row: called by step 1 for the map and for `--sandbox`; the purpose cell names the `Map: not built, <reason>` fallback | Edit | two cells | C2 | T18 | TODO |
| W17 | `commands/v-cr/steps/02-gather.md` | add §2.4a map build; §2.2 names map excerpts as scanned input; rewrite the no-pack paragraph; output gains `Map:` | Edit | local match, sandbox clone or `refs/vcr/<n>` → build; otherwise `Map: not built, <reason>` | C2 | T18 | TODO |
| W18 | `commands/v-cr/steps/03-review.md` | §3.1 seats per §2.4 and calls `bin/change-map.sh slice --map --persona` per seat, adding `--paths` per chunk; the selection restatement at lines 25-26 becomes a pointer; the testing-critic paragraph moves to W6; every routed rule goes to architecture-fit; the task text goes to intent-trace only; each seat gets the repo root and head ref; §3.3 bars map excerpts in fork comments; output gains `Map:` | Edit | strings guarded by `tests/unit/v-cr.bats` and `tests/unit/communication-contract.bats:161` stay | C2 | T20 T21 | TODO |
| W19 | `commands/v-cr/steps/05-capture.md` | coverage block gains the `bin/change-map.sh status` lines, or `map_status: not built <reason>` from step 2; run the armed `refs/vcr/<n>` deletion | Edit | counts come from `status` only | C2 | T21 | TODO |
| W20 | `commands/v-cr.md` | one line in Notes naming the review group and `bin/change-map.sh` | Edit | no new section | C2 | T21 | TODO |
| W21 | `tests/unit/review-personas.bats` | group contract T13–T16, modelled on `tests/unit/planning-personas.bats` | Write | titles start with their ids | C2 | `./tests/run.sh tests/unit/review-personas.bats` | TODO |
| W22 | `tests/unit/v-cr.bats` | add T17–T21 | Edit | existing tests untouched | C2 | `./tests/run.sh tests/unit/v-cr.bats` | TODO |
| W23 | `tests/unit/cr-coverage.bats` | retarget lines 415-418 to `personas/_shared/review/test-gap.md`; keep the `unexamined test files` grep on 03-review | Edit | test title unchanged | C2 | `./tests/run.sh tests/unit/cr-coverage.bats` | TODO |
| W24 | `tests/unit/v-cr-abstract-review-c3.bats` and `tests/fixtures/v-cr-abstract-review-c3/` | T22: pass, wrong-anchor, missing-seat and dirty-control fixtures for the C3 scorer | Write | modelled on `tests/unit/agent-systems-c3.bats` | C2 | the bats file passes | TODO |
| W25 | `checks/v-cr-abstract-review-C4.sh` | pin `bin/rule-count.sh` rule lines at 173 | Write | shape of `checks/indication-routing-SC-4.sh` | C4 | exits 0 today | DONE |
| W26 | `vault/plans/2026-10-24-1903-v-cr-abstract-review.c3-run.md` and `.c3-control-run.md` | build both fixtures, run step 3 §3.1 with real `Agent` spawns on each, and save the `Spawned:` line plus each seat's §(d) block with `grounding` as set by the (e) verify | Agent | maps from `bin/change-map.sh`; both runs get their dossier PR body | C3 | `checks/v-cr-abstract-review-C3.sh` | TODO |
| W27 | `vault/decisions/ADR-035-v-cr-single-task-review-seats.md` | write the decision record with `supersedes_in_part: [ADR-034]` and a `## Superseded clauses` section naming ADR-034 decision 5 on `/v-cr` | Write | cites both research records | C2 | `tests/unit/v-team.bats` inventory test | TODO |
| W28 | `vault/decisions/_inventory.md` | add the ADR-035 row | Edit | same commit as W27 | C2 | `tests/unit/v-team.bats` inventory test | TODO |
| W29 | `docs/reviewer-packs.md` | add the `_shared/review/` group row | Edit | one row | C2 | `bin/doc-lint.sh docs/reviewer-packs.md` | TODO |
| W30 | `vault/indications/cr-panel-spawn-and-visibility.md` | update the `Spawned:` example at line 37 to the five seats | Edit | one line | C2 | `bin/doc-lint.sh` on the file | TODO |
| W31 | `vault/features/v-cr.md` | add the seats, the map contract and their behaviours | Edit | at capture | C3 | `bin/doc-lint.sh vault/features/v-cr.md` | TODO |

## Rollback

`git revert` the implementation commits. Nothing is irreversible: no schema, no external service, and no `VAULT.md` key changes. A leftover head ref is removed with `git update-ref -d refs/vcr/<n>`.

## Test plan

- `tests/unit/change-map.bats`: T1–T12 on repos from `tests/fixtures/v-cr-seeded/mk-repo.sh` and small inline repos, in the bats container via `./tests/run.sh`.
- `tests/unit/review-personas.bats`, `tests/unit/v-cr.bats`, `tests/unit/cr-coverage.bats`: text and shape guards T13–T21.
- `tests/unit/v-cr-abstract-review-c3.bats`: T22 on the C3 scorer.
- C3: two recorded reviews, scored by `checks/v-cr-abstract-review-C3.sh` against rebuilt fixtures.

## Test design dossier

**Seeded repo** (`vs_mk_repo`). Base commit and three earlier commits:

| path | content |
|---|---|
| `lib/args.sh` | `_need_args <want> <got>` prints `need <want> args` to stderr and returns 2 when got < want |
| `lib/format.sh` | `format_row()` opens with `_need_args 2 $# \|\| return 2` and prints two columns; the head change edits only body lines |
| `lib/pad.sh` | `pad_left()` opens with `_need_args 2 $# \|\| return 2` |
| `bin/report.sh` | sources `lib/format.sh`; line 6 is `format_row "$name" "$count"` |
| `tests/format.bats`, `tests/pad.bats` | tests of `format_row` and `pad_left` |

Commit 1 creates every base file. Commits 2, 3 and 4 each change `lib/format.sh` and `tests/format.bats` together, so co-change reads `4/4`.

The head commit plants three defects and one hint:

| id | defect | seat that owns it | evidence C3 re-checks |
|---|---|---|---|
| P1 | `format_row` now requires 3 arguments; `bin/report.sh:6` still passes 2 | change-impact | the cited `bin/report.sh:<n>` line contains `format_row` at head |
| P2 | new `lib/slug.sh` defines `slug_make` with no test | test-gap | the finding names `slug_make`; `git grep -w slug_make <head> -- tests` is empty |
| P3 | `slug_make` has no `_need_args` guard, unlike `lib/format.sh` and `lib/pad.sh` | pattern-conformance | the finding names `_need_args` and cites a `lib/slug.sh:<n>` that exists at head |
| H1 | `tests/format.bats` did not change with `lib/format.sh` | change-impact, advisory | not scored |

PR body for both runs: `Add a unit column to report rows. Add slug_make for report file names, with tests.`

**Clean control** (`vs_mk_clean_repo`): the same base; the head also updates `bin/report.sh:6` and `tests/format.bats`, guards `slug_make` with `_need_args`, and adds `tests/slug.bats`.

**Fault hypotheses for the map:**
- A caller in a file the diff does not touch is the case diff-only review misses.
- A definition removed rather than added still has callers.
- A commit over the file cap must not create co-change.
- An excerpt can carry a tab, a control byte or a token.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T1 | dossier P1 | unit | `tests/unit/change-map.bats` | `build` on the seeded repo, whose change to `format_row` is body-only, emits `caller lib/format.sh format_row bin/report.sh 6` | must | |
| T2 | dossier P2 | unit | `tests/unit/change-map.bats` | `build` emits `test lib/slug.sh slug_make none - -` and a `test` row for `lib/format.sh` pointing at `tests/format.bats` | must | |
| T3 | dossier P3 | unit | `tests/unit/change-map.bats` | `build` emits `sibling` rows for `lib/slug.sh` naming `lib/format.sh` and `lib/pad.sh`, at most 5 | must | |
| T4 | dossier H1 | unit | `tests/unit/change-map.bats` | `build` emits `co-change lib/format.sh - tests/format.bats - 4/4`; the control emits none | must | |
| T5 | relation | unit | `tests/unit/change-map.bats` | a Markdown file linked as `[[stem` and by path yields two `referenced-by` rows, and its own backtick path yields a `references` row | must | |
| T6 | fault | unit | `tests/unit/change-map.bats` | a definition removed in head still yields `caller` rows for its remaining uses | should | |
| T7 | cap | unit | `tests/unit/change-map.bats` | with `VCR_MAP_CAP=2`, a relation with 5 rows keeps 2 and `map-status` reads `capped` with `<relation>=2/3` | must | |
| T8 | cap | unit | `tests/unit/change-map.bats` | a commit touching more than `VCR_MAP_MAX_COMMIT_FILES` files adds no co-change support | must | |
| T9 | slice | unit | `tests/unit/change-map.bats` | `slice` keeps only the persona's relations; `map: []` prints only `map-status`; a missing key exits 2 naming the persona; a malformed map exits 2 | must | |
| T10 | slice | unit | `tests/unit/change-map.bats` | `slice --paths` keeps rows for those paths; `VCR_SLICE_BYTES` cuts rows and prints `withheld: <n> rows` | must | |
| T11 | security | unit | `tests/unit/change-map.bats` | a caller line with a `ghp_` token, a tab and a control byte yields a six-field row with `[REDACTED]`; an inherited `GIT_DIR` does not redirect the map | must | |
| T12 | exit | unit | `tests/unit/change-map.bats` | a bad ref exits 2; a non-git `--repo` exits 2; `status` prints the coverage-block lines from `map-status`; `status` on a file with no `map-status` line exits 2 | must | |
| T13 | group | unit | `tests/unit/review-personas.bats` | README has `group: review`; five lens files exist with `type: persona`, `base_agent` and `tags: [persona, shared, review]` | must | |
| T14 | group | unit | `tests/unit/review-personas.bats` | each lens has the template sections in order: Mandate, Bound analyzer, Severity rubric, Checklist, Output | should | |
| T15 | group | unit | `tests/unit/review-personas.bats` | each lens and `correctness.md` has a `map:` key whose names are in the six-relation set; no lens restates a `confirmed only` rule; README has an evidence row per seat id; `correctness.md` names `review/intent-trace` and `quality.md` names `review/pattern-conformance` | must | |
| T16 | group | unit | `tests/unit/review-personas.bats` | `_persona-template.md` documents `map:`; the testing README names test-gap in its boundaries | should | |
| T17 | wiring | unit | `tests/unit/v-cr.bats` | `critic-panel.md` defers to the review-group evidence table for `/v-cr` and lists the map as untrusted input | must | |
| T18 | wiring | unit | `tests/unit/v-cr.bats` | `01-detect.md` resolves `fetch_ref` outside `--sandbox` with `+` refspec, names the receiving repo and prints `Map: not built, no local clone`; `02-gather.md` has §2.4a and scans map excerpts | must | |
| T19 | wiring | unit | `tests/unit/v-cr.bats` | `_resolution.md` §2.4 names the five seats in order, the intent-trace condition, `correctness` and `security` as the only joining lenses and the cap of five; the keyword-lens bullet names `/v-team` | must | |
| T20 | wiring | unit | `tests/unit/v-cr.bats` | `03-review.md` passes `--map` and `--persona` to `bin/change-map.sh slice` and no longer restates selection | must | |
| T21 | wiring | unit | `tests/unit/v-cr.bats` | `05-capture.md` calls `bin/change-map.sh status`; `v-cr.md` names the review group | should | |
| T22 | C3 | unit | `tests/unit/v-cr-abstract-review-c3.bats` | the C3 scorer passes a pass fixture in the W26 run-file shape, and fails wrong-anchor, missing-seat, dirty-control and unanchored-dirty-control fixtures | must | |

## Refs

- `vault/research/review-agent-splits.md` — how review tools split agents, what review comments are about, and what precision rests on.
- `vault/research/review-code-context.md` — what a relation map should hold and how to compute it with git and grep.
- `vault/decisions/ADR-008-v-cr-remote-pr-review.md` — `/v-cr` stays single-pass, read-only and precision-first.
- `vault/decisions/ADR-032-remove-memory-and-edit-mcps.md` — no code-graph tool is prescribed.
- `vault/decisions/ADR-034-three-execute-loops.md` — decision 5 sets today's diff-review seats; ADR-035 replaces it for `/v-cr`.
- `vault/plans/2026-10-24-1903-v-cr-abstract-review.trail.md` — the process record.
