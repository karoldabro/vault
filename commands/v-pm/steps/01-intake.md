# Step 1 — INTAKE (plan mode)

Capture the business necessity, make sure it's understood, and decide who's in.

## 1.1 Restate + clarify (hard-block)
Write one sentence capturing the business necessity in your own words, plus the assumptions you're
relying on. Then run the **clarify gate** exactly as `v-work/steps/03-propose.md` §3a.0a defines it:
surface open doubts about direction / scope / which products are involved; answer what you can from the
vault; for a genuine plan-fork with **no safe default**, ask via `AskUserQuestion` and **wait** — do not
proceed past an unanswered fork. This is planning-ahead; a wrong assumption here cascades across every
project, so it is the most expensive place to guess.

## 1.2 Resolve participants
Determine which repos the feature spans:
1. If the user named them, use that.
2. Else read `~/vault/_global/coupled-groups.md` — if the necessity clearly maps to a declared group
   (vivi, digitally, givore…), propose its members and confirm.
3. Else ask which projects are in scope.

## 1.3 Break-even gate — decouple the knowledge center from the coordination machinery
The **business knowledge center (`requirements.md`) is worth authoring for ANY feature** — it stops the
user repeating themselves and makes the vault richer for tests + AI. Only the **coordination machinery**
(the `_features/` workspace, `conversation/`, `contracts.md` seam, symlinks, shards) needs 2+ repos to
pay off. So the gate splits on that boundary, not on "author requirements or not":

- **2+ participants → full multi-repo run.** Proceed through SEED WORKSPACE (Step 4) as normal:
  requirements.md + generic-plan.md + contracts.md into the neutral `_features/<feature>/` workspace.
- **1 participant → single-repo run (author the knowledge center, skip the machinery).** Do **not** hand
  off empty-handed and do **not** seed a `_features/` workspace. Instead:
  1. Run **LOAD CONTEXT** (`02-load-context.md`) and **PLAN PANEL** (`03-plan-panel.md`) scoped to the one
     project — but PLAN PANEL emits **only `requirements.md`** (the knowledge center); **skip
     `contracts.md`** (no cross-project seam) and **skip `generic-plan.md`** (single-repo execution
     planning is `/v-team`'s job, not a cross-project shard).
  2. **Write it into the project's OWN vault** at `<project-vault>/requirements/<feature>.md` (from
     `templates/_features/requirements.md`). This is the project's own vault — no cross-repo write. If
     `requirements/` doesn't exist yet, create it + a `requirements/_index.md` (one-line note; no forced
     migration of existing vaults).
  3. Run **CAPTURE** (`05-capture.md`, single-repo branch) against the **project vault**: planning-session
     into `<project-vault>/sessions/`, push the glossary + rules to OV, commit the project vault (not
     `_features/`).
  4. **Hand off execution**: tell the user to run `/v-team` (or `/v-work`) in that repo — it reads
     `requirements/<feature>.md` (LOAD CONTEXT now globs `requirements/`) and, **at `/v-capture` Step 4d**
     (shared by both lifecycles), writes the **established** `features/<feature>` dossier carrying each
     `REQ-NN` id. Same spec→established seam as multi-repo, just inside one vault. Then end the v-pm run.

Carry the resolved **mode** (`single-repo` | `multi-repo`) forward — Steps 3/4/5 branch on it.

## 1.4 Name + slug
Pick a short kebab-case `<feature>` slug (e.g. `saved-filters`, `team-billing`). This is the workspace
directory name and the `/v-team <feature>` argument. Confirm it isn't already taken: **multi-repo** →
check `_features/<feature>/`; **single-repo** → check `<project-vault>/requirements/<feature>.md` (that's
where single-repo mode writes it, not `_features/`).

## Required output
```
Necessity: <one sentence>
Assumptions: [stated defaults] · Clarifications: [asked | none needed]
Participants: [api, frontend, …]   (source: named | coupled-group <g> | asked)
Feature slug: <feature>
```
Mark INTAKE `completed` → Step 2.
