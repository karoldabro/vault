---
type: plan
project: vault
slug: framework-hooks-tools-rename
status: executed
process_record: 2026-06-22-1152-framework-hooks-tools-rename.trail.md
tags: [plan, framework, hooks, tooling, session-rename]
---

# framework-hooks-tools-rename — team plan

Three framework gaps: (1) per-project tool/MCP scenario guidance, (2) per-project + per-lifecycle-step
instruction hooks, (3) auto-rename the session after step 1 in both lifecycles.

## Task
Add to the vault framework: (1) tool-scenario guidance covering project task-tracker MCPs (Jira/Asana)
and when to use them; (2) per-project, per-step **instruction** hooks declared in VAULT.md and honored by
both `/v-work` and `/v-team`; (3) a step-1 session-rename that surfaces `/rename <slug>` for the user.
Keywords: tool-playbook, hooks, per-project-config, VAULT.md, session-rename, lifecycle-steps.

Locked decisions: **instruction-only hooks** (no shell exec); rename targets the **CC conversation
title**; per-project tool guidance lives in a **VAULT.md section + a generic tool-playbook pattern**.

## Plan

Dependency-ordered. All changes are docs + step-file markdown — no shell/code runtime.

**Phase vocabulary (14, symmetric).** Global bookends + `pre_`/`post_` per machine step:

- `on_start` — lifecycle begins (first action after config resolution at §1.4, before any step work).
- `pre_analyze` / `post_analyze`
- `pre_load_context` / `post_load_context`
- `pre_propose` / `post_propose`
- `pre_execute` / `post_execute`
- `pre_commit` / `post_commit`  (commit = `git commit` in §5.1)
- `pre_capture` / `post_capture`  (capture = `/v-capture` in §5.5)
- `on_end` — lifecycle terminates by **any** path (success, gate-rejection, abort).

APPROVAL GATE (step 4) is **not** hookable (user approval, not a machine phase); `post_propose` fires
before it and `pre_execute` after it. v-team's internal panel/review **loop rounds** are non-hookable
(would couple VAULT.md to loop state); `pre_/post_propose` and `pre_/post_execute` fire at the
loop's outer boundary. All hooks optional, instruction-only.

1. **`vault-guide.md` §1.1** — extend the VAULT.md section table with two rows: `hooks` (phase→prose,
   instruction-only) and `tools` (task_tracker, task_tracker_mcp, task_tracker_key, guidance). Add a
   new subsection **"Hooks — phases, precedence & failure modes"**: the 7 phase names + when each fires
   (incl. post_commit-vs-post_capture timing); instruction-only / never-execute-as-shell; precedence
   (CLAUDE.md + indications override a hook on conflict — surface at approval gate); MCP-down → proceed,
   never halt; malformed → skip + surface; panel loops non-hookable. State VAULT.md is read **once** at
   step 1 §1.4 and carried forward (config/structure/behaviour/**hooks**/**tools**).

2. **`v-work/steps/01-analyze.md`** — (a) §1.4: extend the VAULT.md read to also extract `hooks`,
   `tools`, and `behaviour.suggest_rename` into the carried config. (b) new §1.4b: fire `on_start` then
   `pre_analyze` hooks (if present), right after config resolution, before §1.1 work. (c) new §1.5
   "Suggest session rename": compute kebab slug from the restatement; if `suggest_rename` (default true),
   surface the exact `/rename <slug>` line for the user — explicitly noted as a one-paste manual action,
   not zero-touch. (d) end-of-step: honor `post_analyze`. Covers BOTH lifecycles (v-team reuses 01
   verbatim).

3. **`v-work/steps/02-load-context.md`** — (a) start-of-step marker: honor `pre_load_context`. (b) new
   §2.3c "Project task tracker": if the task references a ticket/issue, the declared `tools.task_tracker*`
   MCP is usually the best first source (suggestion, not a gate); none declared → ask; MCP down → fall
   back + surface, never halt. (c) end-of-step marker: honor `post_load_context`.

4. **Pre/post honor markers in remaining steps** — `03-propose.md` (`pre_propose`/`post_propose`),
   `04-execute.md` (`pre_execute`/`post_execute`), `05-commit-capture.md` (`pre_commit` before §5.1 /
   `post_commit` after the commit, before §5.5 / `pre_capture` before §5.5 / `post_capture` after §5.5 /
   `on_end` at the very end). v-team `03-propose-loop.md` / `04-execute-loop.md` honor
   `pre_/post_propose` and `pre_/post_execute` at the loop's outer boundary (per-round cycles
   non-hookable). Each marker is one line: "Honor carried VAULT.md `<phase>` hook if present; treat as
   binding for this step; skip with a surfaced note if it conflicts with CLAUDE.md/indications or its
   MCP is down." `on_end` also fires on early termination (gate rejection / abort)."

