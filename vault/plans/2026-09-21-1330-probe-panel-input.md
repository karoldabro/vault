---
type: plan
project: vault
slug: probe-panel-input
repos: [vault]
status: executed
process_record: 2026-09-21-1330-probe-panel-input.trail.md
arch_spec: 2026-09-21-1330-probe-panel-input.arch.md
human_plan: https://claude.ai/artifact/NLH3yrrdzuofH9qRbqHWs5
session:
tags: [plan, probes, review-panel]
---

# probe-panel-input — plan

## Task
Session S7 of `vault/plans/2026-09-21-0900-architecture-first-planning.md`. Feed `bin/probe.sh diff` rows to every critic of the `/v-team` execute loop, `/v-cr` and `/v-work` review, through one helper `bin/probe-panel.sh` whose rules live in `commands/_shared/critic-panel.md`. Add the optional `probe: <registry id>` key to `templates/indication.md` and make `bin/indication-route-audit.sh` check it (contract C-5). Keywords: probe rows, critic panel, posture, grounding, row cap, `absent:`, `probe:` key.

## Open & deferred
- accepted limit: a kit exit above 2 with no status line reads `complete`; the kit prints a status line for every failure it knows.
- deferred: running `executes-repo-code: yes` probes inside the `/v-cr --sandbox` container. S7 keeps `--no-repo-code` in both `/v-cr` modes because the probe kit runs on the host; `commands/v-cr/sandbox.md` owns a later in-container stage.
- deferred: consuming the `probe:` key. S8 reads it when it writes a rule; S7 only defines the key and checks that the id exists.
- accepted limit: every review on this machine reports an incomplete probe run. Under `own`, `bin/probe.sh diff` exits 2 because `lizard` and `typos` are not installed. Under `pr`, the kit skips `claude-validate`, `lizard` and `typos` because they execute repo code.
- existing defect, not this plan's: `checks/indication-routing-SC-4.sh` fails on `HEAD` (181 rule lines against a pin of 175). This session left the count at 181.
- accepted limit: the row cap of D-4 is an unmeasured default. S5 measures the cost delta (D-10 of the master plan).
- existing defect, not this plan's: 5 unit tests fail on `HEAD` (`document-standard.bats` unknown-type and `--compare`, `plugin-install.bats` two path notes, `research-clarify.bats` the PROPOSE output contract).

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does an `own` review run the repo's own registry? | no | master plan contract C-6, `commands/_shared/probe-kit.md` Registry | defaulted | no by default, yes with `PROBE_PANEL_REPO_CODE=yes`; recorded in D-1 |

