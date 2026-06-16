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

Use `/v-work` for routine work. `/v-team` spends more (up to ~3 critics × 2 rounds × 2 loops) to buy
design + review rigor — reach for it on architecture, schema, auth, billing, or cross-repo contracts.

---

## Tools — preferred, force when present (never gating)

Identical to `/v-work` — OpenViking, claude-mem, Serena, MorphLLM, graphify are the token-saving
backbone. Plus the **Agent** tool for the critic panel (parallel spawn).

| Tool | Health check | Fallback if down |
|------|-------------|------------------|
| OpenViking | `memory_health()` (MCP plugin — never `curl`) | `Grep` over `~/vault/` |
| claude-mem | `search("test", limit=1)` via mcp-search | skip; note it |
| Serena | `check_onboarding_performed()` | graphify → Glob/Grep/LSP |
| MorphLLM | (MCP — no runtime check) | `Edit` / `MultiEdit` |
| graphify | `graphify-out/graph.json` present | offer `graphify hook install`, then grep |

Full rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md`. Persona resolution: `$VAULT_FRAMEWORK_PATH/personas/_resolution.md`.

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

---

## Step 1 — ANALYZE
Read `~/.claude/commands/v-work/steps/01-analyze.md`, then execute.
**v-team addendum:** also Read `$VAULT_FRAMEWORK_PATH/personas/_resolution.md`, resolve the persona
pack, and **select the critics for this change** (§2 there). Append one line to the ANALYZE output:
`Personas: <pack> → [selected names]   (skipped: ...)`. Mark ANALYZE `completed`.

## Step 2 — LOAD CONTEXT
Read `~/.claude/commands/v-work/steps/02-load-context.md`, then execute. Mark LOAD CONTEXT `completed`.

## Step 3 — PROPOSE (panel loop)
Read `~/.claude/commands/v-team/steps/03-propose-loop.md`, then execute. Mark PROPOSE `completed`.

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
- If no persona pack resolves, `/v-team` degrades gracefully to `/v-work`-with-a-panel (see
  `personas/_resolution.md` §1.4) — warn once, never halt.
