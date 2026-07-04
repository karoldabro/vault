---
description: Vault-aware development lifecycle. Loads context → proposes solution + vault writes (with dedupe) → approval → execute → commit + capture.
---

# /v-work — Vault-aware development lifecycle

Vault-first mirror of `/dev`: every step considers what knowledge to load and what to write back.
Thin dispatcher — each step is loaded on demand so only the current step's instructions sit in
context (keeps the run lean; the whole body never loads at once).

---

## Tools — preferred, force when present (never gating)

OpenViking, claude-mem, Serena, MorphLLM Fast Apply, and graphify are the token-saving backbone.

Present → use it (don't hand-roll grep/full-file reads/`sed` in its place); genuinely down →
health-check to confirm, warn once, fall back, **never halt the lifecycle**. Canonical health-check +
fallback table and full rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md` (default `~/workspace/vault/`).

**Per-project hooks + tools.** A repo's `VAULT.md` can attach `hooks` (per-phase instructions, e.g.
"fetch the Jira ticket on start") and `tools` (task-tracker MCP guidance), read once at step 1 and
carried through the run. Contract + phases: `$VAULT_FRAMEWORK_PATH/vault-guide.md` §1.1.

---

## On start: create task list

Use `TaskCreate` to add one task per step (below). Mark `in_progress` when starting, `completed` when
done — the list is the enforcement mechanism, do not skip a step. COMMIT + CAPTURE is `completed` only
after `/v-capture` has run.

1. ANALYZE
2. LOAD CONTEXT
3. PROPOSE
4. APPROVAL GATE
5. EXECUTE
6. COMMIT + CAPTURE

---

## Step 1 — ANALYZE
Read `~/.claude/commands/v-work/steps/01-analyze.md`, then execute. Mark ANALYZE `completed`.

**Fast path (auto-detected).** If the §1.4c size check says **small**, don't make the user pre-classify:
announce `Size: small → fast path`, mark the remaining lifecycle tasks `deleted`, Read
`~/.claude/commands/v-do.md` and continue as `/v-do` (orient-lite → execute → self-review; capture
offered, off by default; no approval gate). The user can say **"full lifecycle"** to override — then
continue with Step 2 as normal. Any doubt about size → no fast path.

## Step 2 — LOAD CONTEXT
Read `~/.claude/commands/v-work/steps/02-load-context.md`, then execute. Mark LOAD CONTEXT `completed`.

## Step 3 — PROPOSE
Read `~/.claude/commands/v-work/steps/03-propose.md`, then execute. Mark PROPOSE `completed`.

## Step 4 — APPROVAL GATE
**STOP. Present the proposal. Do not proceed until the user explicitly approves.** Approval covers the
whole lifecycle **through capture** (Step 6, including `/v-capture`) — don't re-ask to commit or
capture later.

- Approval ("looks good", "go", "yes", "approved") → Step 5
- Feedback → revise the proposal, present again
- Rejection ("no", "cancel") → end; mark remaining tasks `deleted`

## Step 5 — EXECUTE
Read `~/.claude/commands/v-work/steps/04-execute.md`, then execute. Mark EXECUTE `completed`.

## Step 6 — COMMIT + CAPTURE
Read `~/.claude/commands/v-work/steps/05-commit-capture.md`, then execute. Mark COMMIT + CAPTURE
`completed` — only after `/v-capture` has run.

---

## Notes

- Never write source code in Step 2. Vault-first means no premature source reads.
- PROPOSE opens with two front gates (§3a.0a/§3a.0b): **clarify** the task (surface assumptions, ask
  plan-changing questions via `AskUserQuestion`) and **research it online** (ground the approach against
  how the wild solves it — reconcile any contradicting consensus). Don't jump straight to a plan.
- If dedupe returns conflicting results (OV finds doc X, claude-mem finds doc Y), read both — the
  vault may hold parallel docs that need merging. Flag it to the user.
- If `$VAULT_FRAMEWORK_PATH/vault-guide.md` can't be found, the framework install path is wrong —
  check `~/vault/_global/config.md` (`framework_path`) or re-run `setup.sh`. If the resolved vault
  dir is missing, the repo isn't wired: run `/v-init` (old submodule vault: `bin/vault-migrate.sh`).
