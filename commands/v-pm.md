---
description: Cross-project feature planning. A business→product→architect→contract critic pipeline drafts a project-agnostic feature plan into a shared _features/ workspace; per-project /v-team sessions then read it and coordinate async via a file-based conversation instead of the human relaying context between agents.
argument-hint: [business necessity] | reconcile <feature> | status
---

# /v-pm — cross-project feature planning & coordination

The planning brain that sits **above** execution. You describe a business necessity once; a panel of
critics (business advisor · product owner · architect · contract) turns it into a **project-agnostic
plan** in a shared `_features/<feature>/` workspace. Each project's `/v-team <feature>` session then
reads that plan, writes its own detail, and — when it hits a cross-project doubt — parks it as a
**thread** in the feature's `conversation/` for the other project (or the PM) to pick up. No more
copy-pasting context between agent sessions; the workspace is the message bus.

**When to use.** Reach for `/v-pm` to **capture a feature's business logic once, richly** — the
requirements knowledge center (rules, acceptance, glossary) that grounds rich tests + AI product
understanding — for **any** feature, single- or multi-repo. Two tiers, split by `01-intake`:
- **1 repo** → author `requirements.md` into the project's own `requirements/` vault category, then hand
  execution to `/v-team`/`/v-work`. The `_features/` workspace + conversation machinery is skipped (pure
  overhead below 2 repos) — but the knowledge center is **not**.
- **2+ repos worked in separate sessions** (the api↔frontend seam) → the full run: requirements.md +
  `generic-plan.md` + `contracts.md` in the shared `_features/` workspace + the file-based conversation.

For a throwaway one-sitting change with no business logic worth keeping, use `/v-work`/`/v-team` directly.

Thin dispatcher — each step is loaded on demand, like `/v-team`. Execution is **not** v-pm's job: after
planning you run `/v-team <feature>` (or `/v-work`) in each project. v-pm inherits the PROPOSE front
gates (§3a.0a clarify + §3a.0b research) from `/v-work` via the planning pipeline.

---

## Modes

| Invocation | Mode | What it does |
|------------|------|--------------|
| `/v-pm <business necessity>` | **plan** (default) | Intake → planning panel → author the `requirements.md` knowledge center; **2+ repos** also seed the `_features/` workspace, **1 repo** writes into the project's `requirements/` then hands off. |
| `/v-pm reconcile <feature>` | **reconcile** | Drain `to: pm` threads, fold execution learnings back into the generic plan + contracts, flag stale threads. |
| `/v-pm status` | **status** | Sweep every `_features/*/conversation/` and print one cross-feature inbox: open threads by target project, `to: pm` decisions, and answered-but-unseen replies, with staleness age. |

`status` is the **push-side surface** — the one command you run to see everything waiting across all
features, so a thread never orphans just because you didn't reopen the right session.

---

## Tools — preferred, force when present (never gating)
The token-saving backbone from `/v-team`, plus the **Agent** tool for the planning panel. LOAD CONTEXT
(Step 2) probes these and falls back to the next layer; it never halts.

| Tool | Health check | Fallback if down |
|------|-------------|------------------|
| OpenViking | `memory_health()` (MCP plugin — never `curl`) | `Grep` over `~/vault/` |
| claude-mem | `search("test", limit=1)` via mcp-search | skip; note it |
| graphify | `<repo>/graphify-out/graph.json` present | grep the repo |
| Serena | `check_onboarding_performed()` | graphify → Glob/Grep |

Search precedence (`CLAUDE.md`): vault + OV → graph → source. Full rules:
`$VAULT_FRAMEWORK_PATH/tool-playbook.md`. Web research (soft — the AI decides, or force with `--research`
/ disable with `--no-research`) per `tool-playbook.md` §7.

---

## plan mode — on start, create the task list
`TaskCreate` one task per step; mark `in_progress` / `completed` as you go.

1. INTAKE
2. LOAD CONTEXT
3. PLAN PANEL
4. SEED WORKSPACE
5. CAPTURE

### Step 1 — INTAKE
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/01-intake.md`, then execute. The clarify gate
hard-blocks on a no-safe-default fork. The break-even gate (§1.3) splits on the **coordination
machinery**, not the knowledge center: a **single-participant** feature still authors `requirements.md`
into the project's own `requirements/` vault, skips the `_features/` workspace, then hands execution to
`/v-team`/`/v-work`. 2+ participants → full multi-repo run.

### Step 2 — LOAD CONTEXT
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/02-load-context.md`, then execute. Vault-first, **across
every participant's vault** + `_global` + `_features/` (OV → claude-mem → graph → grep). Produces the
context digest the panel plans from — so the PM grounds in accumulated project knowledge, not blindly.

### Step 3 — PLAN PANEL
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/03-plan-panel.md`, then execute. Emits the
`requirements.md` knowledge center; multi-repo also emits `generic-plan.md` + structured `contracts.md`
(single-repo emits requirements.md only).

### Step 4 — SEED WORKSPACE  _(multi-repo only)_
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/04-seed-workspace.md`, then execute. Scaffolds
`_features/<feature>/` (requirements.md · generic-plan.md · contracts.md), seeds each shard's v-pm-owned
`## Business rules to satisfy` id list, and symlinks the workspace into each participant vault. → Step 5.
(**Single-repo** skips this — Step 1 §1.3 already wrote `requirements.md` into the project vault.)

### Step 5 — CAPTURE
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/05-capture.md`, then execute. Writes the planning-session
record + cross-project ADR candidates into the workspace, pushes the rationale to OpenViking, and commits
the whole workspace. Then STOP: tell the user the workspace is ready and to run `/v-team <feature>` in
each project.

## reconcile mode
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/06-reconcile.md`, then execute (it ends by running CAPTURE
to record the reconciliation + any new decisions).

## status mode
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/07-status.md`, then execute. (Read-only — no capture.)

---

## Notes
- **`_features/` is its own committed vault**, wired into `/v-sync` — neutral ground owned by no single
  project. Path resolution + the full protocol: `vault-guide.md` §1.1 + §13.
- v-pm **plans**, it does not execute. Only v-pm writes `requirements.md` (the knowledge center) +
  `generic-plan.md` (`plan` + `reconcile`); projects write their own `projects/<proj>/plan.md` shard and,
  at capture, their established `features/` dossier (carrying each `REQ-NN`).
- **The knowledge center is for 1+ repos; coordination is the 2+ delta.** A single-repo feature still
  authors `requirements.md` (into the project's `requirements/` vault), then hands **execution** to
  `/v-team`/`/v-work` — it is not handed off empty-handed.
- **Latency is honest, not hidden**: a thread reply surfaces only at the next open of the asking
  project's session (or via `/v-pm status`). There is no live agent-to-agent channel by design.
- Degrades gracefully: no coupled group + no participants given → ask; a single-project feature authors
  its requirements.md then hands execution to `/v-team`. Never halts.
