---
type: plan
project: vault
slug: human-page-essentials
repos: [vault]
status: executed
process_record: 2026-09-24-1902-human-page-essentials.trail.md
arch_spec: 2026-09-24-1902-human-page-essentials.arch.md
human_plan: https://claude.ai/artifact/MAf32L9fMMW8dP9SfPszH4
session_of:
session:
tags: [plan, architecture, human-plan]
---

# human-page-essentials — plan

<!-- Governed by commands/_shared/document-standard.md. Contract class: current truth only. -->

## Task
Cut the human plan page that `bin/render-human.sh` writes down to what only the operator can supply or judge. That is the decisions waiting on them, the defaults taken for them, the trade-offs users will notice, the checks they run by hand, the diagrams and the method signatures. Everything the gates already check stays in the agent plan and the spec.
Keywords: render-human, human page, human-plan-sections, Open & deferred status, erDiagram, signatures, diagram labels.

## Open & deferred
- user-visible: every existing `.human.html` page differs from a fresh render after this change. The 6 in-flight plans in `~/vault/givore/plans/` with `status: proposed` get a stale refusal from `bin/gate.sh human` at approval. Their session re-renders and republishes, as `commands/v-team.md` Step 4 already says.
- deferred: the published Artifacts of the 12 executed plans in `vault/plans/` keep their old content. Their local `.human.html` files are re-rendered so `bin/gate.sh human` stays green.
- deferred: the gauge preview comes from a scratchpad copy of `~/vault/givore/plans/2026-09-24-1345-value-estimate-gauge.md` and its spec. In the copy, O2, O3, O4, O9, O10 and O11 are relabelled `user-visible`. Another session owns that plan, so the original is not edited.
- deferred: a screen picture on the page. A spec has no image section yet.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does the page keep the Decisions table? | no | the operator's review of `https://claude.ai/artifact/Y23LSErPdNUAsL3hVBfRsV`: 25 decision rows, all agent-owned detail | defaulted | no; a decision the operator must make is an Open item whose status names the operator |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN `bin/render-human.sh` renders a plan THE SYSTEM SHALL show only Open items whose status names the operator or `user-visible`, only `defaulted` open questions, only `observed` success criteria without verdict or evidence, no Decisions, Layers & placement, Reuse map or Size budgets heading, no checklist and no `Keywords:` text | functional | command | `checks/human-page-SC-1.sh` | exit 0 | MET | `checks/human-page-SC-1.sh` exited 0 |
| SC-2 | WHEN the spec's Data model is a table THE SYSTEM SHALL draw one `erDiagram` with one entity per table and one `parent \|\|--o{ child : column` line per valid reference, and SHALL list each Interfaces row as one `Interface.method(params): returns` line | functional | command | `checks/human-page-SC-2.sh` | exit 0 | MET | `checks/human-page-SC-2.sh` exited 0 |
| SC-3 | WHEN a spec holds a Data flow diagram and a diagram in an unlisted section THE SYSTEM SHALL draw both on the page | functional | command | `checks/human-page-SC-3.sh` | exit 0 | MET | `checks/human-page-SC-3.sh` exited 0 |
| SC-4 | WHEN a Data flow label holds a parameter list inside double quotes THE SYSTEM SHALL draw it with empty parentheses | functional | command | `checks/human-page-SC-4.sh` | exit 0 | MET | `checks/human-page-SC-4.sh` exited 0 |
| SC-5 | WHEN `./tests/run.sh tests/unit` runs in Docker THE SYSTEM SHALL fail no test that passes on the base commit `da3a2bd` | functional | command | `checks/human-page-SC-5.sh` | exit 0 | MET | `checks/human-page-SC-5.sh` exited 0 · v-team PROPOSE output contract is two-layer and translates panel vocabulary |
| SC-6 | WHEN `bin/gate.sh human` runs on each of the 12 plans in `vault/plans/` that has a `.human.html` page THE SYSTEM SHALL print `human: ok` for every one | delivery | command | `checks/human-page-SC-6.sh` | exit 0 | MET | `checks/human-page-SC-6.sh` exited 0 |
| SC-7 | WHEN the operator opens the preview of the value-gauge plan page THE SYSTEM SHALL show their decisions, user-visible trade-offs, hand checks, diagrams and signatures, and nothing a gate already checks | delivery | observed | open the preview Artifact link; it fails when the operator names a block they do not need or a thing they need that is missing. `no-command: whether content is essential is the operator's judgement, and no detector can make it` | the operator names no block to cut and nothing missing | MET | the operator opened the preview `https://claude.ai/artifact/FDPXtEhAtQt3KstMrkW4wN` and answered "nothing to add" |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| dod-1 | `test_command: ./tests/run.sh tests/unit` | met | `checks/human-page-SC-5.sh`: no new failures; `tests/unit/human-plan.bats` 33 of 33; 3 seeded mutants each failed a test |
| dod-2 | `lint_command: ./bin/doc-lint.sh --changed` | met | exited 0 with no output |
| dod-3 | `delivery_command: ./bin/gate.sh verdict <plan> --run && ./bin/gate.sh all <plan> --phase close` | met | both exited 0 |

