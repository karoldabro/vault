---
description: Multi-agent persona-critique dev lifecycle. Drafts a plan, runs parallel project-specific critics (tool-grounded) that propose design fixes + tests, loops to convergence, then implements with a code-review panel loop.
argument-hint: [task description]
---

# /v-team — persona-critique development lifecycle

Heavier sibling of `/v-work` for **BIG / high-stakes work**. Same vault-first lifecycle, but PROPOSE
and EXECUTE run **panel loops**: a set of project-specific persona critics review in parallel, each
through its own tool-grounded lens, proposing design fixes **and tests**; a synthesizer revises; the
panel re-runs until convergence. The same personas then review the implementation diff.

Thin dispatcher — each step is loaded on demand. Reuses `/v-work` steps 01/02/05 verbatim; only
PROPOSE and EXECUTE get looped variants. `/v-team` therefore **depends on `/v-work` being installed**
(both ship in the same framework repo).

**`/v-team` is the escalation, not the default.** Use `/v-work` for routine work — it has a single-pass
**lite critic** (`03-propose.md` §3a.6) when you want a second opinion, at a fraction of the cost. A
`/v-team` run costs roughly **2× a `/v-work` session** (~20k of scaffolding + 30–60k of agent fan-out
across 6–12 spawns: up to ~3 critics × 2 rounds × 2 loops + `team_max_test_designers` generators), and
measured across June–July 2026 it delivered the **same ~79% completion rate** as `/v-work`. Reach for it
only when a wrong design decision is **expensive to reverse** — architecture, schema, auth, billing,
cross-repo contracts — not because you want *a* second opinion.

---

## Tools — preferred, force when present (never gating)

Identical to `/v-work` — OpenViking, claude-mem, Serena, MorphLLM, graphify are the token-saving
backbone; plus the **Agent** tool for the critic panel (parallel spawn). Canonical health-check +
fallback table and full rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md`. Persona resolution:
`$VAULT_FRAMEWORK_PATH/personas/_resolution.md`.

**Per-project hooks + tools.** A repo's `VAULT.md` can attach `hooks` (per-phase instructions) and
`tools` (task-tracker MCP guidance), read once at step 1 and carried through the run — `pre_/post_propose`
and `pre_/post_execute` fire at the panel-loop outer boundary (rounds non-hookable). Contract:
`$VAULT_FRAMEWORK_PATH/vault-guide.md` §1.1.

---

## On start: create task list

Use `TaskCreate` to add one task per step (below). Mark `in_progress` when starting, `completed` when
done — the list is the enforcement mechanism, do not skip a step. COMMIT + CAPTURE is `completed` only
after `/v-capture` has run.

1. ANALYZE
2. LOAD CONTEXT
3. PROPOSE (panel loop)
4. APPROVAL GATE
5. EXECUTE (review loop)
6. COMMIT + CAPTURE

**If invoked with a `<feature>` (from `/v-pm`), prepend a Step 0 — FEATURE PICKUP task** (below);
otherwise skip it.

---

## Step 0 — FEATURE PICKUP (only when invoked with a `<feature>`)
When `/v-team` is invoked with a feature name — or the current project vault has a `features/<feature>`
symlink into `_features/` — Read `~/.claude/commands/v-team/steps/00-feature-pickup.md` and execute it
**before Step 1**: pick up conversation threads addressed to this project, surface replies to questions
this project raised, and run the deterministic contracts-drift check against the shared `contracts.md`.
This is how the cross-project planning substrate (`/v-pm`) reaches execution. No feature arg → skip
Step 0 entirely (ordinary `/v-team` run).

## Step 1 — ANALYZE
Read `~/.claude/commands/v-work/steps/01-analyze.md`, then execute.
**v-team addendum:** also Read `$VAULT_FRAMEWORK_PATH/personas/_resolution.md`, resolve the persona
pack, and **select the critics for this change** (§2 there). Append one line to the ANALYZE output:
`Personas: <pack> → [selected names]   (skipped: ...)`. Mark ANALYZE `completed`.

## Step 2 — LOAD CONTEXT
Read `~/.claude/commands/v-work/steps/02-load-context.md`, then execute. Mark LOAD CONTEXT `completed`.

## Step 3 — PROPOSE (panel loop)
Read `~/.claude/commands/v-team/steps/03-propose-loop.md`, then execute. The design panel converges
first, then sub-phase **(f2)** fans out the generative test-design group (`personas/_shared/testing/
design/`) to author the Test Design Dossier + Proposed test backlog (test design is split out of solution
design). Mark PROPOSE `completed`.

## Step 4 — APPROVAL GATE
**STOP. Present the converged plan + critique trail + proposed-test backlog. Do not proceed until the
user explicitly approves.** Surface any `CONVERGENCE: capped with N open blockers` and any unresolved
trade-offs the synthesizer escalated. Approval covers the whole lifecycle **through capture** (Step 6).

- Approval ("looks good", "go", "yes", "approved") → Step 5
- Feedback → revise the plan (re-loop if needed), present again
- Rejection ("no", "cancel") → end; mark remaining tasks `deleted`

## Step 5 — EXECUTE (review loop)
Read `~/.claude/commands/v-team/steps/04-execute-loop.md`, then execute. Mark EXECUTE `completed`.

## Step 6 — COMMIT + CAPTURE
Read `~/.claude/commands/v-work/steps/05-commit-capture.md`, then execute.
**v-team addendum:** also stage/commit the `plans/<...>.md` artifact (converged plan + critique trail).
Mark COMMIT + CAPTURE `completed` — only after `/v-capture` has run.

---

## Notes

- **Depends on `/v-work`.** Steps 01/02/05 resolve at `~/.claude/commands/v-work/steps/...`; if that
  path is missing, fall back to `$VAULT_FRAMEWORK_PATH/commands/v-work/steps/...`. If neither exists,
  re-run `install.sh`.
- Critics are **read-only** and **tool-grounded**: a finding blocks convergence only when a concrete
  check confirms it; unconfirmed observations are `advisory` (recorded, never blocking).
- The loop **never stops on unanimous approval alone** — only on the round cap or no-new-blocking-
  findings (false-convergence guard). Caps are hard; a cap hit with open blockers escalates to the user.
- Never write source code in Step 2. Vault-first means no premature source reads.
- The v0 draft runs both PROPOSE front gates (§3a.0a **clarify** + §3a.0b **online research**) **before**
  the panel spawns — resolve direction and ground the approach first, so critics review a well-understood,
  research-backed plan. An unresearched design or an unsound assumption is a legitimate critic finding.
- If no persona pack resolves, `/v-team` degrades gracefully to `/v-work`-with-a-panel (see
  `personas/_resolution.md` §1, fallback item 4) — warn once, never halt.
- **Feature mode** (`/v-team <feature>`): Step 0 connects the session to a `/v-pm` feature workspace
  (`_features/<feature>/`) — auto-pickup of threads addressed to this project + a deterministic
  contracts-drift check. See `v-team/steps/00-feature-pickup.md` and `vault-guide.md` §13.
