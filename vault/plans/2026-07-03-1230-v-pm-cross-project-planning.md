---
type: plan
project: vault
slug: v-pm-cross-project-planning
status: executed   # proposed | approved | executed | superseded
process_record: 2026-07-03-1230-v-pm-cross-project-planning.trail.md
tags: [plan, team, v-pm, cross-project, planning]
---

# v-pm — cross-project feature planning & agent coordination

## Task
Build `v-pm` — a planning command (business→product→architect→contract panel) that emits a
project-agnostic feature plan into a shared `~/vault/_features/<feature>/` workspace, plus a file-based
**conversation** protocol so per-project `/v-team <feature>` sessions coordinate async (auto-pickup)
instead of the human relaying context between them.
Keywords: `v-pm`, `_features`, `conversation`, `auto-pickup`, `contracts`, `cross-project`.

## Open & deferred
- **⚠️ ESCALATION — `_features/` git ownership (needs user decision).** It holds the durable
  source-of-truth (`generic-plan.md`, `contracts.md`) but sits parallel to the never-committed `_global/`,
  so no repo versions or syncs it. Options: **(a)** its own committed vault wired into `v-sync`;
  **(b)** hosted under the coupled-group's lead-project vault. Must be decided before EXECUTE.
- **Deferred to follow-up**: the broad LLM consistency-pass (kept only the deterministic contracts diff);
  the Spec-Kit per-group `constitution`; archival of shipped features → `_features/_done/<feature>/`.
- **Blackboard staleness/latency** (honest contract, not a bug): a reply surfaces only at the next open of
  the asking project; `v-pm status` + the staleness flag are the mitigations, documented in vault-guide.
- **Shared working tree**: EXECUTE commits direct-to-`main` with explicit staging, no branch switch
  (parallel-session safety convention, per `253209e` capture).

## Decisions
| decision | reason | record |
|----------|--------|--------|
| `contracts.md` is a separate, structured file, not merged into `generic-plan.md` | A parseable contracts file is what makes the drift check deterministic | local |
| The ledger is derived from thread filenames on read, never written to disk | A shared `ledger.md` races between parallel sessions | local |
| Auto-pickup is pull-only; `v-pm status` is the push-side surface | No session can push into another; the latency is stated instead of hidden | local |

## Context
- **Precedent**: BMAD-METHOD (planning agents + self-contained shards), Spec-Kit (spec→plan→tasks +
  `/analyze` consistency), blackboard architecture + file-A2A (shared workspace, state-in-filename).
- **Decisions**: planner-first v-pm + thin `reconcile`; auto-pickup routing; `~/vault/_features/<feature>/`;
  4 planning critics; v-team-style dispatcher/steps/rounds; soft AI-decided research; clarify hard-block
  (shipped `3124a7d`); thread protocol = filename-state + `to:` header.
- **Already shipped** (`253209e` + `3124a7d`): the clarify + research front gates v-pm inherits via §3a.

## Work items
Dependency-ordered. File · Action · Pattern.

1. `commands/v-pm.md` — **create**. Thin dispatcher (mirrors `v-team.md`). Modes: `plan` (default),
   `reconcile <feature>`, **`status`** (cross-feature inbox sweep). Opens with a **"when to
   use"** line — reach for v-pm only when a feature spans **2+ repos worked in separate
   sessions**; else use `/v-team`. Task list; advertises inherited front gates + the planning pipeline +
   workspace seed. README-landing-page rule → detail in steps.
2. `commands/v-pm/steps/01-intake.md` — **create**. Capture business necessity; restate; **clarify gate
   (hard-block)**; resolve participants (`_global/coupled-groups.md`, else ask). **Break-even gate:
   if participants == 1, skip the workspace and hand off to plain `/v-team`** — no ceremony.
   Name + slug the feature.
3. `commands/v-pm/steps/02-plan-panel.md` — **create**. **Its own sequential pipeline**
   `business → product → architect → contract` (each stage consumes the prior stage's
   output), borrowing **only** the finding schema + de-biased synthesize sub-steps from
   `v-team/steps/03-propose-loop.md` — **not** `_shared/critic-panel.md` (that module is diff-review
   only: no diff, no analyzers to ground on). Rounds capped by `pm_max_rounds` (default 2); soft research
   (`--research`/`--no-research`). Emits `generic-plan.md` + **structured** `contracts.md`.
