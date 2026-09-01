# Step 1 — INTAKE (plan mode)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Capture the business necessity, make sure it's understood, and decide who's in.

## 1.1 Elicit (do not merely clarify)
Read `$VAULT_FRAMEWORK_PATH/commands/_shared/elicitation.md` and run it. That module owns the whole
protocol: the technique menu worked cheapest-first (document analysis → five whys when the operator
hands you a solution → research → scenario walkthrough → example-driven), where each answer lands, and
the stopping rule. It is not repeated here.

Three things this step must produce beyond the module's own output:

1. **The need, restated in one sentence** — after the whys, not before them. The operator usually
   arrives with a solution; the need behind it is what the plan is built on.
2. **The measurable success metric**, into `requirements.md` `## Business context & goals`. If the
   operator cannot name one, record that as an open question rather than inventing one.
3. **What "done" adds** beyond the baseline in
   `$VAULT_FRAMEWORK_PATH/commands/_shared/definition-of-done.md`. Ask only for the additions — a
   performance bound, a migration that must complete, a third party that must confirm. The floor is
   fixed and is not the operator's to restate.

**Unanswered does not mean blocked.** Every question still open after the stopping rule gets a stated
default, written to `requirements.md` `## Assumptions to test` and surfaced at the approval gate where
it can still be corrected. The one exception is a genuine plan-fork with **no safe default** — ask via
`AskUserQuestion` and **wait**. Planning ahead is the most expensive place to guess, but holding a
whole feature for a question that changes nothing is its own failure.

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
     into `<project-vault>/sessions/`, commit the project vault (not
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
Need: <one sentence, after the whys — the problem, not the requested solution>
Techniques used: [document analysis · five-whys · …]   (ruled out: <n> — <reason>)
Asked: <n> · Answered: <n> · Defaulted: <n>   (defaults → requirements.md `## Assumptions to test`)
Still open: [carried to `## Open questions`, with why each does not block]
Success metric: <the operator's measurable outcome | not supplied — recorded as open>
Done adds: [what this feature adds to the baseline | nothing beyond the baseline]
Participants: [api, frontend, …]   (source: named | coupled-group <g> | asked)
Feature slug: <feature>
```
Mark INTAKE `completed` → Step 2.
