---
type: plan
project: vault
slug: v-pm-cross-project-planning
status: proposed   # proposed | approved | executed | superseded
personas: [fallback-shared]
rounds: 1
convergence: clean   # clean | capped-with-open-blockers — 1 escalation to user (_features git owner)
tags: [plan, team, v-pm, cross-project, planning]
---

# v-pm — cross-project feature planning & agent coordination

Written by `/v-team`. Converged implementation plan + critique trail + proposed-test backlog.
Design rationale + research trail: `scratchpad/v-pm-design.md` (this session).

## Task
Build `v-pm` — a planning command (business→product→architect→contract panel) that emits a
project-agnostic feature plan into a shared `~/vault/_features/<feature>/` workspace, plus a file-based
**conversation** protocol so per-project `/v-team <feature>` sessions coordinate async (auto-pickup)
instead of the human relaying context between them.
Keywords: `v-pm`, `_features`, `conversation`, `auto-pickup`, `contracts`, `cross-project`.

## Context (already decided — see design doc)
- **Precedent**: BMAD-METHOD (planning agents + self-contained shards), Spec-Kit (spec→plan→tasks +
  `/analyze` consistency), blackboard architecture + file-A2A (shared workspace, state-in-filename).
- **Decisions**: planner-first v-pm + thin `reconcile`; auto-pickup routing; `~/vault/_features/<feature>/`;
  4 planning critics; v-team-style dispatcher/steps/rounds; soft AI-decided research; clarify hard-block
  (shipped `3124a7d`); thread protocol = filename-state + `to:` header.
- **Already shipped** (`253209e` + `3124a7d`): the clarify + research front gates v-pm inherits via §3a.

## Converged plan (v1 — post Round 1)
Dependency-ordered. File · Action · Pattern. Changes from draft are marked `[R1: …]`.

1. `commands/v-pm.md` — **create**. Thin dispatcher (mirrors `v-team.md`). Modes: `plan` (default),
   `reconcile <feature>`, **`status`** `[R1: new — cross-feature inbox sweep]`. Opens with a **"when to
   use"** line `[R1: dx-3]` — reach for v-pm only when a feature spans **2+ repos worked in separate
   sessions**; else use `/v-team`. Task list; advertises inherited front gates + the planning pipeline +
   workspace seed. README-landing-page rule → detail in steps.
2. `commands/v-pm/steps/01-intake.md` — **create**. Capture business necessity; restate; **clarify gate
   (hard-block)**; resolve participants (`_global/coupled-groups.md`, else ask). **Break-even gate
   `[R1: skeptic-6/dx-3]`: if participants == 1, skip the workspace and hand off to plain `/v-team`** —
   no ceremony. Name + slug the feature.
3. `commands/v-pm/steps/02-plan-panel.md` — **create**. **Its own sequential pipeline** `[R1:
   architect-1/2]` `business → product → architect → contract` (each stage consumes the prior stage's
   output), borrowing **only** the finding schema + de-biased synthesize sub-steps from
   `v-team/steps/03-propose-loop.md` — **not** `_shared/critic-panel.md` (that module is diff-review
   only: no diff, no analyzers to ground on). Rounds capped by `pm_max_rounds` (default 2); soft research
   (`--research`/`--no-research`). Emits `generic-plan.md` + **structured** `contracts.md`.
4. `commands/v-pm/steps/03-seed-workspace.md` — **create**. Scaffold `~/vault/_features/<feature>/`
   (`header.md`, `generic-plan.md`, `contracts.md`, `conversation/`, `projects/`). **No `ledger.md`
   file `[R1: skeptic-5/dx-1]` — the ledger is a *derived view* computed from thread filenames on read**
   (kills the write-race). Symlink `~/vault/<project>/features/<feature>` → workspace per participant;
   the symlink is **gitignored** in participant repos `[R1: architect-5]`.
5. `commands/v-pm/steps/04-reconcile.md` — **create**. `reconcile` mode: drain threads `to: pm`, fold
   execution learnings into `generic-plan.md`/`contracts.md`. **Staleness flag `[R1: dx-4]`**: surface
   any OPEN thread older than N session-opens as "waiting on <proj>, not picked up."
