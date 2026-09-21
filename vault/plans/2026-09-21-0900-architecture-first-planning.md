---
type: plan
project: vault
slug: architecture-first-planning
repos: [vault]
status: executed
process_record: 2026-09-21-0900-architecture-first-planning.trail.md
arch_spec: 2026-09-21-0900-architecture-first-planning.arch.md
human_plan: https://claude.ai/artifact/LHVhsU2fsQWNFpJTH6NKuC
session: vault/sessions/2026-09-21-1015-architecture-first-planning-s1-s2.md
tags: [plan, master-plan, architecture, probes]
---

# architecture-first-planning — master plan

## Task
Make `/v-team` and `/v-pm` plan the structure of the work before any code exists: a machine-checked
architecture spec, a human-readable artifact generated from it, deterministic probes run by
independent auditors, probe results fed to every review panel, and an on-demand skill that turns an operator's review comments into rules. Keywords: architecture spec,
arch_profile, human plan artifact, probes, auditors, master plan, review panel, review-to-rule skill.

This plan is a master plan: it holds the order of nine sessions and executes S1 and S2 only. Each
later session writes its own plan, criteria and work items. The spec for this plan is
`2026-09-21-0900-architecture-first-planning.arch.md` in this folder. The spec contract (sections,
columns, check order, messages) is `commands/_shared/architecture-spec.md`.

## Open & deferred
- needs the operator: approve S1 and S2 as this session's scope, and S3 to S9 as later sessions.
- deferred: S3 to S9, one session row each below.
- unverified: 12 tool claims in the probe catalog carry `(?)` (Atlas lint licence tier, DCM licence and
  JSON flag, `phparkitect --format=json`, `tbls lint --format json`, PHPMD empty-catch rule name,
  Semgrep and ast-grep Dart and Vue support, lizard `--json`, PMD 7 CPD flags, typos on PyPI, Qlty
  offline claim, `claude plugin validate`). S4 verifies each before a row enters `probes/registry.tsv`.
- unverified: most research figures came through a summarising fetch tool. W-1 re-opens each URL before
  its figure is written into a shipped document.