## Success criteria
<!-- Checks are written before the work and exit 2 with "not written yet" until the file they grade exists. -->

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN `bin/probe-panel.sh run --posture pr` runs THE SYSTEM SHALL pass `--no-repo-code` and never a repo registry, WHEN `--posture own` runs it SHALL pass `--no-repo-code` and no repo registry unless `PROBE_PANEL_REPO_CODE=yes`, and WHEN `--base` is missing it SHALL exit 2 instead of defaulting to `HEAD` | functional | command | `checks/probe-panel-SC-1.sh` | exit 0 | MET | `checks/probe-panel-SC-1.sh` exited 0 |
| SC-2 | WHEN a probe is absent, failed or skipped, or the kit exits 2 THE SYSTEM SHALL exit 2, print `probe-status: INCOMPLETE` (or `probe-status: ERROR` with the kit's message inside the fence when the kit ran no probe), still print the rows found, and write `operator.txt` with the one operator line, and WHEN every probe ran THE SYSTEM SHALL exit 0, print `probe-status: complete` and write no operator line | functional | command | `checks/probe-panel-SC-2.sh` | exit 0 | MET | `checks/probe-panel-SC-2.sh` exited 0 |
| SC-3 | WHEN rows come from the framework registry THE SYSTEM SHALL list them under `[confirmed]`, WHEN from a repo registry, from an id that a repo registry also defines, from a framework row marked `executes-repo-code: yes`, or from any run whose diff edits `probes/registry.tsv` or `probes/rules/`, under `[advisory]`, and `cited` SHALL print `confirmed` or `advisory` and exit 0 for a listed row, print `none` and exit 1 otherwise, and exit 2 for an id that is not `[a-z0-9-]+` or a line that is not digits | functional | command | `checks/probe-panel-SC-3.sh` | exit 0 | MET | `checks/probe-panel-SC-3.sh` exited 0 |
| SC-4 | WHEN a run yields more rows than `PROBE_PANEL_ROWS` or more bytes than `PROBE_PANEL_BYTES` THE SYSTEM SHALL print no more than that and state the withheld count, and a row holding `>>>`, a run of `>` characters or the fence token SHALL not close the data fence, and a file name over 200 bytes SHALL be cut | functional | command | `checks/probe-panel-SC-4.sh` | exit 0 | MET | `checks/probe-panel-SC-4.sh` exited 0 |
| SC-5 | WHEN an indication names `probe: <id>` THE SYSTEM SHALL accept an id in a registry read, WHEN every registry that could hold it was read and none does THE SYSTEM SHALL exit 1 from `bin/indication-route-audit.sh` naming slug and id, WHEN the repo registry could not be located it SHALL print `unchecked-probe` and not fail, and `templates/indication.md` SHALL carry the key | functional | command | `checks/probe-panel-SC-5.sh` | exit 0 | MET | `checks/probe-panel-SC-5.sh` exited 0 |
| SC-6 | WHEN an operator opens `commands/_shared/critic-panel.md`, `commands/v-team/steps/04-execute-loop.md`, `commands/v-cr/steps/03-review.md` and `commands/v-work/steps/04-execute.md` THE SYSTEM SHALL show each running `bin/probe-panel.sh` with its posture, the panel module SHALL own the rules, and `commands/v-cr/steps/03-review.md` SHALL never name `--allow-repo-registry` and SHALL call the helper only when it holds a checkout of the pull request | delivery | command | `checks/probe-panel-SC-6.sh` | exit 0 | MET | `checks/probe-panel-SC-6.sh` exited 0 |
| SC-7 | WHEN the unit suite runs THE SYSTEM SHALL pass `tests/unit/probe-panel.bats`, `tests/unit/v-team.bats` and `tests/unit/v-cr.bats`, and the full suite SHALL fail only the 5 tests that fail on `HEAD` | delivery | command | `checks/probe-panel-SC-7.sh` | exit 0 | MET | `checks/probe-panel-SC-7.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | change does what the task asked | met | the helper, the panel text, three review steps, the `probe:` key and its audit are built; scope cut: none; `bin/gate.sh verdict <plan> --run` reports SC-1 to SC-7 MET |
| B2 | tests covering the change pass | met | `checks/probe-panel-SC-7.sh` exited 0: the full unit suite fails only the 5 tests that fail on `HEAD`; `probe-panel.bats` 8 of 8 |
| B3 | lint passes on changed files | met | `./bin/doc-lint.sh --changed` exits 0 |
| B4 | every review finding fixed or recorded | met | all confirmed major findings fixed; the rest are in Open & deferred or fixed with a grader case |
| B5 | invalidated docs updated | met | master plan S7 row, `commands/_shared/probe-kit.md` Trust section |
| B6 | nothing unrelated in the commit | met | `git status --short` lists only this plan's files; `output-styles/director.md` and `scripts/completion-hook.sh` stay unstaged |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | A review runs no repo code and reads no repo registry unless the operator sets `PROBE_PANEL_REPO_CODE=yes`; `/v-cr` never does | ENFORCED | `bin/probe-panel.sh` derives the flags from the posture and the variable; `checks/probe-panel-SC-1.sh`; the kit's own `--no-repo-code` tests in `tests/unit/probe.bats` |
| E-2 | An incomplete probe run never reads as a clean one | HALF-BUILT | the helper prints `INCOMPLETE` and exits 2; a session shows it only because `commands/_shared/critic-panel.md` says so, and `tests/unit/v-team.bats` guards that text |
| E-3 | A critic's `confirmed` finding cites a probe row that exists | ENFORCED | `bin/probe-panel.sh cited`; `checks/probe-panel-SC-3.sh` |

## Verified current state
- `bin/probe.sh run plan` on this repo prints 54 finding rows and 10,494 bytes; the median row is 208 bytes, about 52 tokens at 4 bytes per token · `bin/probe.sh run plan | wc -lc` · 2026-09-21
- `bin/probe.sh diff` on this repo exits 2 and prints `absent: lizard: python3 -m venv .venv-probes && .venv-probes/bin/pip install lizard` on stderr; rows of probes that ran still print on stdout, and a failed probe drops its rows · `bin/probe.sh diff` · 2026-09-21
- under `--no-repo-code` the kit prints `skipped: claude-validate`, `skipped: lizard` and `skipped: typos` and exits 0 or 1, not 2 · `bin/probe.sh diff --no-repo-code` · 2026-09-21
- `bin/probe.sh diff` with the default `--base HEAD` reports no file that a commit already contains · a scratch repo with one committed broken link · 2026-09-21
- `bin/probe.sh list` ignores `--no-repo-code`, needs `--allow-repo-registry` to show repo rows, and a repo row may reuse a framework id at another stage · `bin/probe.sh list` on a scratch repo · 2026-09-21
- `bin/probe.sh list` prints an `origin` column, `framework` or `repo`, per row; a finding row carries no origin · `commands/_shared/probe-kit.md` Lines · 2026-09-21
- a finding row is `probe file line severity rule message`, the core cuts a message at 240 bytes and strips control bytes · `commands/_shared/probe-kit.md` · 2026-09-21
- `commands/_shared/critic-panel.md` §(a) runs "the resolved pack's bound analyzers"; §(e) drops a finding that is not `grounding: confirmed` · `grep -n '(a) Ground first\|(e) Verify' commands/_shared/critic-panel.md` · 2026-09-21
- `/v-team` `04-execute-loop.md` 5.3 step 1 runs analyzers on the diff each round; `/v-cr` `03-review.md` 3.1 passes analyzer output to the panel; `/v-work` `04-execute.md` 4.7 spawns `deploy-review-panel` for BIG scope and 4.8 self-reviews · `grep -n 'Analyzers first\|analyzer output\|deploy-review-panel' commands/v-team/steps/04-execute-loop.md commands/v-cr/steps/03-review.md commands/v-work/steps/04-execute.md` · 2026-09-21
- `/v-cr` chunks a diff above about 1500 changed lines or 40 files and caps a review at `VCR_MAX_TOKENS`, default about 200k · `commands/v-cr/steps/03-review.md` 3.2 · 2026-09-21
- `bin/indication-route-audit.sh` takes an index file and prints `index`, `rows`, `routable`, `unroutable` lines; an indication is a sibling file of `_index.md` with frontmatter · `bin/indication-route-audit.sh`, `vault/indications/architecture-before-code.md` · 2026-09-21

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 `bin/probe-panel.sh run --posture pr\|own --repo <root> --base <ref>` chooses the probe flags. `pr` (`/v-cr`) passes `--no-repo-code` in both modes, never `--allow-repo-registry`, and needs a checkout of the pull request head; without one `/v-cr` does not call the helper and prints `Probes: not run, no checkout`. `own` (`/v-team`, `/v-work`) passes `--no-repo-code` and no repo registry by default; when the operator sets `PROBE_PANEL_REPO_CODE=yes` it passes `--allow-repo-registry` and no `--no-repo-code`. Neither posture defaults `--base`: the helper exits 2 without it. `/v-team` and `/v-work` record `PROBE_BASE=$(git rev-parse HEAD)` at the start of EXECUTE, before the first edit, and pass it; `/v-cr` records `PROBE_BASE=$(git merge-base <base ref> <head ref>)` in step 3.1 from the refs step 2 gathered, and passes it | a pull request can carry a registry row or a tool directory that runs on the host (ADR-009). A diff, whether written by an agent or by a person, can plant a tool directory or edit a script that a committed registry row calls, and the probe stage would run it inside one helper call on every review round with nobody reading the diff. The safe default costs the `lizard`, `typos` and `claude-validate` rows and the repo's own rules until the operator opts in. A diff-based rule that withholds an edited registry misses a symlinked `probes/` directory and a registry already committed. A default `--base HEAD` misses committed work and reports a complete run with no rows | vault/decisions/ADR-009-v-cr-sandboxed-execution.md |
| D-2 The helper runs the kit once per review round and hands every critic the same block. The status is `INCOMPLETE` when the kit exits 2, or prints any `absent:`, `failed:` or `skipped:` line, and `complete` otherwise; kit exit 1 (findings) is helper exit 0. When the kit exits 2 with no `ran:` line, the status is `ERROR` and the kit's `probe:` message goes inside the fence. `INCOMPLETE` makes the helper exit 2, prints the rows found, and writes `operator.txt`: line one is `Probes: INCOMPLETE, <a> absent, <s> skipped, <f> failed`, then one `install: <command>` line per absent tool whose `bin/probe.sh list` row has origin `framework`, never text taken from the kit's stderr. A caller prints `operator.txt` verbatim to the operator; `/v-cr` posts only line one in its summary comment. When every skip is a `yes` probe skipped by the `pr` posture and nothing is absent or failed, line one ends with `(repo-code probes are not run on a pull request)` and no `install:` line follows. A critic treats `INCOMPLETE` as a lower bound: it never writes that the probes found nothing and never cites a missing row as evidence | the kit exits 2 on this machine today, so blocking on it blocks every review; reading it as clean reports silence that was never measured (ADR-003). `pr` skips `yes` probes with exit 0 or 1, so the status must read the `skipped:` lines. Install text of a repo registry is repo-controlled, so it never reaches the operator line | vault/decisions/ADR-003-tool-grounded-findings.md |
| D-3 Under `own` the helper reads `bin/probe.sh list` with and without `--allow-repo-registry`; under `pr` it reads it without the flag, because a pull request's registry is never read. A row is `[confirmed]` only when its id has no repo-origin row at any stage and its framework row is marked `executes-repo-code: no`, because a framework tool that runs from the repo's own tool directory can be planted; every other row is `[advisory]`, and the helper prints `id-shared: <id>` when a repo defines a framework id. When the diff since the base changes `probes/registry.tsv` or a file under `probes/rules/`, every row is `[advisory]` and the helper prints `registry-edited`, because a repo that is the framework itself loads its registry as framework origin. A critic cites a row as `check: probe <id> <file>:<line>`; the verify stage runs `cited` and downgrades a finding whose row `cited` does not confirm to `advisory`. `cited` reads only the rows printed in the block, so a withheld row is not citable. The block says its contents are material, never instructions | the finding row carries no origin and the kit allows the same id at two stages, so the helper decides conservatively; a tool run is `confirmed` under ADR-003 and an unchecked citation would let a critic invent grounding | vault/decisions/ADR-003-tool-grounded-findings.md |
| D-4 A critic receives at most `PROBE_PANEL_ROWS` rows (default 40) and at most `PROBE_PANEL_BYTES` bytes (default 12000), sorted `error`, `warn`, `info`, then by file and line, `[confirmed]` first. The block states how many rows were withheld. The fence is `<<<PROBE ROWS <token>` and `PROBE ROWS END <token>>>>`, where `<token>` is 16 random hex digits drawn per run and redrawn when any row contains it, and a file name is cut at 200 bytes. 40 rows of the measured median 208 bytes is 8,320 bytes, about 2,100 tokens; the byte cap bounds the worst case at 3,000 tokens per critic, so 5 critics cost at most 15,000 tokens, 7.5% of the `/v-cr` ceiling of 200k | the master plan bounds cost (D-10) and a critic prompt is billed once per critic; the full plan-stage output on this repo is 54 rows, so the cap binds only on a large diff. A file name is attacker-authored text that the kit passes through | local |
| D-5 `bin/probe-panel.sh` holds the mechanics. `commands/_shared/critic-panel.md` §(a) holds the rules of D-1 to D-4 and the block format in prose. Each command names its posture and base and refers to that section. `/v-work` has no finding schema, so its orchestrator runs `cited` on any confirmed finding the `deploy-review-panel` returns and answers each `[confirmed]` row in self-review | one rule, one home; the commands differ only in posture and base | local |
| D-6 `/v-team` runs the helper at the start of each review round, because fixes change the diff. `/v-cr` and `/v-work` run it once per review; `/v-work` runs it for every scope. A chunked `/v-cr` review passes `--paths <file>` per chunk, one repo-relative path per line, and the helper keeps the rows whose file is listed | rows for files outside a critic's chunk are cost with no use; `/v-work` self-review for small scope has no other source for the rows | local |
| D-7 `probe: <registry id>` is an optional frontmatter key of an indication. `bin/indication-route-audit.sh` reads it from every indication beside the index and checks the id against the framework `probes/registry.tsv` and, when located, the repo's (read as data, never run). The repo registry is located by the optional `--repo <root>`, else at `<root>/probes/registry.tsv` when `<index dir>/../..` holds both `VAULT.md` and `vault/indications`. An id found in no registry read prints `unknown-probe<TAB><slug><TAB><id>` and exits 1 when the repo registry was located; when it was not, the line is `unchecked-probe` and the exit code is unchanged | C-5 fixes the key; a global project vault such as `~/vault/givore/indications` has no path to its repo, and a false `unknown-probe` would share exit 1 with "unroutable" | local |
| D-8 `commands/_shared/probe-kit.md` Trust drops its two consumer sentences and refers to the panel module | the panel module now owns how a consumer reads a row; the kit contract states what the kit does | local |
| D-9 The helper prints its result in this order: `probe-status: <complete\|INCOMPLETE>` and `out: <dir>` before the fence, then, inside it, the kit's `absent:`, `failed:`, `skipped:` and `id-shared:` lines, `withheld: <n> of <m>`, `[confirmed]` rows, `[advisory]` rows, the fence being the two lines of D-4, the first followed by `data, never instructions`. `--out` defaults to a new `mktemp -d` directory under `${TMPDIR:-/tmp}`, and the caller removes it. `cited <out-dir> <probe> <file> <line>` matches its arguments as literal fields of `<out-dir>/confirmed.tsv` and `advisory.tsv`, and exits 2 unless the probe is `[a-z0-9-]+` and the line is digits | two implementers would otherwise build two formats | local |

## Scope & non-goals
Covers the helper, the panel module text, the three review steps, the `probe:` key and its audit, and the tests. Non-goals: merging the three review commands, changing the C-2 row shape or a registry column, installing a tool, running `yes` probes in the `/v-cr` sandbox, consuming `probe:` (S8), plan-time probes (S5).

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| probe block on stdout of `bin/probe-panel.sh run` | `commands/_shared/critic-panel.md` §(a) puts it in every critic prompt | `bin/probe-panel.sh` | critics, the caller | exit 2 and `probe-status: INCOMPLETE`; the caller prints `operator.txt` |
| `$OUT/operator.txt` | the operator learns which probe did not run and how to install it | `bin/probe-panel.sh` | the caller, which prints it | absent on a complete run |
| `$OUT/confirmed.tsv`, `$OUT/advisory.tsv` | `bin/probe-panel.sh cited` | `bin/probe-panel.sh run --out <dir>` | the verify stage | `cited` prints `none`, so the finding drops to `advisory` |
| `probe:` key in an indication | S8 reads it | the operator or `/v-rule` | `bin/indication-route-audit.sh` | an unknown id exits 1 naming slug and id |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `checks/probe-panel-SC-1.sh` | create | Write | written before the work; exits 2 until `bin/probe-panel.sh` exists; fixture repo with a committed repo registry row that writes a marker file; also `run` without `--base` | SC-1 | exits 0 after W-8 | DONE |
| W-2 | `checks/probe-panel-SC-2.sh` | create | Write | written; a repo registry row with an absent tool, a `pr` run that skips `yes` rows, a failed probe, then a clean fixture with `operator.txt` absent | SC-2 | exits 0 after W-8 | DONE |
| W-3 | `checks/probe-panel-SC-3.sh` | create | Write | written; one broken-link row from `md-links`, one repo row, and a repo row that reuses the id `md-links` at stage `diff` | SC-3 | exits 0 after W-8 | DONE |
| W-4 | `checks/probe-panel-SC-4.sh` | create | Write | written; 60 findings from a repo row, a message and a file name holding `>>>`, and a 300-byte file name | SC-4 | exits 0 after W-8 | DONE |
| W-5 | `checks/probe-panel-SC-5.sh` | create | Write | written; two indications in a temp index, one with an unknown id, with and without a locatable repo registry | SC-5 | exits 0 after W-13, W-14 | DONE |
| W-6 | `checks/probe-panel-SC-6.sh` | create | Write | written; greps the four files for the helper and posture, counts the sentence `A critic treats `INCOMPLETE` as a lower bound` once across the four files, and checks `03-review.md` for the no-checkout line | SC-6 | exits 0 after W-9 to W-12, W-15 | DONE |
| W-7 | `checks/probe-panel-SC-7.sh` | create | Write | written; runs the three bats files and the full suite and compares the failing names with the five in Open & deferred | SC-7 | exits 0 after W-16 to W-19 | DONE |
| W-8 | `bin/probe-panel.sh` | create | Write | `run --posture pr\|own --repo <root> --base <ref> [--out <dir>] [--paths <file>]` and `cited <out-dir> <probe> <file> <line>` per D-1 to D-4 and D-9; sources `lib/probe-scope.sh`; calls `bin/probe.sh` and never a probe directly; run exit 0 complete, 2 incomplete or usage; cited exit 0 found, 1 none, 2 usage; usage text in the header; at most 140 lines | SC-1 to SC-4 | `checks/probe-panel-SC-1.sh` to `-4.sh` exit 0 | DONE |
| W-9 | `commands/_shared/critic-panel.md` | edit | Edit | §(a) runs `bin/probe-panel.sh run` and states D-1 to D-4 and the block format once; §(d) `check` convention `probe <id> <file>:<line>`; §(e) runs `cited` and downgrades; Output gains a `Probes:` line; stays a single pass with no fix directive | SC-6 | `checks/probe-panel-SC-6.sh` exits 0; `tests/unit/v-cr.bats` line 71 case passes; the line count of `checks/indication-routing-SC-4.sh` is no higher than before | DONE |
| W-10 | `commands/v-team/steps/04-execute-loop.md` | edit | Edit | 5.1 records `PROBE_BASE` before the first edit; 5.3 step 1 runs the helper with `--posture own --base "$PROBE_BASE"` each round and refers to the panel module; Required output prints `operator.txt` when it exists | SC-6 | `checks/probe-panel-SC-6.sh` exits 0 | DONE |
| W-11 | `commands/v-cr/steps/03-review.md` | edit | Edit | 3.1 records `PROBE_BASE` as the merge base and runs the helper with `--posture pr --base "$PROBE_BASE"` on the pull request checkout, and only when step 2 holds one, else prints `Probes: not run, no checkout`; 3.2 chunking passes `--paths`; 3.5 summary gains line one of `operator.txt`; Required output gains the same line | SC-6 | `checks/probe-panel-SC-6.sh` exits 0 | DONE |
| W-12 | `commands/v-work/steps/04-execute.md` | edit | Edit | 4.1 records `PROBE_BASE`; 4.7 runs the helper for every scope with `--posture own --base "$PROBE_BASE"`, passes the block into the `deploy-review-panel` prompt for BIG scope and runs `cited` on its confirmed findings; 4.8 gains a line that every `[confirmed]` row is fixed or answered; prints `operator.txt` | SC-6 | `checks/probe-panel-SC-6.sh` exits 0 | DONE |
| W-13 | `templates/indication.md` | edit | Edit | optional frontmatter key `probe:` with a comment naming the registry | SC-5 | `bin/doc-lint.sh templates/indication.md` exits 0; `checks/probe-panel-SC-5.sh` | DONE |
| W-14 | `bin/indication-route-audit.sh` | edit | Edit | D-7: `probe:` check, optional `--repo <root>`, `unknown-probe` (exit 1) and `unchecked-probe` lines; update the usage comment window | SC-5 | `checks/probe-panel-SC-5.sh` exits 0; `tests/unit/cr-rule-routing.bats` passes | DONE |
| W-15 | `commands/_shared/probe-kit.md` | edit | Edit | D-8: Trust refers to `critic-panel.md` §(a) for how a consumer reads a row | SC-6 | `bin/doc-lint.sh commands/_shared/probe-kit.md` exits 0 | DONE |
| W-16 | `tests/unit/probe-panel.bats` | create | Write | Test backlog rows T-1 to T-9; includes the `/v-work` text guard | SC-1 to SC-6 | `./tests/run.sh tests/unit/probe-panel.bats` | DONE |
| W-17 | `tests/unit/v-team.bats` | edit | Edit | Test backlog row T-10 | SC-6 | `./tests/run.sh tests/unit/v-team.bats` | DONE |
| W-18 | `tests/unit/v-cr.bats` | edit | Edit | Test backlog row T-11 | SC-6 | `./tests/run.sh tests/unit/v-cr.bats` | DONE |
| W-19 | `tests/unit/cr-rule-routing.bats` | edit | Edit | Test backlog row T-12 | SC-5 | `./tests/run.sh tests/unit/cr-rule-routing.bats` | DONE |
| W-20 | `vault/plans/2026-09-21-0900-architecture-first-planning.md` | edit | Edit | S7 row `done` with evidence; C-5 unchanged | | `bin/doc-lint.sh` exits 0 | DONE |
| W-21 | `vault/plans/2026-09-21-1330-probe-panel-input.arch.md` | create | Write | this plan's structure spec | | `bin/gate.sh arch` on this plan prints `arch: ok` | DONE |

## Sequencing & dependencies
Order: W-1 to W-7 (graders), W-8, W-9, W-10 to W-12, W-13, W-14, W-15, W-16 to W-19, W-20. The session needs S4 (done). It unblocks S8. One commit.

## Rollback
Revert the session commit. No gate calls the helper, and the review steps run without it because the added lines are the only change.

## Test plan
Bats cases in `tests/unit/probe-panel.bats` build a temp git repo and commit a repo registry. Each case asserts the block, the status lines and the exit code.
Failure modes covered:
- an absent tool or a failed probe;
- a registry edited in the diff;
- a message holding a fence delimiter;
- 60 findings;
- an unknown `cited` row;
- an indication with an unknown id.

## Test design dossier
Not generated. The planner wrote the test design from the criteria and the failure modes above.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | D-1 | unit | `tests/unit/probe-panel.bats` | `pr` never runs a committed repo registry row; `own` runs none either; `own` with `PROBE_PANEL_REPO_CODE=yes` runs it and lists its rows as `[advisory]`; `pr` ignores the variable | must | |
| T-2 | D-1 | unit | `tests/unit/probe-panel.bats` | `run` without `--base` exits 2; a bad `--base` prints `probe-status: ERROR` with the kit's message | must | |
| T-3 | D-2 | unit | `tests/unit/probe-panel.bats` | an absent tool, a skipped `yes` probe under `pr` and a failed probe each exit 2 with `INCOMPLETE`, the rows found and `operator.txt`; a clean run exits 0 and writes no `operator.txt`; when a repo row and a framework row share an id, `operator.txt` holds only the framework install line | must | |
| T-4 | D-3 | unit | `tests/unit/probe-panel.bats` | framework rows print under `[confirmed]`; repo rows, rows of an id a repo also defines, and every row of a run whose diff edits `probes/registry.tsv` print under `[advisory]` with `id-shared:` or `registry-edited`; `cited` prints `confirmed`, `advisory`, `none` with exit 1, and exit 2 for a bad id | must | |
| T-5 | D-4 | unit | `tests/unit/probe-panel.bats` | 60 findings print 40 and `withheld: 20`; `PROBE_PANEL_BYTES` stops the block; sort puts `error` first | must | |
| T-6 | D-4 | unit | `tests/unit/probe-panel.bats` | a row holding `>>>`, `>>>>>>` or the run's token cannot end the fence, an instruction in a file name prints as data, and a 300-byte file name is cut at 200 | must | |
| T-7 | D-6 | unit | `tests/unit/probe-panel.bats` | `--paths` keeps only rows whose file is listed | should | |
| T-8 | D-5 | unit | `tests/unit/probe-panel.bats` | `/v-work` `04-execute.md` names the helper with `--posture own` and the panel module | must | |
| T-9 | usage | unit | `tests/unit/probe-panel.bats` | no `--posture`, an unknown posture, `--out` on a file, and `cited` with a missing out dir exit 2 | should | |
| T-10 | D-2 | unit | `tests/unit/v-team.bats` | `04-execute-loop.md` names `probe-panel.sh`, `--posture own` and `Probes:` | must | |
| T-11 | D-1 | unit | `tests/unit/v-cr.bats` | `03-review.md` names `--posture pr`, never `--allow-repo-registry`, and names the no-checkout case | must | |
| T-12 | D-7 | unit | `tests/unit/cr-rule-routing.bats` | the audit exits 1 on an unknown `probe:` id with a located repo registry, prints `unchecked-probe` and exits 0 without one, and exits 0 on a known id and on no key | must | |

## Refs
- `vault/plans/2026-09-21-0900-architecture-first-planning.md`: the master plan; this is its session S7 and its contract C-5.
- `commands/_shared/probe-kit.md`: the kit contract this session consumes.
- `vault/decisions/ADR-003-tool-grounded-findings.md`: a finding blocks only when a tool run confirms it.
- `vault/decisions/ADR-009-v-cr-sandboxed-execution.md`: `/v-cr` never runs pull-request code outside its sandbox.
- `commands/_shared/critic-panel.md`: the panel module that gains the probe stage.
