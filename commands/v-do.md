---
description: Small, low-risk change — no approval gate, no propose loop. Orient (vault-lite) → execute → self-review. Capture is offered, off by default. Escalates to /v-work when scope grows.
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

# /v-do — small job (no approval gate)

Light sibling of `/v-work`. For **small, low-risk changes** where the full gated lifecycle is
overkill: a one-file fix, a rename, a tweak, a tightly-scoped addition. Single file, loaded whole.

`/v-do` drops the ceremony `/v-work` exists to provide — there is **no PROPOSE step and no approval
gate**. The guardrail below replaces them: it is the line that decides whether a job is actually
small. Cross it and you escalate, you do not push through.

(`/v-work` now auto-detects small jobs at ANALYZE §1.4c and takes this flow itself — you don't have to
pre-classify. Invoking `/v-do` directly still works and skips the ANALYZE ceremony entirely.)

---

## Guardrail — when to STOP and escalate (this replaces the approval gate)

Before editing, sanity-check scope. Escalate **before** touching code if any hold:

- Touches **architecture, schema/migration, auth, billing, or a cross-repo contract** → `/v-team`.
- Spans more than ~5 files, or you can't predict the blast radius → `/v-work`.
- Destructive or hard to reverse (drops data, deletes/​overwrites work you didn't create, mass
  rewrite) → stop, surface it, get explicit consent (per global safety rules).
- You're unsure it's small → it isn't. Escalate.

Escalating means: state in one line why it's bigger than `/v-do`, and suggest `/v-work` or `/v-team`.

---

## Tools — preferred, never gating

claude-mem, Serena, MorphLLM, graphify — present → use it (don't hand-roll grep/full-file
reads/`sed`); genuinely down → health-check, warn once, fall back, never halt. Serena and graphify
ship only in the developer install (`setup.sh --full`) — on a `light` machine
(`~/vault/_global/config.md` → `install_mode`) they are absent by design: grep and say nothing. Full
rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md`.

---

## Flow

No task list required for a small job — but if it grows past a couple of units, create one and
reconsider the guardrail.

### 1 — Orient (lite)

- Restate the change in one line. Detect the test command (project `CLAUDE.md` / Step-1 cues; Docker
  projects use their Docker test aliases).
- **Sync the vault first** (unless `behaviour.vault_autosync` is `false`):
  `$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh pull <project-vault>`. Exit 0 and 4 are silent; anything
  else is one line and you carry on. Contract: `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`.
  The matching push happens only if the optional capture at the end actually runs — `/v-capture` owns it.
- **Cheap vault check, not the full Step-2 sweep:** claude-mem `search("<keywords>")` for prior
  decisions/gotchas in this area (playbook §2; grep the vault if it isn't installed), and read any
  `indications/` rows matching the files you'll touch — those are **binding constraints**, not
  suggestions. Skip the rest unless the answer needs it.
- Structural question (what calls X, where defined) → `graphify query` / Serena `find_symbol` before
  grepping, when they are installed. Otherwise go straight to the edit.

### 2 — Execute

File-editing rules (same as `/v-work` §4.2) — **`sed`/`awk`/`python`/heredocs never modify file
content:**

| Operation | Tool |
|-----------|------|
| Single-location change | `Edit` |
| Several changes, one file | `MultiEdit` |
| Bulk / multi-file pattern edit | `MorphLLM morph_edit` (keep `// ... existing code ...` markers both ends) |
| New file / full rewrite | `Write` |
| Project-wide symbol rename | Serena `rename_symbol` |

Honor every `indications/` rule loaded in step 1. Follow existing patterns. Write or adjust tests for
the changed surface (AAA, descriptive names, behaviour not internals, cover edge + error — not
happy-path-only). Run the detected test command against that surface; fix root cause before moving on.

### 3 — Self-review (lite)

Quick pass over each changed file: no dead/commented-out code, no magic numbers/strings, no copy-paste
(extract shared), pattern + `indications/` compliance, input validated at boundaries. Issue → fix,
re-run the relevant check (max 3 iterations); still failing → present to the user.

### 4 — Capture (optional, OFF by default)

`/v-do` does **not** capture by default — that's what keeps it cheap. After the change lands:

- Routine/trivial (typo, small fix following an existing pattern) → **skip capture, say nothing.**
- Notable (a decision was made, a non-obvious gotcha surfaced, a reusable pattern emerged) → **offer**
  it: *"Notable — want me to `/v-capture` this?"* Run capture only if the user says yes.

### Commit

Do **not** auto-commit. Commit only when the user asks (global rule). Work on the current branch; do
not `git checkout -b` (the user branches if they want isolation).