- unverified: publishing an Artifact from a subagent. Publishing from the main session works (this plan's page). S3 tests the subagent path.
- existing defect, not this plan's: `vault/decisions/` holds two files numbered ADR-030.
- existing defect, not this plan's: 5 unit tests fail on `HEAD` (`v-reconcile.md` has no frontmatter description, `commands/v-loop/adapters/test-and-repair.md` has no path note, and three others).
- deferred: `lib/arch-check.sh` repeats one row-loop skeleton seven times and holds two functions over 40 lines. Extract a shared row iterator when a later profile adds tables.
- deferred: the spec gate checks form, not truth; a session can write plausible rows. S5 adds probes that compare the spec with the existing code.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does the probe kit live in this framework or in `vault-quality-gates`? | no | README of `vault-quality-gates`; the operator's plugin registry | defaulted | framework; recorded in D-4 |

## Success criteria
<!-- Criteria cover S1 and S2. Each later session adds its own criteria to its own plan. -->

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN an operator opens `vault/research/ai-code-slop.md` THE SYSTEM SHALL show eight numbered mechanisms, each with a source URL and a `verified:` field | artifact | command | `checks/arch-SC-1.sh` | exit 0 | MET | `checks/arch-SC-1.sh` exited 0 |
| SC-2 | WHEN `bin/gate.sh arch` reads a spec that omits a required section or lacks `type: arch-spec` THE SYSTEM SHALL exit 1 with the message from `commands/_shared/architecture-spec.md`, and print `arch: ok` for a complete spec of either profile | functional | command | `checks/arch-SC-2.sh` | exit 0 | MET | `checks/arch-SC-2.sh` exited 0 |
| SC-3 | WHEN a code spec has an untyped interface parameter, a table without a primary key, a foreign key without an index, or a `new` reuse row without a reason THE SYSTEM SHALL exit 1 and name the row | functional | command | `checks/arch-SC-3.sh` | exit 0 | MET | `checks/arch-SC-3.sh` exited 0 |
| SC-4 | WHEN a harness spec lists a `new: no` path that is absent from disk THE SYSTEM SHALL exit 1 and name the path | functional | command | `checks/arch-SC-4.sh` | exit 0 | MET | `checks/arch-SC-4.sh` exited 0 |
| SC-5 | WHEN `bin/gate.sh all <plan> --phase propose` runs on this plan THE SYSTEM SHALL print `arch: ok`, and WHEN a profiled repo has a plan with no `arch_spec` or a profile mismatch THE SYSTEM SHALL exit 1 | delivery | command | `checks/arch-SC-5.sh` | exit 0 | MET | `checks/arch-SC-5.sh` exited 0 |
| SC-6 | WHEN `bin/doc-lint.sh --list-caps` runs THE SYSTEM SHALL list type `arch-spec`, both templates and both fixtures SHALL pass, and a 310-line spec SHALL fail | functional | command | `checks/arch-SC-6.sh` | exit 0 | MET | `checks/arch-SC-6.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | change does what the task asked | met | S1 and S2 built; scope cut: none; `bin/gate.sh verdict <plan> --run` reports SC-1 to SC-6 MET |
| B2 | tests covering the change pass | met | `./tests/run.sh tests/unit`: 803 tests, 5 fail, the same 5 that fail on `HEAD` (`document-standard.bats` unknown-type and `--compare`, `plugin-install.bats` two path notes, `research-clarify.bats` research sources); 3 seeded mutants in `lib/arch-check.sh` each failed at least one arch test |
| B3 | lint passes on changed files | met | `./bin/doc-lint.sh --changed` exits 0 |
| B4 | every review finding fixed or recorded | met | all confirmed findings fixed; two recorded in Open & deferred |
| B5 | invalidated docs updated | met | `commands/v-team.md`, `commands/v-team/steps/03-propose-loop.md`, `templates/plan.md`, `templates/VAULT.md`, ADR inventory, indications index |
| B6 | nothing unrelated in the commit | met | `git status --short` lists only this plan's files; `output-styles/director.md` and `scripts/completion-hook.sh` stay unstaged |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | A profiled repo's PROPOSE session drafts no work item before the spec passes | HALF-BUILT | `bin/gate.sh arch` and its tests exist; a session runs it only because `commands/v-team/steps/03-propose-loop.md` (g) and `commands/v-team.md` Step 4 say so, and `tests/unit/v-team.bats` guards that text |
| E-2 | Data-model and interface rules | ENFORCED | `bin/gate.sh arch`, `tests/unit/gate.bats` arch cases, `checks/arch-SC-3.sh` |
| E-3 | Every dependency between two sessions of a master plan has a contract row | OPEN | `bin/gate.sh master <plan>`, built in S6 |

## Verified current state
- `bin/gate.sh all --phase propose` and `approve` run `arch` after `criteria`; `/v-team` calls `gate.sh arch` in step (g) and in Step 4 · `grep -n 'gate.sh arch' commands/v-team.md commands/v-team/steps/03-propose-loop.md` · 2026-09-21
- `dod_profile` accepts `code` and `ai-instructions`; this repo declares `code`, and 13 of 13 operator VAULT.md files do · `bin/gate.sh:449`, `grep -rh '^dod_profile' VAULT.md files` · 2026-09-21
- plan type cap is 300 lines · `bin/doc-lint.sh --list-caps` · 2026-09-21
- `table_rows` reads every row after the first separator line under a `##` heading; a later dash-only row is data · `bin/gate.sh:96` · 2026-09-21
- `check_is_claimed_elsewhere` scans every `*.md` beside a plan except `*.trail.md` and `*.brief.md` · `bin/gate.sh:190` · 2026-09-21
- `scripts/completion-hook.sh:87` lists plans by `status: approved`; a spec carries no `status` key · 2026-09-21
- `vault-quality-gates` is a push-time ratchet with parsers for jscpd, phpstan and cloc · its README · 2026-09-21
- `commands/_shared/critic-panel.md` is shared by `/v-cr` and `/v-team`; `/v-work` spawns `deploy-review-panel` for large changes and self-reviews small ones · `grep -n 'panel' commands/v-work/steps/04-execute.md commands/v-cr/steps/03-review.md` · 2026-09-21
- panels already receive indications (`/v-cr` routes each rule by path glob) but run only the pack's analyzers, not a probe per indication · `commands/v-cr/steps/03-review.md:38` · 2026-09-21
- `recycling-api` runs Larastan level 5, phpat, phpmd, jscpd and the ratchet; no operator repo runs Rector, deptrac, Semgrep or ast-grep · grep of composer.json and configs · 2026-09-21
- this machine has none of phpstan, phpmd, rector, jscpd, semgrep, ast-grep, ruff, knip · `command -v` · 2026-09-21
- `/media/kdabrow/Programy/vivi` is Python and shell, not Laravel · file search · 2026-09-21
- 97.0% of structural failures in agent-written code evaded type checking and 100% evaded tests and static security scans · https://arxiv.org/html/2607.08981v1 · 2026-09-21

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 A plan is four files: `plans/<slug>.md` for agents, `plans/<slug>.arch.md` for structure, the trail, and a generated human artifact | probes need structured input, and the human view renders from it | vault/decisions/ADR-031-architecture-first-planning.md |
| D-2 A profile is a data file pair `arch-profiles/<name>.tsv` and `.md`, found in the repo first and then in the framework, and loaded only when named; `arch_profile` in `VAULT.md` names it; absent means `none`; this repo declares `harness` | a new project type is a new file and no code change; `dod_profile` is `code` in every repo, including this harness repo | vault/decisions/ADR-031-architecture-first-planning.md |
| D-3 The human artifact is generated from a committed template and verified by a gate that finds every spec element in it | generators emit, checkers confirm | vault/decisions/ADR-031-architecture-first-planning.md |
| D-4 The probe kit lives in this framework: `bin/probe.sh` and `probes/` | probes run while an agent plans and reviews; `vault-quality-gates` runs at push time | vault/decisions/ADR-031-architecture-first-planning.md |
| D-5 A probe never installs a tool; a missing tool prints `absent: <project-scope install command>` | global installs and package changes need consent | local |
| D-6 A probe finding blocks only when a tool run produced it; model-only observations stay advisory | existing grounding rule | vault/decisions/ADR-003-tool-grounded-findings.md |
| D-7 The spec and plan-time stages belong to `/v-team` and `/v-pm`. The review panels of `/v-team`, `/v-work` and `/v-cr` stay separate commands; each reads probe results through its existing review step | the operator keeps three commands with their own flows; `/v-do` is unchanged | vault/decisions/ADR-015-retier-lifecycle-lite-critic-fast-path.md |
| D-8 A rule written from a review comment is accepted with a firing bad fixture, a silent good fixture and a recorded finding count on the current repo | prevents rules that never fire or fire everywhere | local |
| D-9 A repo's ruleset is its project vault `indications/` plus rule files in the repo; probes run the rule files and each indication names its probe | `rule-inventory.md` scores this framework's own rules and is the wrong store for another repo | local |
| D-12 Turning comments into rules is an on-demand skill, `/v-rule`, that no command calls by default | the knowledge is needed only after a review that left comments | local |
| D-13 `/v-rule` accepts comments only from the operator's own forge account | anyone can comment on a public PR, and an accepted comment becomes a rule | local |
| D-15 Every master plan carries a `## Cross-session contracts` table (id, contract, produced by, consumed by, shape), and a gate refuses a master plan where a dependency between two sessions carries no contract, or a contract names a session that does not exist | a session that consumes another's output otherwise redefines its shape, and later sessions then disagree | vault/decisions/ADR-031-architecture-first-planning.md |
| D-14 Outside `--sandbox`, `/v-cr` runs only probes marked `executes-repo-code: no` | ADR-009: `/v-cr` never runs pull-request code, and some analyzers load repo config that executes | vault/decisions/ADR-009-v-cr-sandboxed-execution.md |
| D-10 The plan-time stage adds at most 50% to the token cost of a `/v-team` PROPOSE; S5 measures the baseline and reports the delta | longer planning is only worth it when its cost is bounded | local |
| D-11 A spec is type `arch-spec`, cap 300 lines | a 10-table feature estimates at 190 to 230 lines, and it sits beside a 300-line plan | vault/decisions/ADR-031-architecture-first-planning.md |

## Scope & non-goals
Covers the nine sessions below. Non-goals: installing any probe tool, changing `vault-quality-gates`,
merging `/v-work`, `/v-team` and `/v-cr` (each keeps its own flow), and claiming that longer plans reduce rework (no controlled study
exists; the plan targets reuse, layering and data model, where agents fail most).

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `arch-profiles/code.tsv`, and one such file per profile | `bin/gate.sh arch` reads the section list of the profile a spec names | framework, or the repo in its own `arch-profiles/` | `lib/arch-check.sh` | an unknown name exits 1 naming the value; a broken line exits 1 naming the validator or kind |
| `arch-profiles/code.md`, and one such file per profile | PROPOSE step (a) instantiates it into the spec | framework, or the repo | PROPOSE session, `bin/gate.sh arch`, the S3 renderer | an unedited copy exits 1 as a template placeholder |
| `arch_spec` key in `templates/plan.md` | `bin/gate.sh arch` resolves a plan to its spec through it | PROPOSE session | `bin/gate.sh` | a profiled repo's plan without it exits 1 |
| `arch_profile` key in `templates/VAULT.md` | `bin/gate.sh arch` reads the repo's profile | operator or `bin/vault-init.sh` | `bin/gate.sh` | absent means `none`, so no repo is refused for lacking it |
| `commands/_shared/architecture-spec.md` | step (a) of `commands/v-team/steps/03-propose-loop.md` | S2 session | every PROPOSE session | step (a) has nothing to read; `tests/unit/v-team.bats` fails on the missing path |
| `vault/research/ai-code-slop.md` | ADR-031 cites it | S1 session | S3 to S9 sessions | `checks/arch-SC-1.sh` exits 1 |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `vault/research/ai-code-slop.md` | create | Write | headings `### M1 <title>` to `### M8 <title>`; under each, a line at column 0 `verified: primary` or `verified: summary-only`; each URL re-opened | SC-1 | `checks/arch-SC-1.sh` exits 0 | DONE |
| W-2 | `vault/decisions/ADR-031-architecture-first-planning.md` | create | Write | records D-1 to D-4, D-11 and D-15; Context names the `vault-quality-gates` boundary | | `bin/doc-lint.sh` exits 0; `grep -c 'ADR-031' vault/decisions/_inventory.md` is 1 | DONE |
| W-3 | `vault/decisions/_inventory.md` | edit | Edit | one row for ADR-031 | | `./tests/run.sh tests/unit/v-team.bats` inventory case | DONE |
| W-4 | `vault/indications/architecture-before-code.md` | create | Write | E-1 as a recognition test; names `vault/research/ai-code-slop.md` | | `grep -c 'ai-code-slop' <file>` is 1 | DONE |
| W-5 | `vault/indications/_index.md` | edit | Edit | one row for W-4 | | `grep -c 'architecture-before-code' <file>` is 1 | DONE |
| W-6 | `checks/arch-SC-1.sh` | create | Write | written | SC-1 | exits 0 after W-1 | DONE |
| W-7 | `checks/arch-SC-2.sh` | create | Write | written | SC-2 | exits 0 after W-15 | DONE |
| W-8 | `checks/arch-SC-3.sh` | create | Write | written | SC-3 | exits 0 after W-15 | DONE |
| W-9 | `checks/arch-SC-4.sh` | create | Write | written | SC-4 | exits 0 after W-15 | DONE |
| W-10 | `checks/arch-SC-5.sh` | create | Write | written | SC-5 | exits 0 after W-15, W-20, W-21 | DONE |
| W-11 | `checks/arch-SC-6.sh` | create | Write | written | SC-6 | exits 0 after W-12, W-13, W-16 | DONE |
| W-12 | `arch-profiles/code.md` | create | Write | starting text of the code profile; `type: arch-spec`; no `status` key | SC-2, SC-3, SC-6 | `bin/doc-lint.sh arch-profiles/code.md` exits 0 | DONE |
| W-13 | `arch-profiles/harness.md` | create | Write | starting text of the harness profile | SC-4, SC-6 | `bin/doc-lint.sh arch-profiles/harness.md` exits 0 | DONE |
| W-30 | `arch-profiles/code.tsv` | create | Write | section list of the code profile, in the format of `commands/_shared/architecture-spec.md` | SC-2, SC-3 | `checks/arch-SC-3.sh` exits 0 | DONE |
| W-31 | `arch-profiles/harness.tsv` | create | Write | section list of the harness profile | SC-2, SC-4 | `checks/arch-SC-4.sh` exits 0 | DONE |
| W-14 | `commands/_shared/architecture-spec.md` | create | Write | owns sections, columns, check order and messages; each rule stated once | SC-2 | `bin/doc-lint.sh` exits 0 | DONE |
| W-15 | `bin/gate.sh` | edit | Edit | source `lib/arch-check.sh` (W-27) and route `arch` to `cmd_arch`; `cmd_config` stays unchanged; `table_rows` treats only the first separator line as the separator; `all` calls `cmd_arch` in `propose` and `approve` and accepts `--repo`; `check_is_claimed_elsewhere` skips `*.arch.md`; reuse `table_rows`, `table_header`, `frontmatter_get`; widen the `usage` line window | SC-2 to SC-5 | `checks/arch-SC-2.sh` to `-5.sh` exit 0; `bin/gate.sh --help \| grep -c 'gate.sh arch'` is at least 1 | DONE |
| W-16 | `bin/doc-lint.sh` | edit | Edit | type `arch-spec`, cap 300, in `cap_for_type`, `is_known_type` and `--list-caps`; infer the type for `*.arch.md` beside the `*.trail.md` case | SC-6 | `checks/arch-SC-6.sh` exits 0 | DONE |
| W-17 | `templates/plan.md` | edit | Edit | frontmatter keys `arch_spec` and `human_plan` | SC-5 | `bin/doc-lint.sh templates/plan.md` exits 0 | DONE |
| W-18 | `commands/v-team/steps/03-propose-loop.md` | edit | Edit | (a) instantiates the spec beside plan and trail; (g) runs `bin/gate.sh arch`; keep the literal `plans/YYYY-MM-DD-HHMM` | SC-5 | `./tests/run.sh tests/unit/v-team.bats` | DONE |
| W-19 | `commands/v-team.md` | edit | Edit | Step 4 runs `bin/gate.sh arch <plan>` next to `coverage`; exit 1 stops the gate | SC-5 | `grep -c 'gate.sh arch' commands/v-team.md` is at least 1 | DONE |
| W-20 | `templates/VAULT.md` | edit | Edit | optional `arch_profile` key with its three values and default | SC-5 | `bin/doc-lint.sh templates/VAULT.md` exits 0 | DONE |
| W-21 | `VAULT.md` | edit | Edit | `arch_profile: harness` | SC-5 | `bin/gate.sh config .` exits 0 | DONE |
| W-22 | `tests/unit/gate.bats` | edit | Edit | Test backlog rows T-1 to T-21, defects written inline from the two fixtures | SC-2 to SC-5 | `./tests/run.sh tests/unit/gate.bats` | DONE |
| W-26 | `tests/unit/document-standard.bats` | edit | Edit | Test backlog row T-22 | SC-6 | `./tests/run.sh tests/unit/document-standard.bats` | DONE |
| W-27 | `lib/arch-check.sh` | create | Write | holds `cmd_arch` and `vault_key` and every check behind them, following the check order in W-14's file, on a CR-stripped copy, with its own printer (`REFUSED arch <path>: <problem> [<row>]`, one `violations` bump per defect); sourced by `bin/gate.sh` so that file stays under its size budget | SC-2 to SC-5 | `checks/arch-SC-2.sh` to `-5.sh` exit 0 | DONE |
| W-29 | `vault/plans/2026-09-21-0900-architecture-first-planning.human.html` | create | Write | source of the published human page; republish keeps its URL in `human_plan` | | `human_plan` key holds the URL | DONE |
| W-28 | `lib/shared-module-rules.tsv` | edit | Edit | one owned-rule row naming `architecture-spec.md`, which two tests require of every shared module | | `./checks/v-loop-SC-3.sh` exits 0 | DONE |
| W-23 | `tests/fixtures/arch/code-complete.arch.md` | create | Write | valid code spec | SC-2, SC-3 | `checks/arch-SC-2.sh` | DONE |
| W-24 | `tests/fixtures/arch/harness-complete.arch.md` | create | Write | valid harness spec | SC-2, SC-4 | `checks/arch-SC-2.sh` | DONE |
| W-25 | `vault/plans/2026-09-21-0900-architecture-first-planning.arch.md` | create | Write | this plan's own harness spec | SC-5 | `checks/arch-SC-5.sh` case (a) | DONE |

## Sequencing & dependencies
Order: S1, S2, S3, S4, S5, S6, S7, S8, S9. S2 needs S1's ADR. S3 needs S2's spec. S5 needs S3 and S4.
S6 needs S2 and S3. S7 needs S4. S8 needs S4 and S7. S9 needs S4 and S5. Within S2, W-14 (done) precedes W-12 and W-13. W-15 precedes W-16 only in review order; both
land in one commit.

## Cross-session contracts
Each later session plans its own work items. These shapes are fixed now, so a session that consumes one
does not redefine it. The producing session may add columns, never rename or drop one.

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
| C-1 | spec format | S2 | S3, S5, S6 | `commands/_shared/architecture-spec.md` |
| C-2 | probe finding row | S4 | S5, S7, S8 | TSV `probe file line severity rule message`; exit 0 clean, 1 findings, 2 could not run |
| C-3 | probe registry `probes/registry.tsv` | S4 | S5, S7, S8, S9 | columns `id stack stage detect run parser cost executes-repo-code install`; `stage` is `plan`, `diff` or `review`; a missing tool reports `absent: <project-scope install command>` |
| C-4 | probe commands | S4 | S5, S7 | `bin/probe.sh list`, `detect`, `run <stage>`, `diff`, `scale` |
| C-5 | indication-to-probe link | S7 | S8 | optional `probe: <registry id>` in an indication's frontmatter |
| C-6 | rule file location | S8 | S7, S9 | `probes/rules/<slug>.<ext>` in the target repo, plus one registry row |
| C-7 | human page check | S3 | S5, S6 | `bin/gate.sh human <plan>` finds every spec table, interface and diagram in the page |

## Sessions

| id | scope | command | status | depends | date | evidence |
|----|-------|---------|--------|---------|------|----------|
| S1 | research doc, ADR-031, indication | /v-work | done | | 2026-09-21 | `checks/arch-SC-1.sh` exits 0; `vault/decisions/ADR-031-architecture-first-planning.md` written |
| S2 | arch spec contract, `gate.sh arch`, PROPOSE and approval wiring | /v-team | done | S1 | 2026-09-21 | `checks/arch-SC-2.sh` to `-6.sh` exit 0; `./tests/run.sh tests/unit/gate.bats` 93 of 93 |
| S3 | human plan artifact: template, renderer step, `gate.sh human`, `human_plan` link; falls back to a local HTML file when publishing fails | /v-team | todo | S2 | 2026-09-21 | |
| S4 | probe kit core: `bin/probe.sh`, `probes/registry.tsv`, harness probes, `probe.sh scale`, schema duplicate-column, index and naming probes, similar-method probe, verified tool list | /v-team | todo | S1 | 2026-09-21 | |
| S5 | plan-time probes: auditor agents, longer planning stage, cost delta per D-10 | /v-team | todo | S3, S4 | 2026-09-21 | |
| S6 | master plan template with a required `## Cross-session contracts` table and its artifact, `gate.sh master` (D-15, E-3), `/v-pm` and `(f3)` in `commands/v-team/steps/03-propose-loop.md` write and read it, sub-plan ordering gate | /v-team | todo | S2, S3 | 2026-09-21 | |
| S7 | probe results as a panel input: `commands/_shared/critic-panel.md` runs `bin/probe.sh diff` in its ground-first stage; `/v-team` execute, `/v-cr` review (D-14) and `/v-work` review read it; each indication names its probe | /v-team | todo | S4 | 2026-09-21 | |
| S8 | `/v-rule` skill: operator comments in, indication plus rule file plus fixtures out (D-8, D-12, D-13) | /v-team | todo | S4, S7 | 2026-09-21 | |
| S9 | stack packs for Laravel, Nuxt, Flutter, Python and SQL, validated on `recycling-api` and one Nuxt repo | /v-work | todo | S4, S5 | 2026-09-21 | |

## Rollback
Every change is additive. Revert the session commit. A repo without `arch_profile` reads as `none`, so
no repo is refused by the arch check, and plans written before this change keep passing `gate.sh all`.

## Test plan
Bats cases in `tests/unit/gate.bats`, run in Docker with `./tests/run.sh tests/unit/gate.bats`. Each case
derives one defect from a fixture with `sed` or `awk` and asserts the exit code and that stderr names the
failing row. Failure modes to cover: unreadable spec (exit 2), spec with no `type`, profile mismatch,
profiled repo with a plan naming no spec, and a `*.arch.md` beside a plan that must not be read as a plan.

## Test design dossier
Resolution matrix for `gate.sh arch` (repo profile, input, result):

| repo arch_profile | input | spec named | spec profile | result |
|-------------------|-------|------------|--------------|--------|
| code or harness | plan | none or empty | | exit 1, names no arch_spec |
| code or harness | plan | file missing | | exit 1, names the path |
| code or harness | plan or spec | present | equals repo | exit 0, `arch: ok` |
| code or harness | plan or spec | present | differs, missing or invalid | exit 1, names profile |
| none, absent, or no VAULT.md | plan | none | | exit 0, silent |
| none, absent, or no VAULT.md | plan or spec | present | valid | validated, exit 0, `arch: ok` |
| any other value | any | | | exit 1, names the value |
| any | unreadable file | | | exit 2 |
| any | other `type:` | | | exit 1, names `type: arch-spec` |

Fault hypotheses covered: a `## ` line inside a fence (T-11), CRLF (T-12), duplicate heading (T-13),
missing trailing pipe, missing column and unescaped pipe (T-14), substring table names (T-9), column
order (T-15). Generator output is advisory until the diff review confirms each row against real code.

## Test backlog
All rows target `tests/unit/gate.bats` unless stated; defects are derived inline from the two fixtures.

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | matrix row 8 | unit | `tests/unit/gate.bats` | unreadable or missing file exits 2, empty stdout, stderr names it | must | |
| T-2 | matrix row 1 | unit | `tests/unit/gate.bats` | profiled repo, plan with `arch_spec` absent then empty: exit 1; via `all --phase propose` and `approve`; other phases make no arch call | must | |
| T-3 | matrix row 5 | unit | `tests/unit/gate.bats` | no profile, absent key, no VAULT.md: silent exit 0; a `*.arch.md` beside a plan is not read as a plan | must | |
| T-4 | matrix rows 3, 4 | unit | `tests/unit/gate.bats` | profile equal, differing, missing, on the direct and plan-resolved paths | must | |
| T-5 | matrix row 2 | unit | `tests/unit/gate.bats` | plan names a missing spec: exit 1 naming the path | must | |
| T-6 | matrix row 7 | unit | `tests/unit/gate.bats` | invalid `arch_profile` value, inline comment, CRLF, explicit `none`, prefix key `x_arch_profile` | must | |
| T-7 | Reuse rules | unit | `tests/unit/gate.bats` | table-driven: `reuse` with `-`, `extend` with empty symbol, `new` with no reason, decision `replace` each exit 1 naming the row | must | |
| T-8 | Data model rules | unit | `tests/unit/gate.bats` | `n/a: reason` ok; `n/a:` and `n/a` refuse; `n/a` beside a table refuses | should | |
| T-9 | Data model rules | unit | `tests/unit/gate.bats` | second table valid while `order_lines` has no PK exits 1 naming `order_lines`, not `orders`; FK with `-` refuses; two PK rows accepted | must | |
| T-10 | Files rules | unit | `tests/unit/gate.bats` | `new: no` missing path, `new` blank, `loaded` invalid, `..` path each refuse; `new: yes` missing path ok | must | |
| T-11 | H1 | unit | `tests/unit/gate.bats` | a fenced block containing `## Fake` does not truncate its section | should | |
| T-12 | H2 | unit | `tests/unit/gate.bats` | CRLF copy of the complete spec exits 0; CRLF copy of the no-PK spec still exits 1 | must | |
| T-13 | H3 | unit | `tests/unit/gate.bats` | a second `## Interfaces` with an untyped row refuses as a duplicate section | must | |
| T-14 | H4, H5, H6 | unit | `tests/unit/gate.bats` | no trailing pipe ok; missing `references` header exits 1 naming it; unescaped extra pipe exits 1 | must | |
| T-15 | MR1, MR4 | unit | `tests/unit/gate.bats` | reordering rows or columns keeps the verdict; appending a valid row keeps a refusal | should | |
| T-16 | params grammar | unit | `tests/unit/gate.bats` | `-`, ` - `, `a: int`, `Map<string, int>`, `?string`, `string[]`, `int\|string` pass; empty, `a`, `a:`, `: int`, `a: int,`, `a: int = 1` refuse | must | |
| T-17 | identifiers | unit | `tests/unit/gate.bats` | `Order Lines`, `1orders`, empty name refuse | should | |
| T-18 | Size budgets | unit | `tests/unit/gate.bats` | `0`, `-1`, `1.5`, `abc`, empty, overflow refuse with exit 1, never 2 | should | |
| T-19 | output contract | unit | `tests/unit/gate.bats` | exit code is 0, 1 or 2; refusal lines match `^REFUSED arch <path>: .* \[<row>\]$`; success stdout is exactly `arch: ok <file>` | must | |
| T-20 | determinism | unit | `tests/unit/gate.bats` | two runs are byte-identical; verdict unchanged by mtime, cwd; spec checksum unchanged | should | |
| T-21 | frontmatter | unit | `tests/unit/gate.bats` | `type: arch_spec`, `Arch-Spec`, quoted, `status` present, empty `plan`, no `---`: each refuses | should | |
| T-22 | doc-lint cap | unit | `tests/unit/document-standard.bats` | 299 and 300 lines pass, 301 fails naming the cap; `--list-caps` prints a line matching `^arch-spec +300$`; `arch-spec` is not a record type | must | |

## Refs
- `vault/decisions/ADR-003-tool-grounded-findings.md`: a finding blocks only when a tool confirms it.
- `vault/indications/plan-appetite-not-tasks.md`: the sizing and sessions tracker this plan follows.
- `vault/architecture/session-gates.md`: the gate contract W-15 extends.
- `commands/_shared/critic-panel.md`: the panel module `/v-cr` and `/v-team` share; S7 extends its inputs.
- README of the `vault-quality-gates` plugin: the push-time ratchet this plan does not duplicate.