5. **`tool-playbook.md`** — new §6 "Project tools (task trackers & team MCPs)". **Suggestions, not
   rules**: the playbook is guidance, Claude auto-selects tools — no hard ordering, no "must". Frame
   as: "if the task references a ticket and the repo declares a tracker in VAULT.md
   `tools`, that MCP is usually the best first source; if none is declared or it's down, fall back
   naturally (ask / vault / web)." Cite vault-guide §1.1 for where the per-project facts live; do **not**
   repeat the layer hierarchy and do **not** impose a decision tree. Keep the example (Jira/Asana) as
   illustration, not a mandate. Also add a one-line framing note near the top of `tool-playbook.md`:
   "These are suggestions — Claude selects the tool that fits; the cost hierarchy is a sensible default,
   not a gate." Soften rigid tool-**selection** language (e.g. "never grep…") toward suggestion; keep
   genuine **safety** notes intact (e.g. Morph `// ... existing code ...` markers).

6. **`templates/VAULT.md` + repo `VAULT.md`** — add commented `## hooks` (Jira `on_start` +
   `post_commit` example), `## tools` (Jira example), and `behaviour.suggest_rename: true`. Keep both in
   sync (drift-tested).

7. **Dispatcher notes** — one line each in `v-work.md` and `v-team.md` pointing to the hooks contract in
   vault-guide §1.1 (no logic in the dispatcher; it stays thin).

## Test plan

Framework is markdown honored by the model — behavior isn't unit-testable, but **doc-consistency** is.
bats-core tests (Docker, never host) grepping the framework tree. New test file
`tests/unit/test-hooks-tools-rename.bats`.

## Test backlog

All rows run from `tests/unit/test-hooks-tools-rename.bats`.

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| arch-t1 | local | unit | `vault-guide.md` §1.1 | table has `hooks` + `tools` rows + failure-mode subsection | must | implemented |
| arch-t2 | local | unit | `templates/VAULT.md` ↔ repo `VAULT.md` | both expose same top-level section set (drift guard) | must | implemented |
| skep-t3 | local | unit | `commands/v-work/steps/01-analyze.md` | contains hook-load (§1.4), `on_start` fire (§1.4b), rename sub-step (§1.5) | must | implemented |
| skep-t4 | local | unit | each lifecycle step file under `commands/v-work/steps/` and `commands/v-team/steps/` | contains its `pre_`/`post_` honor markers; full 14-phase vocabulary documented in `vault-guide.md` | must | implemented |
| arch-t5 | local | unit | `tool-playbook.md` | has "Project tools" §6; does not duplicate layer rules | should | implemented |
| skep-t6 | local | unit | `vault-guide.md` hooks subsection | documents instruction-only + precedence + MCP-down-proceeds | should | implemented |
| skep-t7 | local | unit | `commands/v-work/steps/02-load-context.md` | has §2.3c project-task-tracker step | should | implemented |

## Open trade-offs / deferrals

- **Session rename is not zero-touch.** `/rename` works mid-session but only from user input; the model
  cannot fire built-in slash commands. Deliverable = lifecycle computes the slug and surfaces
  `/rename <slug>` for a one-paste run. Key named `suggest_rename`, not `auto_rename`, for honesty.
- **Pre-step hooks deferred.** Only `on_start` + per-step `post_<step>` ship. A "before each command"
  hook is approximated by `on_start` + the prior step's `post_` hook. `pre_<step>` can extend the
  vocabulary later if a real need appears.
- **v-team panel-loop cycles non-hookable.** No per-round hook point exists inside the loop; one would
  couple VAULT.md to internal loop state. `vault-guide.md` §1.1 documents the limit.
- **Rename honoring stays in step 1.** `v-work/steps/01-analyze.md` §1.4 already reads VAULT.md there,
  and the requirement is a rename after the first step.

## Refs
<!-- session that executes this -->
- Process record: `vault/plans/2026-06-22-1152-framework-hooks-tools-rename.trail.md` — findings,
  dispositions and rejected options for this plan.
- Executed by session [[2026-06-22-1152-framework-hooks-tools-rename]].
- Feedback captured: [[feedback-tools-suggestions-not-rules]] (tool-playbook = suggestions, not rules).