6. `commands/v-pm/steps/05-status.md` — **create** `[R1: skeptic-1/dx-2 — the push-side surface]`.
   `status` mode: sweep every `_features/*/conversation/` for OPEN threads (by target + `→ pm`) and
   ANSWERED-but-unseen replies; emit ONE cross-feature inbox digest with staleness age. This is the one
   thing the human runs to actually get out of the message-bus loop (auto-pickup alone is pull-only).
7. `commands/v-team/steps/00-feature-pickup.md` — **create** + `v-team.md` dispatcher **edit** `[R1:
   architect-3]`. A `<feature>`-gated pre-step, fired **only** when `/v-team` gets a feature arg (derive
   the feature from the project's `features/` **symlink** if present; if a slug is given and matches
   nothing, **warn loudly** `[R1: dx-5]`): auto-pickup (answer/act threads `→ this project`, rename file
   state, surface ANSWERED replies) + a **deterministic contracts-drift check** `[R1: skeptic-4]` (parse
   structured `contracts.md`, diff vs the project's consumed contract; LLM only for prose rationale and
   must cite the drifted line). **Leave `v-work/steps/02-load-context.md` untouched.** The broad LLM
   consistency-pass is **deferred** (false-confidence).
8. `templates/_features/` — **create** `[R1: architect-6]`. `header.md`, `generic-plan.md`,
   `contracts.md` (structured enums/shapes), `project-shard.md` (BMAD self-contained: rationale ·
   constraints · tests · up-links), `THREAD.md` (frontmatter `from`/`to`/`asks`; filename encodes state
   `OPEN_→<proj>` / `ANSWERED_<proj>` / `RESOLVED`). Add the feature-symlink line to the participant-repo
   gitignore template.
9. `vault-guide.md` — **edit**. Document the `_features` workspace, thread protocol, the **derived-ledger**
   rule, the auto-pickup + **deterministic contracts-drift** contract, and the **latency contract**
   (a reply surfaces only at the next open of the asking project — stated honestly), plus `_features/`
   git ownership (see escalation).
10. `commands/README.md` + `README.md` — **edit**. One-line `v-pm` entry (landing-page rule).
11. `tests/unit/v-pm.bats` — **create**. File-contract tests (see Test plan). `[R1: architect-4 —
    dropped the old "edit install.sh" step; install.sh auto-discovers via glob. Test instead asserts the
    installer links v-pm after a run.]`

## Test plan
Dockerized bats file-contract tests (agent-loop behavior validated by manual dry-run), mirroring
`v-team.bats` / `research-clarify.bats`:
- dispatcher exists, has `plan` + `reconcile` modes, references all 4 step files;
- each step file exists; planning panel names the 4 critics + `pm_max_rounds`;
- workspace seed lists the 6 workspace entries; templates exist;
- thread protocol: filename states + `to:`/`from:` frontmatter documented;
- v-team auto-pickup + consistency-pass wired (grep the edited v-team steps);
- `install.sh` symlinks v-pm; README carries a one-line entry (landing-page rule).

## Open trade-offs / deferrals
- **⚠️ ESCALATION — `_features/` git ownership (architect-5, needs user decision).** It holds the durable
  source-of-truth (`generic-plan.md`, `contracts.md`) but sits parallel to the never-committed `_global/`,
  so no repo versions or OV-syncs it. Options: **(a)** its own committed vault wired into `v-sync`;
  **(b)** hosted under the coupled-group's lead-project vault. Must be decided before EXECUTE.
- **Resolved conflict — contracts.md separate+structured (skeptic-4) vs merged-for-fewer-concepts (dx-1).**
  Chose **structured-separate**: the api↔frontend seam is the user's actual pain, and a separate parseable
  `contracts.md` is what enables the *deterministic* drift check (the payoff). Concept-load is cut instead
  by deriving the ledger and deferring the LLM consistency-pass.
- **Deferred to follow-up**: the broad LLM consistency-pass (kept only the deterministic contracts diff);
  the Spec-Kit per-group `constitution`; archival of shipped features → `_features/_done/<feature>/`.
