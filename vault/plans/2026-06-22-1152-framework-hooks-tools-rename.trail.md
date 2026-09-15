---
type: trail
project: vault
plan: 2026-06-22-1152-framework-hooks-tools-rename
personas: [none — framework repo; degraded to v-work-with-a-panel]
rounds: 1
convergence: clean
tags: [trail, record]
---

# 2026-06-22-1152-framework-hooks-tools-rename — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`vault/plans/2026-06-22-1152-framework-hooks-tools-rename.md`, which carries the current truth only.

Nothing in the lifecycle reads this file back. It exists so a decision can be audited months later.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Hooks contract lives in `vault-guide.md` §1.1 | a new standalone `lifecycle-hooks.md` | a separate doc fragments the per-project config contract across two files |
| v-team panel-loop cycles are non-hookable, and the fact is documented | per-round hook points inside the loop | a per-round hook couples `VAULT.md` to internal loop state |
| Rename honoring stays in `v-work/steps/01-analyze.md` | move it to `02-load-context.md` | the ask was "after the first step", and §1.4 already reads `VAULT.md` in step 1 |
| Key named `suggest_rename` | `auto_rename` | `/rename` is user-invoked; `auto_` would name a capability the model does not have |
| `tools` carries plain keys with no static-vs-prose split | split static facts into `tools`, per-step prose into `hooks` | the split was incoherent at the boundary and forced arbitrary placement |
| 14 symmetric phases (`pre_`/`post_` per machine step plus `on_start`/`on_end`) | the 11-phase draft vocabulary | the draft mixed `post_analyze` with `pre_load`/`post_load` asymmetrically |

## Findings & dispositions

### Round 0 — draft

**F1 — Tool-scenario guidance (ask 1).** Add `tool-playbook.md` §6 "Project tools (task trackers &
per-project MCP)": generic scenario + decision rule (task names a ticket → consult the project's declared
tracker MCP before grep/web; prefer declared MCP; none declared → ask/skip). The *which/how* is filled
per project by the VAULT.md `tools` section (F3). Add a short lifecycle-step→tools scenario index.

**F2 — Instruction hooks (ask 2).** New VAULT.md `## hooks` section, instruction-only, keyed by lifecycle
phase shared across both lifecycles: `on_start`, `post_analyze`, `pre_load`/`post_load`,
`pre_propose`/`post_propose`, `pre_execute`/`post_execute`, `pre_commit`/`post_commit`, `post_capture`.
Each value = prose (string or list) injected into the agent at that phase and treated as binding for that
step. Define the phase names + honoring contract once in a shared doc (`lifecycle-hooks.md` or a
vault-guide section); each step file gets a one-line "honor VAULT.md hooks for phase X". `on_start` =
the "before starting work" hook; `post_commit` = the "post-commit action per project" ask.

**F3 — Per-project tool guidance in VAULT.md (ask 1/3 home).** New VAULT.md `## tools` section:
`task_tracker:` (jira|asana|linear|github-issues|none), `task_tracker_mcp:`, `task_tracker_key:`,
`usage:` prose. Documented in vault-guide §1.1 table. LOAD CONTEXT reads it when a task references a
ticket. Static facts in `tools`; per-step prose in `hooks`.

**F4 — Session rename (ask 3).** Add `01-analyze.md` §1.5 "Rename session": after the restatement,
compute a kebab slug, surface `/rename <slug>` for the user to run. Gate via VAULT.md
`behaviour.auto_rename` (default true) + optional title template. Lives in 01 only → both lifecycles get
it with no duplication.

### Round 1 — findings + dispositions

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| architect | a1 | BLOCKER | confirmed | hooks contract in new doc fragments config | applied — contract → vault-guide §1.1 |
| architect | a2 | MAJOR | confirmed | v-team panel loops not covered by flat phases | applied — documented non-hookable |
| architect | a3 | MAJOR | confirmed | tools/hooks static-vs-prose split incoherent | applied — `tools` simplified, no artificial split |
| architect | a4 | MAJOR | confirmed | template VAULT.md not updated → drift | applied — update both + drift test (arch-t2) |
| skeptic | s1 | MAJOR | confirmed | steps don't re-read VAULT.md; hooks would silently no-op | applied — carry-forward from §1.4, explicit markers |
| skeptic | s2 | MAJOR | confirmed | `auto_rename` mislabeled (it's manual) | applied — renamed `suggest_rename` + honest docs |
| skeptic | s5 | MAJOR | advisory | no failure-mode/precedence spec | applied — precedence subsection in vault-guide |
| skeptic | s6 | MINOR | advisory | 11 phases = scope creep | applied — cut to 7 step-boundary hooks |
| both | b1 | MINOR | confirmed | post_commit vs post_capture timing fuzzy | applied — timing defined in vault-guide |
| skeptic | s7 | MINOR | advisory | tracker query not wired into step 2 | applied — new §2.3c |
| architect | a6 | NIT | confirmed | phase names vs step names | applied — `post_<step>` naming mirrors steps |

### Diff-review round 1 — findings + dispositions

Same two lenses, against the staged diff.

| persona | verdict | finding | disposition |
|---------|---------|---------|-------------|
| architect | APPROVE | all 7 plan items present; cross-refs resolve; 14 phases consistent; DRY (contract once in vault-guide); rename honest; both VAULT.md in sync | — (clean) |
| skeptic | APPROVE_WITH_NITS | n1: later-step hook markers don't restate carry-forward | applied — added "loaded at step 1, persisted" to 02/03/04 markers |
| skeptic | " | n2: §1.4b on_start ordering vs restatement implicit | applied — §1.4b now says "after §§1.1–1.3" |
| skeptic | " | n3: templates/VAULT.md doesn't warn against `run:` shell syntax | applied — added "there is no `run:` syntax" |

## Metrics

| round | new confirmed blockers | findings-delta | persona overlap | confirmed / advisory | verdicts |
|---|---|---|---|---|---|
| 0 — draft | — | 4 draft findings | — | — | no critique yet |
| 1 — plan | 1 (resolved) | 11 | 3 clusters (carry-forward, rename, scope) | 7 / 4 | both REQUEST_CHANGES |
| 1 — diff review | 0 | 3 | — | 0 / 3 | APPROVE + APPROVE_WITH_NITS |

Convergence declared after round 1: every confirmed finding was applied in v1 and no open blocker
remained. Round 2 would have re-spawned on a fully revised low-risk doc plan. Test suite at close:
109/109 green, including the 7 new cases.

## Advisory test hints

The seven backlog rows in the plan came from the two lenses: `arch-t1`, `arch-t2` and `arch-t5` from
the architect lens; `skep-t3`, `skep-t4`, `skep-t6` and `skep-t7` from the skeptic lens.

## Rejected / deferred

- **`lifecycle-hooks.md` as a standalone contract doc.** Replaced by `vault-guide.md` §1.1; a second
  home for per-project config splits what one read must resolve.
- **The 11-phase draft vocabulary** (`on_start`, `post_analyze`, `pre_load`/`post_load`,
  `pre_propose`/`post_propose`, `pre_execute`/`post_execute`, `pre_commit`/`post_commit`,
  `post_capture`). Replaced by the 14-phase symmetric set plus `on_end`.
- **`behaviour.auto_rename`.** Renamed to `suggest_rename`; the model cannot fire `/rename` itself.
- **A hard decision tree in `tool-playbook.md`** ("consult the tracker MCP before grep/web"). Cut to a
  suggestion: the playbook is guidance and Claude auto-selects tools.
- **Per-critic-round hook points in the v-team loop.** Rejected; they would couple `VAULT.md` to
  internal loop state.
