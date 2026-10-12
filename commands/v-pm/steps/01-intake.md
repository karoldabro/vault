# Step 1 — INTAKE (plan mode)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Understand the need, get the operator's success criteria, decide who is in, and size the work.

## 1.1 Elicit (do not merely clarify)
Read `$VAULT_FRAMEWORK_PATH/commands/_shared/elicitation.md` and run it. That module owns the protocol:
the technique menu worked cheapest-first, where each answer lands, and the stopping rule. This step
adds the need restated in one sentence, after the whys and before anything else.

Every question still open after the stopping rule gets a stated default in `requirements.md`
`## Assumptions to test`, surfaced at the approval gate. A genuine plan fork with no safe default is
asked through `AskUserQuestion`, and the step waits for the answer.

## 1.2 Success criteria — refuse without them
`/v-pm` does not plan until the operator has stated at least one success criterion in this form:

```
WHEN <trigger> THE SYSTEM SHALL <observable>
```

When the operator has given none, draft one from their own words and send exactly this, filled in:

```
I will not plan until you give at least one line: WHEN <trigger> THE SYSTEM SHALL <observable>.
Drafted from your words: WHEN <trigger> THE SYSTEM SHALL <observable>.
Reply with your own lines, or "yes" to take this one.
```

An explicit "yes" makes the drafted line the operator's. Silence, "fine" to another question, or a
feature name such as "admins can export orders" does not. Repeat the refusal until a line is stated
or accepted; never write a default in its place. The lines go to the plan's `## Success criteria`,
their single home; `requirements.md` `## Business context & goals` links them.

## 1.3 Definition of done
The plan carries four default lines, DD-1 to DD-4, from `$VAULT_FRAMEWORK_PATH/templates/feature-plan.md`:
planning done, code implemented, code tested, static analysis passed. Ask the operator only what this
feature adds beyond them: a performance bound, a migration that must complete, a third party that must
confirm. The per-session floor stays in `$VAULT_FRAMEWORK_PATH/commands/_shared/definition-of-done.md`.

## 1.4 Resolve participants and their paths
1. If the operator named the repos, use them.
2. Else read `~/vault/_global/coupled-groups.md`; when the need maps to a declared group, propose its
   members and confirm.
3. Else ask which repos are in scope.

For each repo record its **absolute path** (from `coupled-groups.md` or the repo's `VAULT.md`) and its
vault path. Every session row names the path its command runs in.

## 1.5 Size the work — the scale tier
Count these facts from the intake answers: repos in scope; whether the work changes a schema, auth,
payments, a public contract or adds an external service; whether it creates a new system. Map them to
`small`, `medium` or `large` with the table in `$VAULT_FRAMEWORK_PATH/personas/_shared/planning/README.md`
`## Scale tiers`. The tier sets the reviewer and round caps in Step 3 and what each reviewer may demand.

A small project gets a small plan. A `small` tier with one obvious session may still run the panel
once; it never grows sessions to look thorough.

## 1.6 Plan home
- **1 repo** → the plan lives in `<project-vault>/plans/<feature>/`, and `requirements.md` in
  `<project-vault>/requirements/<feature>.md`. Create either folder when absent (warn once). No
  `_features/` workspace, no conversation threads, no symlinks.
- **2+ repos** → the plan and `requirements.md` live in `~/vault/_features/<feature>/`, with the
  workspace of Step 4.

Both homes hold the same three things: `plan.md`, `plan.trail.md` and `briefs/`. Carry the resolved
mode (`single-repo` | `multi-repo`) forward.

## 1.7 Name and slug
Pick a short kebab-case `<feature>` slug. Check it is free: `<project-vault>/plans/<feature>/` for
single-repo, `~/vault/_features/<feature>/` for multi-repo.

## Required output
```
Need: <one sentence, after the whys — the problem, not the requested solution>
Techniques used: [document analysis · five-whys · …]   (ruled out: <n> — <reason>)
Success criteria: <n> stated by the operator   [SC ids]
Done adds: [what this feature adds to DD-1..DD-4 | nothing]
Participants: [<repo> → <absolute path>, …]   (source: named | coupled-group <g> | asked)
Tier: <small | medium | large>   (repos: <n>; risky surface: <none | which>)
Mode: <single-repo | multi-repo>   ·   Home: <plan folder>   ·   Feature slug: <feature>
```
Mark INTAKE `completed` → Step 2. Without at least one stated success criterion INTAKE is not complete.
