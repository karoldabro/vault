---
description: Read-only, vault-aware Q&A. Loads context cheapest-first (vault → symbols → source) and answers. No edits, no approval, no capture.
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

# /v-ask — context-aware answer (read-only)

Light sibling of `/v-work`. **Answers a question with vault context loaded — nothing else.**
No task list, no PROPOSE, no approval gate, no EXECUTE, no capture. Single file, loaded whole.

Reach for `/v-ask` when you want a grounded answer ("how does X work here", "where is Y decided",
"what did we conclude about Z") **without** starting a change. The moment the answer requires editing
a file, stop and hand off — see *Hard rules* below.

---

## Hard rules — read-only, never gating

- **No mutations.** Never call `Edit`, `MultiEdit`, `Write`, Serena refactors, or any
  `git` write. No file in any repo or vault changes during `/v-ask`.
- **No capture.** Do not run `/v-capture` or write memory. This command leaves no trail.
- **If answering needs a change** — say so in one line and suggest `/v-do` (small job) or `/v-work`
  (gated lifecycle). Do not start it yourself.
- Tools below are **preferred, not gating**: present → use it; genuinely down → health-check, warn
  once, fall back, never halt.

---

## Search precedence — stop as soon as you can answer

Query cheapest-first. A vault hit costs ~100–2000 tok; reading 40 source files costs ~20k. Stop the
moment you have enough to answer — do **not** walk every layer out of habit.

1. **Vault grep** — `grep -ril "<keyword>" <project-vault>/{decisions,sessions,indications,features}/`
   for decisions, ADRs, past sessions, dossiers, pitfalls and coupled projects. Read only the hits.
2. **Indications + MOC** — `<project-vault>/indications/_index.md` and `_moc.md` for the canonical
   "how this project works" rules and the map of dossiers. Read the matching rows only.
3. **Serena, when present** — `find_symbol` / `get_symbols_overview` / `find_referencing_symbols` for
   structural questions (what calls X, where is Y defined) and to orient before reading whole files.
4. **Grep / Glob / Read source** — last resort, or to verify a specific current line.

**Fan out when broad.** If the question spans several areas and you can't answer from one cheap
layer, launch up to 3 read-only **Explore** subagents in parallel (one message, multiple `Agent`
calls) — distinct foci (vault/decisions · code structure · tests). They return conclusions; your
context stays lean.

---

## Answer format

- Shape and length are governed by the communication contract bound at the top of this file.
- **Cite sources** so the user can verify: `file_path:line`, ADR ids, session/dossier names. An uncited claim about "what the codebase does" is a guess — mark it as one or go verify.
- If the vault and source disagree (stale doc), surface the conflict rather than picking silently.
- If the answer implies work, close with the one-line `/v-do` or `/v-work` hand-off.