## Decisions

| decision | reason | record |
|----------|--------|--------|
| `templates/human-plan-sections.tsv` lists every page block as `source`, `section`, `mode`, `cols` and `heading`, tab-separated. The rows are in the spec's Config points. A block with nothing to show is left out with its heading. | One data file decides the page. | local |
| A plan or spec section with no TSV row stays off the page. Its mermaid blocks still reach the page under its heading. The `er` mode replaces any mermaid block in Data model. | A diagram can never go missing, and none is drawn twice. | local |
| Mode `match:<columns>:<words>` judges each rendered item whole: a table row, a bullet with its indented continuation lines, or a paragraph. A row matches when the first named column that exists contains one of the words, or its whole text does when no named column exists. A bullet or paragraph matches when its text before the first `:` contains one. Matching ignores case, `*` and backticks, and `###` lines are dropped. | Real plans write `**needs the operator:**`, `needs operator`, a `state` column, `Status` and multi-line bullets. A near miss shows the item instead of hiding it. | local |
| Open & deferred shows items that name `operator` under "Needs your decision" and items that name `user-visible` or `user visible` under "Users will notice". A plain `open` or `blocked` item matches no word and stays off the page; `blocked — needs the operator` matches and shows. | Open and blocked work is usually the agent's, and a matching word always wins. | local |
| Mode `er` builds tokens from `[A-Za-z0-9_]` only, turning every other character into `_`. It maps `UQ` to `UK` and drops other keys. It draws a relationship only for a `references` value of the form `table.column`. The generated text skips the hostile-line filter. | Mermaid's ER parser rejects spaces, dots and `UQ`, and the filter would drop a `click_count` column. | local |
| Mode `labels` removes a parenthesis group, nested groups included, inside a double-quoted string of a mermaid block, keeping `()`. It removes a group only when the character before `(` is a letter, digit or `_`, so `"PROPOSE step (a)"` stays. It applies to Data flow. | The signatures list carries the parameters, so 28 existing specs render clean with no refusal. | local |
| The page ends with one line naming the plan's file name and the `arch_spec` value as written. | The operator finds the detail, and the bytes do not depend on the path the caller passed. | local |
| The checklist is dropped. `@review` lines leave both profiles, and `lib/arch-check.sh` stops skipping `@` lines. | It asked the operator to check sections no longer on the page. | local |

