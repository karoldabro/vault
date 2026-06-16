---
type: session
project: vault
date: 2026-06-16
topic: v-team-persona-critique-command
files_touched: [commands/v-team.md, commands/v-team/steps/03-propose-loop.md, commands/v-team/steps/04-execute-loop.md, personas/, templates/plan.md, templates/VAULT.md, vault-guide.md, commands/README.md, _moc.md, tests/unit/v-team.bats]
decisions: []
tags: [session, v-team, personas, multi-agent]
---

# v-team-persona-critique-command

## Goal
Design and ship `/v-team` — a persona-critique multi-agent dev lifecycle alongside `/v-work`, where
project-specific critics loop over the plan and the diff to cut human involvement.

## Did
- Explored the framework: `/v-work` is a thin dispatcher (TaskCreate + Read-on-demand steps); installed
  by symlink via `install.sh` (globs `commands/*.md` + `commands/*/`); no project-type field existed.
- Confirmed 4 design forks with the user (all recommended): standalone `/v-team`; panel→synthesize→
  re-loop (no peer messaging); framework persona packs selected via `VAULT.md`; ship api full + nuxt/
  flutter draft. Added: critics propose tests, a testing agent triages them at execution.
- Ran a deep web-research pass (~25 papers + AI-code-review postmortems). It validated the architecture
  but flagged 3 high-risk patterns — folded the fixes into the design before building.
- Built `[[commands/v-team]]` dispatcher + `03-propose-loop` / `04-execute-loop` steps (reuse v-work
  01/02/05).
- Built the persona library factored for reuse: `personas/_shared/{security,performance,quality,
  skeptic}.md` composed by per-stack packs (`api-laravel` full; `nuxt`/`flutter` draft) via
  `use_shared` + overlays + local architects. `personas/_resolution.md` = pack resolution + critic
  selection. Templates `_persona-template.md` / `_pack-template.md`.
- Added `templates/plan.md` (converged plan + critique trail + test backlog), extended `templates/
  VAULT.md` (project_type / personas / loop caps), updated `vault-guide.md` §2/§4/§11, README, `_moc.md`.
- Wrote `tests/unit/v-team.bats` (8 file-contract tests). Full dockerized unit suite: 18/18 green.
- Ran `install.sh` — `/v-team` symlinked and registered. Dogfooded `/v-init --in-repo` to create this
  vault. Committed feature (`56d3f3a`) + vault wiring (`c853e47`).

## Learned
- Personas help *focus/rubric/format*, not detection competence — and can slightly *hurt* coding
  accuracy. So each persona is **tool-grounded**: runs a bound analyzer first; a finding blocks only
  when a concrete check confirms it (`confirmed`), else `advisory`. This is the defense against the
  AI-review false-positive trust cliff (>30% FP → devs ignore the bot).
- "Loop until critics approve" is the #1 false-convergence trap (sycophancy + LLM-judge bias). Stop on
  round cap or no-new-confirmed-blockers, **never on unanimous approval alone**.
- Parallel independent critics + synthesizer beats debate; cross-talk causes groupthink. Correlated
  critics collapse to ~2 effective votes → select ~3 decorrelated lenses, not always 5.
- LLM-proposed tests over-produce (~1:5–1:20 keep ratio) and coverage passes tautological tests → triage
  with a mutation/characterization gate, not coverage alone.
- `/v-team` should NOT run inside harness plan mode: plan mode blocks the `plans/` artifact write, and
  Step 4 is already its own approval gate.

## Next
- Live dry-run of `/v-team` on `recycling-api` (Laravel) — exercise the panel, confirm auto-detect +
  critic selection picks the right lenses from keywords alone.
- Validate `nuxt`/`flutter` pack analyzer commands against the real repos; tune checklists to each
  project's `indications/`.
- Possible enhancement: make the propose loop plan-mode-aware (present inline instead of writing
  `plans/`).
- `prompts/consolidate-into-indications.md` still untracked from a prior session.

## Refs
<!-- none yet — first session in this vault -->
