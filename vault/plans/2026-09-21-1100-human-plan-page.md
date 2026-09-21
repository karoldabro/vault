---
type: plan
project: vault
slug: human-plan-page
repos: [vault]
status: executed
process_record: 2026-09-21-1100-human-plan-page.trail.md
arch_spec: 2026-09-21-1100-human-plan-page.arch.md
human_plan: https://claude.ai/artifact/FUj88e47kH8AWzaZQdcsMz
session:
tags: [plan, architecture, human-plan]
---

# human-plan-page — plan

## Task
Session S3 of `vault/plans/2026-09-21-0900-architecture-first-planning.md`. A script renders the human-readable plan page from a plan and its architecture spec. A gate checks that the page is present and current. The same session wires the page into `/v-team` and regenerates the master plan's page. Keywords: render-human, human_plan, gate human, mermaid, review checklist.

## Open & deferred
- needs the operator: approve the scope and decisions D-1 to D-9 below.
- accepted change: the regenerated master page keeps its pipeline, rules-flow and data-flow diagrams, its session graph and its seven-requests table, moved into its spec. It loses the two illustration diagrams of an example order feature, the hand-written "what you are asked to approve" box and the prose paragraphs, which the terminal decision block carries.
- deferred: prose that explains a design in plain words. A session that wants an explanation writes it in the plan's Task.
- unverified: the renderer under BusyBox `awk`, which the test container uses. A committed golden page compared in the container and on the host tests this.
- unverified: publishing an Artifact from a subagent. The main session publishes.
- accepted limit: the gate cannot tell that the published Artifact equals the local page, and a `human_plan` URL proves only its shape.
- accepted limit: a page opened as a local file shows diagrams as source text, because the page holds no script.
- accepted limit: a diagram line whose label merely contains `click` or `href` is dropped with the hostile lines.
- deferred: `cmd_arch`, `cmd_human` and `bin/render-human.sh` each parse `--plan`/`--repo` arguments the same way, and `human_render` is long; extract a shared helper when a fourth command needs it.
- existing defect, not this plan's: `tests/unit/v-team.bats` lines 54 to 79 use a bare `! grep` in the middle of a test, which never fails a bats test.
- known limit: `bash -s human <plan> < bin/gate.sh` finds no libraries, because `$0` is `bash`; run the file by path.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does an LLM write the page, or a script? | no | `vault/plans/2026-09-21-0900-architecture-first-planning.md` D-3, the hand-built page | defaulted | a script; recorded in D-1 |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN `bin/render-human.sh` renders a plan with a spec THE SYSTEM SHALL write a page holding every spec section as an escaped heading, every mermaid block as a diagram, the first-column value of every spec table row, and the profile's review checklist | functional | command | `checks/human-SC-1.sh` | exit 0 | MET | `checks/human-SC-1.sh` exited 0 |
| SC-2 | WHEN the spec changes after the page was rendered THE SYSTEM SHALL make `bin/gate.sh human` exit 1 and say the page is stale | functional | command | `checks/human-SC-2.sh` | exit 0 | MET | `checks/human-SC-2.sh` exited 0 |
| SC-3 | WHEN a diagram is removed from the page THE SYSTEM SHALL make `bin/gate.sh human` exit 1 and name the first differing line | functional | command | `checks/human-SC-3.sh` | exit 0 | MET | `checks/human-SC-3.sh` exited 0 |
| SC-4 | WHEN `human_plan` is empty, not an `https://claude.ai/artifact/<id>` URL, or a `file:` name other than the page's, or the page file is missing THE SYSTEM SHALL exit 1, and a valid URL or `file:` name SHALL pass | functional | command | `checks/human-SC-4.sh` | exit 0 | MET | `checks/human-SC-4.sh` exited 0 |
| SC-5 | WHEN a spec cell or plan line holds markup such as `<script>` THE SYSTEM SHALL show it as text and the page SHALL hold no `<script` tag | functional | command | `checks/human-SC-5.sh` | exit 0 | MET | `checks/human-SC-5.sh` exited 0 |
| SC-6 | WHEN a plan has a Sessions table with a `depends` column THE SYSTEM SHALL draw the dependency graph as a mermaid flowchart with one bare `A --> B` line per dependency | functional | command | `checks/human-SC-6.sh` | exit 0 | MET | `checks/human-SC-6.sh` exited 0 |
| SC-7 | WHEN a spec mermaid line holds `click`, `%%`, `href`, `javascript` or `vbscript`, in any letter case, THE SYSTEM SHALL leave that line out of the page | functional | command | `checks/human-SC-7.sh` | exit 0 | MET | `checks/human-SC-7.sh` exited 0 |
| SC-8 | WHEN `bin/gate.sh human` runs on this plan from the repo root THE SYSTEM SHALL print `human: ok` for a page this session rendered with the real profile | delivery | command | `checks/human-SC-8.sh` | exit 0 | MET | `checks/human-SC-8.sh` exited 0 |
| SC-9 | WHEN `bin/gate.sh all <plan> --phase approve` runs on the architecture-first master plan THE SYSTEM SHALL reach the human check and pass, and the regenerated master page SHALL hold the master plan's 4 diagrams: the pipeline, the session graph, the rules flow and the spec's data flow | delivery | command | `checks/human-SC-9.sh` | exit 0 | MET | `checks/human-SC-9.sh` exited 0 |
| SC-10 | WHEN a `/v-team` session reads its PROPOSE step and Step 4 THE SYSTEM SHALL tell it to render the page, publish it, record `human_plan` with a `file:` fallback, and run `bin/gate.sh human` | functional | command | `checks/human-SC-10.sh` | exit 0 | MET | `checks/human-SC-10.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | change does what the task asked | met | renderer, gate, profile checklist, `/v-team` wiring and the regenerated master page built; `bin/gate.sh verdict --run` reports SC-1 to SC-10 MET |
| B2 | tests covering the change pass | met | `./tests/run.sh tests/unit`: 832 tests, 5 fail, the same 5 that fail on `HEAD`; `human-plan.bats` 22 of 22 in the BusyBox container; 6 seeded mutants each failed a test |
| B3 | lint passes on changed files | met | `./bin/doc-lint.sh --changed` exits 0 |
| B4 | every review finding fixed or recorded | met | all confirmed findings fixed; the rest are in Open & deferred |
| B5 | invalidated docs updated | met | `templates/plan.md`, `templates/VAULT.md`, ADR-031, the feature dossier, the master plan and its spec |
| B6 | nothing unrelated in the commit | met | `output-styles/director.md` and `scripts/completion-hook.sh` stay unstaged |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | A plan that names a spec has a current human page before approval | HALF-BUILT | `bin/gate.sh human`, run by `bin/gate.sh all --phase approve`; a session runs it because `03-propose-loop.md` (g) and `commands/v-team.md` Step 4 say so, and `tests/unit/v-team.bats` guards that text |
| E-2 | The page is a pure function of the plan and its spec | ENFORCED | `bin/render-human.sh`, the byte comparison in `bin/gate.sh human`, and a golden page compared in the container and on the host |

## Verified current state
- `bin/gate.sh all --phase approve` runs `criteria`, `arch`, `human` and `coverage`; `main` runs only when the file is executed, so `bin/render-human.sh` sources it · `bin/gate.sh` · 2026-09-21
- `bin/gate.sh verdict --run` writes verdict and evidence into the plan, and `04-execute-loop.md` flips work-item status in place · `bin/gate.sh` `record_verdict`, `commands/v-team/steps/04-execute-loop.md` · 2026-09-21
- the master plan's page is rendered by `bin/render-human.sh` and holds 4 diagrams · `vault/plans/2026-09-21-0900-architecture-first-planning.human.html` · 2026-09-21
- the Artifact tool renders `<pre class="mermaid">` natively and keeps the URL when the same file path is republished · the tool contract, and version 5 of https://claude.ai/artifact/LHVhsU2fsQWNFpJTH6NKuC · 2026-09-21
- the plans in `vault/plans/` use `\|` in table cells, bold, nested bullets, numbered lines and lines over 300 characters; they use links twice · `grep -c` over 38 plans · 2026-09-21
- the test container's `awk` is BusyBox and its `coreutils` provides `sha256sum` · `tests/Dockerfile` · 2026-09-21

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 A script renders the page, with no model in the loop | a model omits diagrams silently and varies between runs; a function of the plan and spec cannot | vault/decisions/ADR-031-architecture-first-planning.md |
| D-2 `bin/gate.sh human` re-renders the page in memory and compares it byte for byte with the file on disk | one check proves the page is present, current and untampered | vault/decisions/ADR-031-architecture-first-planning.md |
| D-3 The page shows only what a person reads at approval. A column whitelist per plan section lives in `templates/human-plan-sections.tsv`, and status, date, verdict, evidence and frontmatter are left out | a status flip or a written verdict must not make the page stale | local |
| D-4 A profile lists what a person must confirm as `@review<TAB><one plain sentence>` lines in its `.tsv`, and the page shows them under "Check these yourself" | the checklist differs per project type and belongs with the profile | local |
| D-5 The gate runs only when the plan names an `arch_spec`; a plan that names none is skipped, and `arch` already refuses it in a profiled repo | one refusal per defect | local |
| D-6 Cells and prose escape `&`, `<` and `>`; a mermaid body escapes only `&` and `<`; a mermaid line starting `click` or `%%`, or holding `javascript:`, is dropped; a generated graph holds only ids matching `^[A-Za-z0-9_-]+$` and quoted labels of plain characters | plan text is agent-written and never markup, and mermaid interprets directives itself | local |
| D-7 The renderer is POSIX `awk` and bash, runs under `LC_ALL=C`, reads bodies from files, never iterates with `for (k in a)`, and ends the page with one newline | the same bytes on every awk and locale | local |
| D-8 `bin/gate.sh` sources cleanly when run as a library: `main` runs only when the file is executed | the renderer needs `frontmatter_get` and the profile lookup without a second copy | local |
| D-9 A fixed set of constructs renders in the plan sections: table, bullet list, numbered list, paragraph, bold, code span. Any other line renders as an escaped paragraph | plans use these constructs, and an unknown one must not break the page | local |

## Scope & non-goals
Covers rendering, the gate, the profile checklist, the golden page, the `/v-team` wiring and the master page regeneration. Non-goals: a model-written explanation, `/v-work` pages, the gate on the contracts table (session S6), and any change to the spec format.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `vault/plans/2026-09-21-1100-human-plan-page.human.html`, and one such page beside each plan | `bin/gate.sh human` compares it with a fresh render | `bin/render-human.sh` | the operator through the Artifact, `bin/gate.sh human` | gate exits 1 naming the missing page or the first differing line |
| `human_plan` key in the plan | `bin/gate.sh human` needs a link the operator can open | the PROPOSE session after publishing | `bin/gate.sh human` | gate exits 1 naming the bad value |
| `@review` lines in `arch-profiles/code.tsv` | the page's "Check these yourself" list | the profile author | `bin/render-human.sh` | an absent line yields a page with no checklist |
| `templates/human-plan.html` | `bin/render-human.sh` takes the page skeleton and styles from it | this session | `bin/render-human.sh` | the renderer exits 2 naming the missing file |
| `templates/human-plan-sections.tsv` | `bin/render-human.sh` reads which plan sections and columns to show | this session | `bin/render-human.sh` | the renderer exits 2 naming the missing file |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `commands/_shared/human-plan.md` | create | Write | owns the render rules, page structure, section and column list, `human_plan` values, check order and the exact messages; each stated once; at most 120 lines | SC-1, SC-4 | `bin/doc-lint.sh` exits 0 | DONE |
| W-2 | `bin/gate.sh` | edit | Edit | wrap the final `main "$@"` so it runs only when the file is executed; source `lib/human-check.sh`; route `human`; `all --phase approve` calls it after `arch` with the same `--repo`; usage line | SC-2, SC-4, SC-8 | `./tests/run.sh tests/unit/gate.bats` passes and `bin/gate.sh --help \| grep -c 'gate.sh human'` is at least 1 | DONE |
| W-3 | `lib/arch-check.sh` | edit | Edit | the section loop skips a line whose first field starts with `@` | SC-1 | `./tests/run.sh tests/unit/gate.bats` | DONE |
| W-4 | `arch-profiles/code.tsv` | edit | Edit | `@review<TAB>sentence` lines with no `& < > " backtick` | SC-1 | `checks/human-SC-1.sh` exits 0 | DONE |
| W-5 | `arch-profiles/harness.tsv` | edit | Edit | `@review` lines, same rule | SC-1 | `bin/gate.sh arch tests/fixtures/arch/harness-complete.arch.md` prints `arch: ok` | DONE |
| W-6 | `templates/human-plan-sections.tsv` | create | Write | one line per plan section: name, then the columns shown; Task, Open & deferred, Success criteria, Decisions, Cross-session contracts, Sessions | SC-1 | `checks/human-SC-1.sh` exits 0 | DONE |
| W-7 | `templates/human-plan.html` | create | Write | skeleton and styles with light and dark tokens; the opening tag `<pre class="mermaid">` appears nowhere in it; no script tag | SC-1, SC-5 | `checks/human-SC-5.sh` exits 0 | DONE |
| W-8 | `lib/human-render.sh` | create | Write | per D-6, D-7 and D-9; one function per section kind; no locale-dependent call | SC-1, SC-5, SC-6, SC-7 | `checks/human-SC-1.sh` and `-5.sh` to `-7.sh` exit 0 | DONE |
| W-9 | `bin/render-human.sh` | create | Write | `<plan> [--repo <root>] [--stdout]`; sources `bin/gate.sh`; writes `<plan>.human.html`; exit 2 on an unreadable plan or a plan with no Task | SC-1 | `checks/human-SC-1.sh` exits 0 | DONE |
| W-10 | `lib/human-check.sh` | create | Write | `cmd_human` per `commands/_shared/human-plan.md`, compares with `cmp`, never through `$(...)` | SC-2, SC-3, SC-4 | `checks/human-SC-2.sh` to `-4.sh` exit 0 | DONE |
| W-11 | `lib/shared-module-rules.tsv` | edit | Edit | one owned-rule row naming `human-plan.md` | | `./checks/v-loop-SC-3.sh` exits 0 | DONE |
| W-12 | `tests/fixtures/human/plan.md` | create | Write | a small plan naming `../arch/code-complete.arch.md`, with a Sessions table carrying `depends` | SC-1, SC-6 | `checks/human-SC-1.sh` exits 0 | DONE |
| W-13 | `tests/fixtures/human/expected.html` | create | Write | the page rendered from W-12 on the host; the container test compares against it | SC-1 | `./tests/run.sh tests/unit/human-plan.bats` | DONE |
| W-14 | `tests/unit/human-plan.bats` | create | Write | Test backlog rows T-1 to T-18, run under the test container | SC-1 to SC-7 | `./tests/run.sh tests/unit/human-plan.bats` | DONE |
| W-15 | `checks/human-SC-1.sh` | create | Write | written | SC-1 | exits 0 after W-3 to W-9 | DONE |
| W-16 | `checks/human-SC-2.sh` | create | Write | written | SC-2 | exits 0 after W-2, W-10 | DONE |
| W-17 | `checks/human-SC-3.sh` | create | Write | written | SC-3 | exits 0 after W-2, W-10 | DONE |
| W-18 | `checks/human-SC-4.sh` | create | Write | written | SC-4 | exits 0 after W-2, W-10 | DONE |
| W-19 | `checks/human-SC-5.sh` | create | Write | written | SC-5 | exits 0 after W-8, W-9 | DONE |
| W-20 | `checks/human-SC-6.sh` | create | Write | written | SC-6 | exits 0 after W-8, W-9 | DONE |
| W-21 | `checks/human-SC-7.sh` | create | Write | written | SC-7 | exits 0 after W-8, W-9 | DONE |
| W-22 | `checks/human-SC-8.sh` | create | Write | written | SC-8 | exits 0 after W-23 | DONE |
| W-23 | `vault/plans/2026-09-21-1100-human-plan-page.human.html` | create | Write | rendered by `bin/render-human.sh` from this plan; published with the Artifact tool; the URL goes in `human_plan` | SC-8 | `checks/human-SC-8.sh` exits 0 | DONE |
| W-24 | `vault/plans/2026-09-21-0900-architecture-first-planning.md` | edit | Edit | the S3 row is `done`; C-7 and D-3 match D-1 and D-2 here | | `bin/doc-lint.sh` exits 0 | DONE |
| W-25 | `commands/v-team/steps/03-propose-loop.md` | edit | Edit | (g) after `arch`: read `commands/_shared/human-plan.md`, run `bin/render-human.sh`, publish the page with the Artifact tool after loading its design skill, record `human_plan` (`file:<page name>` when publishing fails), run `bin/gate.sh human` | SC-10 | `checks/human-SC-10.sh` exits 0 | DONE |
| W-26 | `commands/v-team.md` | edit | Edit | Step 4 runs `bin/gate.sh human <plan>` after `arch`, re-renders and republishes when the plan changed after (g), and names the page link in the decision | SC-10 | `checks/human-SC-10.sh` exits 0 | DONE |
| W-27 | `tests/unit/v-team.bats` | edit | Edit | guards that `03-propose-loop.md` names `render-human.sh`, `human_plan` and `gate.sh human`, and `commands/v-team.md` names `gate.sh human` | SC-10 | `./tests/run.sh tests/unit/v-team.bats` | DONE |
| W-28 | `vault/plans/2026-09-21-0900-architecture-first-planning.arch.md` | edit | Edit | add `## Diagrams` holding the pipeline, rules and contracts diagrams of the hand-built page, and `## Operator requests` holding its seven-requests table | SC-9 | `bin/gate.sh arch` on the master plan prints `arch: ok` | DONE |
| W-29 | `vault/plans/2026-09-21-0900-architecture-first-planning.human.html` | edit | Write | regenerated by `bin/render-human.sh`; republished to the same URL | SC-9 | `checks/human-SC-9.sh` exits 0 | DONE |
| W-30 | `vault/decisions/ADR-031-architecture-first-planning.md` | edit | Edit | decision 4 states that a script renders the page and the gate compares it with a fresh render | | `bin/doc-lint.sh` exits 0 | DONE |
| W-31 | `vault/features/architecture-spec.md` | edit | Edit | Contracts and Coupling name the page, the renderer, the gate and the profile checklist lines | | `bin/doc-lint.sh` exits 0 | DONE |
| W-32 | `checks/human-SC-9.sh` | create | Write | written | SC-9 | exits 0 after W-24, W-28, W-29 | DONE |
| W-33 | `checks/human-SC-10.sh` | create | Write | written | SC-10 | exits 0 after W-25, W-26 | DONE |
| W-34 | `tests/unit/gate.bats` | edit | Edit | one case for an `@review` line in a profile | SC-1 | `./tests/run.sh tests/unit/gate.bats` | DONE |
| W-35 | `vault/plans/2026-09-21-1100-human-plan-page.arch.md` | create | Write | this plan's structure spec | SC-8 | `bin/gate.sh arch` on this plan prints `arch: ok` | DONE |
| W-36 | `templates/plan.md` | edit | Edit | the `human_plan` comment names the accepted values and the gate | SC-4 | `bin/doc-lint.sh templates/plan.md` exits 0 | DONE |