4. `commands/v-pm/steps/03-seed-workspace.md` — **create**. Scaffold `~/vault/_features/<feature>/`
   (`header.md`, `generic-plan.md`, `contracts.md`, `conversation/`, `projects/`). **No `ledger.md`
   file — the ledger is a *derived view* computed from thread filenames on read** (kills the
   write-race). Symlink `~/vault/<project>/features/<feature>` → workspace per participant;
   the symlink is **gitignored** in participant repos.
5. `commands/v-pm/steps/04-reconcile.md` — **create**. `reconcile` mode: drain threads `to: pm`, fold
   execution learnings into `generic-plan.md`/`contracts.md`. **Staleness flag**: surface
   any OPEN thread older than N session-opens as "waiting on <proj>, not picked up."
6. `commands/v-pm/steps/05-status.md` — **create**.
   `status` mode: sweep every `_features/*/conversation/` for OPEN threads (by target + `→ pm`) and
   ANSWERED-but-unseen replies; emit ONE cross-feature inbox digest with staleness age. This is the one
   thing the human runs to actually get out of the message-bus loop (auto-pickup alone is pull-only).
7. `commands/v-team/steps/00-feature-pickup.md` — **create** + `v-team.md` dispatcher **edit**.
   A `<feature>`-gated pre-step, fired **only** when `/v-team` gets a feature arg (derive
   the feature from the project's `features/` **symlink** if present; if a slug is given and matches
   nothing, **warn loudly**): auto-pickup (answer/act threads `→ this project`, rename file
   state, surface ANSWERED replies) + a **deterministic contracts-drift check** (parse
   structured `contracts.md`, diff vs the project's consumed contract; LLM only for prose rationale and
   must cite the drifted line). **Leave `v-work/steps/02-load-context.md` untouched.** The broad LLM
   consistency-pass is **deferred** (false-confidence).
8. `templates/_features/` — **create**. `header.md`, `generic-plan.md`,
   `contracts.md` (structured enums/shapes), `project-shard.md` (BMAD self-contained: rationale ·
   constraints · tests · up-links), `THREAD.md` (frontmatter `from`/`to`/`asks`; filename encodes state
   `OPEN_→<proj>` / `ANSWERED_<proj>` / `RESOLVED`). Add the feature-symlink line to the participant-repo
   gitignore template.
9. `vault-guide.md` — **edit**. Document the `_features` workspace, thread protocol, the **derived-ledger**
   rule, the auto-pickup + **deterministic contracts-drift** contract, and the **latency contract**
   (a reply surfaces only at the next open of the asking project — stated honestly), plus `_features/`
   git ownership (see escalation).
10. `commands/README.md` + `README.md` — **edit**. One-line `v-pm` entry (landing-page rule).
11. `tests/unit/v-pm.bats` — **create**. File-contract tests (see Test plan). `install.sh`
    auto-discovers commands by glob, so the test asserts the installer links `v-pm` after a run.

## Test plan
Dockerized bats file-contract tests (agent-loop behavior validated by manual dry-run), mirroring
`v-team.bats` / `research-clarify.bats`:
- dispatcher exists, has `plan` + `reconcile` modes, references all 4 step files;
- each step file exists; planning panel names the 4 critics + `pm_max_rounds`;
- workspace seed lists the 6 workspace entries; templates exist;
- thread protocol: filename states + `to:`/`from:` frontmatter documented;
- v-team auto-pickup + consistency-pass wired (grep the edited v-team steps);
- `install.sh` symlinks v-pm; README carries a one-line entry (landing-page rule).

## Refs
- Process record: `vault/plans/2026-07-03-1230-v-pm-cross-project-planning.trail.md` — the findings,
  dispositions and rejected approaches behind this plan.
- `commands/v-team/steps/03-propose-loop.md` — the finding schema and synthesize sub-steps item 3 borrows.
- `commands/_shared/critic-panel.md` — diff-review only; item 3 must not be wired into it.