- **Blackboard staleness/latency** (honest contract, not a bug): a reply surfaces only at the next open of
  the asking project; `v-pm status` + the staleness flag are the mitigations, documented in vault-guide.
- **Shared working tree**: EXECUTE commits direct-to-`main` with explicit staging, no branch switch
  (parallel-session safety convention, per `253209e` capture).

## Critique trail

### Round 0 — draft
The plan above (steps 1–11), derived from the converged design doc. Enters the panel for Round 1.

### Round 1 — findings + dispositions
Panel (fallback-shared): architect · skeptic · dx. All three returned REQUEST_CHANGES. De-biased,
clustered across personas. Metrics: 18 findings → 11 clusters; 2 confirmed BLOCKER, 9 MAJOR, 3 MINOR,
1 NIT; 1 advisory. 1 escalation to user. All confirmed findings applied.

| id | sev | grounding | issue (clustered) | disposition |
|----|-----|-----------|-------------------|-------------|
| architect-1 | BLOCKER | confirmed | planning panel can't reuse `_shared/critic-panel.md` (diff-review only) | **applied** — own pipeline on `03-propose-loop` shape (step 3) |
| architect-2 | MAJOR | confirmed | linear pipeline ≠ any existing parallel-panel module | **applied** — new control flow, reuse schema+synthesize only (step 3) |
| skeptic-1 | BLOCKER | confirmed | auto-pickup pull-only → orphaned threads; human not out of loop | **applied** — new `v-pm status` sweep (step 6) |
| skeptic-2 | MAJOR | confirmed | `→pm` threads only drain on manual reconcile | **applied** — status sweep covers `→pm` + reconcile auto-prompt (steps 5–6) |
| skeptic-3 | MAJOR | confirmed | "notify originating thread" is fiction; no latency bound | **applied** — drop "notify", document latency contract + ANSWERED digest (steps 7,9) |
| skeptic-4 | MAJOR | confirmed | LLM prose consistency-pass = false-confidence | **applied** — deterministic contracts diff; defer LLM pass (step 7) |
| skeptic-5 | MAJOR | confirmed | `ledger.md` shared-append race | **applied** — derive ledger from filenames on read (step 4) |
| skeptic-6 | MINOR | advisory | no break-even; single-project = ceremony | **applied** — break-even gate (step 2) |
| architect-3 | MAJOR | confirmed | edits non-existent `v-team/steps/02`; leaks into `/v-work` | **applied** — new `00-feature-pickup.md`, v-work/02 untouched (step 7) |
| architect-4 | MAJOR | confirmed | install.sh is glob-based; hand-edit is dead work | **applied** — dropped edit; test asserts installer links v-pm (step 11) |
| architect-5 | MAJOR | confirmed | `_features/` has no git owner / dangling symlinks | **escalated to user** + gitignore symlinks (Open trade-offs) |
| architect-6 | MINOR | confirmed | missing templates for the load-bearing artifacts | **applied** — templates/_features incl. project-shard (step 8) |
| dx-1 | MAJOR | confirmed | ~10 new concepts for a solo dev | **partially applied** — derive ledger, defer consistency-pass; kept contracts separate (see resolved conflict) |
| dx-2 | MAJOR | confirmed | no push/notification surface for waiting threads | **applied** — `v-pm status` + SessionStart surfacing (steps 6,9) |
| dx-3 | MAJOR | confirmed | no "when to use v-pm"; no single-project degrade | **applied** — dispatcher line + break-even gate (steps 1–2) |
| dx-4 | MAJOR | confirmed | OPEN→proj thread can stall silently forever | **applied** — staleness flag (step 5) |
| dx-5 | MINOR | confirmed | mistyped slug silently misses all threads | **applied** — derive from symlink, warn on mismatch (step 7) |
| dx-6 | NIT | confirmed | landing-page rule already respected | **no change** (compliant) |

**Convergence:** bringing the revised plan to the approval gate rather than a Round 2 — all confirmed
findings are applied architectural corrections (not iterative refinement), and the one remaining item
(`_features/` git ownership) is a **user decision**, not a panel call. No new confirmed blockers would be
expected from re-running the panel on applied corrections.
