---
description: Read-only feature planning across one or many repos. Refuses without operator success criteria; reads vault and code, researches, runs a parallel planning-reviewer panel, and writes a normalized plan split into sessions, each with a brief and a ready-to-paste /v-team or /v-work run line.
argument-hint: [business necessity] | reconcile <feature> | status
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Spawning an agent:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` first — it binds every agent spawned here (read the whole source before summarizing it, lead the report with what is unresolved, write artifacts before reporting them, every count carries its command).

# /v-pm — read-only feature planning across one or many repos

`/v-pm` plans; it never implements. It understands the need, gets the operator's success criteria,
reads the vault and the code of every repo in scope, researches how others solved the same problem,
and drafts an architecture plan. A parallel panel of planning reviewers critiques the draft until it
converges (`personas/_shared/planning/`). The output is one normalized plan, split into sessions:
each row names the repo it runs in, its command and what it waits for, and each session has a brief
with one paste-ready run line. `/v-team` and `/v-work` then run the sessions.

**`/v-pm` writes no code.** It reads source and runs read-only commands; it writes vault files only.

**`/v-pm` holds no opinion of its own.** Every decision names its evidence — a repo path, a vault
path, a source — and every option it rejects names why.

**When to use.** Any feature whose wrong design would be expensive to reverse, or whose work does not
fit one session — in one repo or several. The plan is proportional to the work: the scale tier from
intake caps the reviewers and rounds, and a small feature gets a small plan. For a change that fits
one session and needs no planning record, run `/v-work` or `/v-team` directly.

Thin dispatcher — each step is loaded on demand.

---

## Modes

| Invocation | Mode | What it does |
|------------|------|--------------|
| `/v-pm <need>` | **plan** (default) | Intake → load context → plan panel → approval gate → seed → capture. |
| `/v-pm reconcile <feature>` | **reconcile** | Fold execution learning into the plan, drain `to: pm` threads, convert a legacy workspace. |
| `/v-pm status` | **status** | One cross-feature inbox: runnable sessions, open threads, plan defects, staleness. |

---

## Tools — preferred, force when present (never gating)

| Tool | Health check | Fallback if down |
|------|-------------|------------------|
| Serena | `check_onboarding_performed()` | Glob/Grep |
| WebSearch | a one-term query | say research was unavailable; mark the affected decisions advisory |

Search precedence: vault → code → web. Full rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md`. Web
research runs by default in `/v-pm`; `--no-research` opts out.

---

## plan mode — on start, create the task list
`TaskCreate` one task per step; mark `in_progress` / `completed` as you go.

1. INTAKE
2. LOAD CONTEXT
3. PLAN PANEL
4. APPROVAL GATE
5. SEED WORKSPACE
6. CAPTURE

### Step 1 — INTAKE
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/01-intake.md`, then execute. It refuses to go on
without at least one operator success criterion, resolves the repos and their paths, and sets the
scale tier and the plan home.

### Step 2 — LOAD CONTEXT
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/02-load-context.md`, then execute: every participant's
vault, then a read-only code orientation that produces the code index the reviewers receive.

### Step 3 — PLAN PANEL
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/03-plan-panel.md`, then execute: research, the draft
plan and briefs, the parallel review loop, and `bin/pm-plan.sh check`.

### Step 4 — APPROVAL GATE
Run `$VAULT_FRAMEWORK_PATH/bin/pm-plan.sh check <plan>` and `$VAULT_FRAMEWORK_PATH/bin/gate.sh master <plan>`.
Exit 1 from either means the plan is not normalized: fix it, then present. Exit 2 means a file could
not be read: stop and say so.

**STOP. Present the decision and wait for explicit approval.** Approving the plan authorizes every
session it creates. Present, within 15 lines and per `communication.md` "Presenting a decision":
the recommendation; the impact (repos, session count, waves); the operator's success criteria and the
sessions that reach each; the decisions that are the operator's own call, each with its consequence;
the stated defaults; and anything still open. Always say in plain words when the reviewers ran out of
rounds with items open, and name any minority finding the plan did not apply. Name the plan path.

- Approval → Step 5 · Feedback → revise the plan, re-run the check, present again · Rejection → end.

### Step 5 — SEED WORKSPACE (multi-repo only)
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/04-seed-workspace.md`, then execute.

### Step 6 — CAPTURE
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/05-capture.md`, then execute. It commits the plan and
prints the run lines of the first wave. Then stop.

## reconcile mode
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/06-reconcile.md`, then execute.

## status mode
Read `$VAULT_FRAMEWORK_PATH/commands/v-pm/steps/07-status.md`, then execute.

---

## Notes
- **Running a session.** Paste the brief's run line into a shell, or run `/v-team <feature> [S<n>]` or
  `/v-work <feature> [S<n>]` in the repo. Both read `commands/_shared/feature-pickup.md` as Step 0,
  which refuses a session whose dependencies are not `done`, marks the row `doing`, and loads the brief.
  The close marks the row `done` with its commit.
- **The tracker is the plan's `## Sessions` table.** An executing session may correct its own row's
  scope and deviation and may append a row with its brief; `bin/pm-plan.sh check` accepts the result.
- **`_features/` is its own committed vault**, neutral ground for multi-repo plans
  (`vault-guide.md` §1.1 and §13). A single-repo plan lives in that project's own vault.
- **The reviewers are reusable.** Any command seats a planning lens by its id through a pack's
  `use_shared` or `VAULT.md` `personas.add` (`personas/_shared/planning/README.md`).
- Latency is honest: a thread reply surfaces at the next open of the asking repo's session, or in
  `/v-pm status`. There is no live agent-to-agent channel.