## Scope & non-goals
Covers the renderer, the section list, the human-page contract, both profiles and their starting text, and the plan template. It also covers the unit tests and fixtures, the old human-page checks, the 12 local pages and the release. Leaves unchanged: the gate's byte comparison, the escaping rules, the page's CSS, the published Artifacts of executed plans, and every plan in another repo's vault.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `templates/human-plan-sections.tsv` rows | `HUMAN_AWK_PLAN` and `HUMAN_AWK_SPEC` in `lib/human-render.sh` | W-1 | `lib/human-render.sh` | a missing file: exit 2 `missing: templates/human-plan-sections.tsv`; an unknown mode: exit 2 `unknown mode <mode> for <section>` |
| `user-visible` status in `## Open & deferred` | the "Users will notice" block, which is left out without it | a `/v-team` PROPOSE session, following `templates/plan.md` | `lib/human-render.sh` match; the operator | a status without `user` and `visible` hides the item with no error; `templates/plan.md` states the two words the page looks for |
| Footer line | the operator who wants the detail | `lib/human-render.sh` | the operator | never missing: the renderer refuses a plan with no `arch_spec` |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `templates/human-plan-sections.tsv` | rewrite as the Config points rows of the spec | Write | five fields | SC-1 | SC-1 | DONE |
| W-2 | `lib/human-render.sh` | read the new TSV; add the modes `match`, `task`, `er`, `signatures` and `labels`; route spec sections through the TSV; keep unlisted diagrams; drop `HUMAN_AWK_REVIEW`; append the footer | Edit | POSIX awk; `LC_ALL=C`; no `for (k in a)` | SC-1, SC-2, SC-3, SC-4 | SC-1 to SC-4 | DONE |
| W-3 | `commands/_shared/human-plan.md` | rewrite Page structure for the TSV fields, the modes, the diagram rule and the footer; delete Profile checklist lines | Edit | the rules live here once | SC-1 | `bin/doc-lint.sh commands/_shared/human-plan.md` exits 0 | DONE |
| W-4 | `arch-profiles/code.tsv` | delete the `@review` lines and their comment | Edit | | SC-1 | SC-5 | DONE |
| W-5 | `arch-profiles/harness.tsv` | delete the `@review` lines and their comment | Edit | | SC-1 | SC-5 | DONE |
| W-6 | `lib/arch-check.sh` | remove `@*` from the profile-loop skip at line 333 | Edit | | SC-5 | SC-5 | DONE |
| W-7 | `arch-profiles/code.md` | rewrite the Data flow comment and example: nodes name the component and method, parameters live in Interfaces | Edit | | SC-4 | `bin/doc-lint.sh` exits 0 | DONE |
| W-8 | `arch-profiles/harness.md` | same comment rule as W-7 | Edit | | SC-4 | `bin/doc-lint.sh` exits 0 | DONE |
| W-9 | `templates/plan.md` | in the Open & deferred comment, name the six statuses and say the page shows items naming `operator` or `user-visible` | Edit | | SC-1 | `bin/doc-lint.sh templates/plan.md` exits 0 | DONE |
| W-10 | `tests/fixtures/human/plan.md` | add Open items in table and bullet form with each status style, a Keywords line, a `defaulted` question and an `observed` criterion with a verdict | Edit | | SC-1 | SC-5 | DONE |
| W-11 | `tests/fixtures/arch/code-complete.arch.md` | keep the fixture valid; its hand-written `erDiagram` stays to prove `er` replaces it | Edit | | SC-2 | SC-5 | DONE |
| W-12 | `tests/fixtures/human/expected.html` | regenerate on the host with `bin/render-human.sh --stdout` | Bash | render on the host, compare in the container | SC-5 | golden case | DONE |
| W-13 | `tests/unit/human-plan.bats` | replace the checklist cases; add cases for each match style, `task`, `er` edge inputs, `signatures`, `labels`, unlisted and replaced diagrams, the footer, a verdict written after rendering | Edit | negative assertions go through `absent` | SC-1 to SC-5 | SC-5 | DONE |
| W-14 | `tests/unit/gate.bats` | replace the `@review` case at line 1236 with a case that a profile line is always a section | Edit | | SC-5 | SC-5 | DONE |
| W-15 | `checks/human-SC-1.sh` | drop the checklist assertions | Edit | | SC-6 | runs to exit 0 | DONE |
| W-16 | `checks/human-SC-8.sh` | drop the checklist assertion | Edit | | SC-6 | runs to exit 0 | DONE |
| W-17 | `checks/human-SC-9.sh` | drop the checklist assertion; keep the 4-diagram assertion | Edit | | SC-6 | runs to exit 0 | DONE |
| W-18 | `checks/human-page-fixture.sh`, `checks/human-page-SC-1.sh` to `checks/human-page-SC-6.sh` | keep the fixture and checks in step with SC-1 to SC-6 | Edit | exit 0 met, 1 not met, 2 cannot say | SC-1 to SC-6 | each runs | DONE |
| W-19 | `vault/plans/*.human.html` (12 files) | re-render each with `bin/render-human.sh <plan>` | Bash | local files only | SC-6 | SC-6 | DONE |
| W-20 | `vault/features/architecture-spec.md` | update lines 29 and 58 to the new blocks | Edit | | SC-1 | `bin/doc-lint.sh` exits 0 | DONE |
| W-22 | `/tmp/claude-1000/-home-kdabrow-workspace-vault/f714f0ec-40ba-48a7-b201-77811d4296b9/scratchpad/gauge/` | copy the gauge plan and spec, relabel O2, O3, O4, O9, O10 and O11 `user-visible`, render with `bin/render-human.sh`, publish as a new Artifact | Bash | the original givore plan is not edited | SC-7 | the operator opens the link | DONE |
| W-21 | `.claude-plugin/plugin.json` | set `version` to `1.11.0` in its own `chore(release)` commit, then push `main` to `origin` | Edit | after SC-1 to SC-6 are MET | SC-5 | `git log origin/main -1` shows the release commit | DONE |

## Rollback
`git revert` of the implementation and release commits restores the old renderer, the TSV, the profiles and the 12 pages. A second push publishes the revert. The gauge preview is a separate Artifact and can be deleted.

## Test plan
Unit tests go in `tests/unit/human-plan.bats` and `tests/unit/gate.bats` and run in Docker through `./tests/run.sh tests/unit`. The golden page is rendered on the host and compared in the BusyBox container. Scenarios:
- `match`: `needs the operator:`, `**needs the operator:**`, `needs operator —`, `deferred to the operator:`, `blocked — needs the operator`, `User-Visible`, a `state` column, a `Status` header, a table with neither column, a multi-line bullet and a paragraph. Plain `accepted`, `open` and `blocked` stay hidden, each shown item appears once, and a hidden bullet's continuation line does not leak.
- `task`: Keywords as its own line and at the end of a paragraph.
- `er`: a `UQ` key, a `timestamp with time zone` type, a `public.orders` table, a `click_count` column, a `-` reference, and a hand-written `erDiagram` that is replaced. An `n/a` Data model is left out.
- `signatures`: `-` params, a throws value, a `\|` union.
- `labels`: a quoted label with a parameter list, nested parentheses `Svc.run(x: (int, int))`, `"PROPOSE step (a)"` left unchanged, and an unquoted round node left unchanged.
- Staleness: writing `MET` and evidence into an observed criterion leaves `bin/gate.sh human` at `human: ok`.

## Refs
- `commands/_shared/human-plan.md`: the page contract this plan rewrites.
- `vault/decisions/ADR-031-architecture-first-planning.md`: decision 4, the script-rendered page, still holds.
- `vault/plans/2026-09-21-1100-human-plan-page.md`: the plan that built the page.
- `2026-09-24-1902-human-page-essentials.trail.md`: process record.
