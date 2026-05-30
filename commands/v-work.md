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

- **When a tool is present, use it** — do not hand-roll grep / full-file reads / `sed` in its place.
- **When one is genuinely unavailable**, confirm via its health check, warn once, then proceed with
  the documented fallback. **Never halt the lifecycle for a missing tool.**

| Tool | Health check | Fallback if down |
|------|-------------|------------------|
| OpenViking | `memory_health()` (MCP plugin — never `curl`) | `Grep` over `~/vault/` |
| claude-mem | `search("test", limit=1)` via mcp-search | skip; note it |
| Serena | `check_onboarding_performed()` | graphify → Glob/Grep/LSP |
| MorphLLM | (MCP — no runtime check) | `Edit` / `MultiEdit` |
| graphify | `graphify-out/graph.json` present | offer `graphify hook install`, then grep |

Full rules + worked examples: `_process/tool-playbook.md`.

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
- If dedupe returns conflicting results (OV finds doc X, claude-mem finds doc Y), read both — the
  vault may hold parallel docs that need merging. Flag it to the user.
- If `_process/vault-guide.md` is missing, the framework folder isn't wired. Re-run `/v-init` or
  check the `_process/` link in the project vault.