## Sequencing & dependencies
Order: W-3 first, since a profile line starting `@` is refused until the loop skips it. Then W-2, W-1, W-6, W-7, W-8, W-9, W-10, W-4, W-5, W-11, W-12, W-13, W-14, W-25 to W-27. Then edit the master plan, W-24, W-28, W-30 and W-31, and render the master page, W-29, last, since any later edit to the master plan stales it. W-23 renders this plan's own page after its last edit. The session needs session S2 (done). It unblocks S5 and S6.

## Rollback
Revert the session commit. A plan that names no `arch_spec` skips the human check, so no other plan is refused. The check runs only in the approve phase.

## Test plan
Bats cases in `tests/unit/human-plan.bats`, run in Docker with `./tests/run.sh tests/unit/human-plan.bats`. Each case renders `tests/fixtures/human/plan.md` into a temp directory. It then derives one defect from the result. The golden page `tests/fixtures/human/expected.html` is rendered on the host and compared inside the container, which uses a different `awk`. Failure modes covered:
- an unreadable plan, a plan with no Task, and a plan with no spec;
- an empty section, and a table cell holding markup or `\|`;
- a mermaid block holding `-->`, `<`, `&`, `click` and `javascript:`;
- a page changed by one byte, and a spec changed after rendering.

## Test design dossier
Not generated. The planner wrote the test design from the criteria, and the generators did not run, so the backlog below is reviewed only by the plan review.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | SC-1 | unit | `tests/unit/human-plan.bats` | every `## ` section of the spec as an escaped heading, every mermaid block and every table's first-column values appear in the page | must | |
| T-2 | SC-5 | unit | `tests/unit/human-plan.bats` | a cell with `<script>alert(1)</script>`, `&` and `"` renders as text and the page holds no `<script` | must | |
| T-3 | D-6 | unit | `tests/unit/human-plan.bats` | a mermaid body keeps `-->` raw and escapes `<` and `&`, and stays inside `pre class="mermaid"` | must | |
| T-4 | SC-2 | unit | `tests/unit/human-plan.bats` | changing one spec cell makes `gate.sh human` exit 1 with `stale` | must | |
| T-5 | SC-3 | unit | `tests/unit/human-plan.bats` | one changed byte in the page exits 1 and names a line number | must | |
| T-6 | SC-4 | unit | `tests/unit/human-plan.bats` | `human_plan` empty, `http://`, an empty id, `file:` with another name, and a missing page each exit 1 | must | |
| T-7 | SC-6 | unit | `tests/unit/human-plan.bats` | a `depends` of `S1, S2` yields both edges, and a row with no dependency yields a lone node | should | |
| T-8 | D-4 | unit | `tests/unit/human-plan.bats` | a profile with no `@review` line yields a page with no checklist heading | should | |
| T-9 | E-2 | unit | `tests/unit/human-plan.bats` | two renders give identical bytes whatever the working directory, and the container's render equals the golden page | must | |
| T-10 | D-9 | unit | `tests/unit/human-plan.bats` | a plan missing one of the listed sections renders no empty heading for it | should | |
| T-11 | D-9 | unit | `tests/unit/human-plan.bats` | a `\|` inside a cell stays one cell, and the renderer and `bin/gate.sh` split the same row into the same cells | must | |
| T-12 | D-9 | unit | `tests/unit/human-plan.bats` | bold, a numbered list, a nested bullet and a line over 300 characters render without breaking the page | should | |
| T-13 | SC-7 | unit | `tests/unit/human-plan.bats` | `click A href "javascript:alert(1)"`, a `%%{init}%%` line and a `javascript:` line are left out of a spec mermaid block | must | |
| T-14 | W-3 | unit | `tests/unit/gate.bats` | a profile holding an `@review` line does not make `gate.sh arch` report a missing section | must | |
| T-15 | D-5 | unit | `tests/unit/human-plan.bats` | a plan that names no `arch_spec` is skipped silently with exit 0 | must | |
| T-16 | D-3 | unit | `tests/unit/human-plan.bats` | flipping a Sessions status or writing a verdict does not change the page | must | |
| T-17 | W-9 | unit | `tests/unit/human-plan.bats` | a plan with no Task, and an unreadable plan, exit 2 from the renderer | should | |
| T-18 | D-6 | unit | `tests/unit/human-plan.bats` | a Sessions scope holding a backtick, a quote or `<b>` yields a node label of plain characters only | must | |
| T-19 | SC-7 | unit | `tests/unit/human-plan.bats` | `Click`, `CLICK`, a `;` joined `click`, a mid-line `%%`, `JAVASCRIPT` and `vbscript` lines never reach the page | must | |
| T-20 | SC-6 | unit | `tests/unit/human-plan.bats` | a repeated session id draws one node, the id `end` is drawn as `n_end`, a long scope is cut at a word boundary, and a cell beyond the header is shown | must | |
| T-21 | SC-4 | unit | `tests/unit/human-plan.bats` | a valid artifact URL alone passes, an unreadable plan exits 2, and `arch: ok` precedes `human: ok` | should | |
| T-22 | SC-3 | unit | `tests/unit/human-plan.bats` | a page that differs only in its final newline names the last line, and a failing render is reported once | should | |

## Refs
- `commands/_shared/architecture-spec.md`: the spec contract the page renders.
- `vault/plans/2026-09-21-0900-architecture-first-planning.md`: the master plan; this is its session S3.
- `vault/decisions/ADR-031-architecture-first-planning.md`: decisions 1 to 4; session S3b amends decision 4.
- `vault/plans/2026-09-21-0900-architecture-first-planning.human.html`: the hand-built page that session S3b replaces with a rendered one.
