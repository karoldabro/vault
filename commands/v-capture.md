---
description: Capture this session as a vault sessions/*.md doc. Runs dedupe vs recent sessions, auto-updates indexes, extracts ADR candidates, cross-links Refs.
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

# /v-capture — Enhanced session capture

Force-write this session into the project vault: dedupe vs recent sessions, session doc, ADR +
indication candidates, feature dossier gate, Refs cross-linking, index updates.

The session doc in the vault is the durable record — it is git-tracked and greppable. claude-mem
auto-captures alongside it; if it is absent, say so once and carry on. Degrade gracefully, never
halt, never skip *silently*.

**Mechanics live in `$VAULT_FRAMEWORK_PATH/bin/vault-capture.sh`** (default
`~/workspace/vault/bin/vault-capture.sh`; below: `$VC`). You supply judgment: metadata, candidate
approval, feature verdicts, honest content. Script output is advisory input, not autopilot.

---

## Step 0 — Resolve project + vault path

1. From `$PWD` or the most-touched file path this session, derive the project slug; match against
   `~/vault/_global/coupled-groups.md` if present.
2. Resolve the vault path per `vault-guide.md` §1.1: `<repo-root>/VAULT.md` → `vault_path`, else
   `~/vault/_global/config.md`, else `~/vault/<slug>/`. Note any `behaviour.capture_indications` toggle.
3. If the vault dir doesn't exist, stop and tell the user to run `/v-init` first (old submodule
   vault: `bin/vault-migrate.sh`).
4. Unless `behaviour.vault_autosync` is `false`, pull before dedupe — deduping against a stale copy
   invents duplicates. Skip if this session already pulled (e.g. `/v-work` step 2 did).

```bash
$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh pull <vault>
```

Exit codes and what to do with each: `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`. A failed
pull never blocks the capture — write the session anyway.

Below, `<vault>` = the resolved path (may be in-repo, e.g. `<code-repo>/vault`).

## Step 1 — Extract session metadata (judgment)

From the conversation: **Goal** (one sentence), **topic slug** (kebab-case ≤6 words), **keywords**
(3–6, drives dedupe), **files touched** (real paths), **affected features/ADRs**.

## Step 2 — Dedupe

```bash
$VC dedupe --vault <vault> --keywords "<kw1 kw2 ...>"
```

If any file scores >60%: ask the user — append a `## Continuation YYYY-MM-DD-HHMM` section to it, or
write fresh with `continues: [[that-session]]` in frontmatter. Else write fresh.

## Step 3 — Write session file (judgment)

Template: `$VAULT_FRAMEWORK_PATH/templates/session.md`. Path: `<vault>/sessions/YYYY-MM-DD-HHMM-<slug>.md`
(multi-repo products prefix the sub-slug: `api-YYYY-...`). Fill honestly from the actual conversation:

- **Goal / Did / Learned / Next** — concrete steps, real paths, non-obvious facts, open threads.
- **Behaviors & rules** — only rules this session **established or validated**, test-shaped
  (`precondition → expected outcome [; edge: when X then Y]`), ~3–7 bullets. Never aspirational
  "should build" items. **Omit the section** for pure infra/refactor/config sessions.
- **Refs** — from Step 4c.

## Step 4 — Candidates + Refs

**4a ADRs:** `$VC scan-adr --file <session-file>` → present candidates one-per-line, ask
`Promote any to ADR stubs? (y/N + numbers)`. For each confirmed: `$VC next-adr --vault <vault>` for the
number, create `decisions/ADR-NNN-<slug>.md` from the `decision.md` template, append the
`decisions/_inventory.md` row. Skip candidates already promoted in a prior run.

**4b Indications** (skip if `capture_indications: false`): `$VC scan-ind --file <session-file> --vault <vault>`
— offer only `NEW` lines (`DUP` = already in `indications/_index.md`). For each confirmed: create
`indications/<slug>.md` from the `indication.md` template, append the `_index.md` row. Rule-shaped
bullets from `## Behaviors & rules` are natural candidates — a rule that recurs across features belongs
in `indications/` (durable), not just one session.

**4c Refs:** `$VC refs --file <session-file> --vault <vault>` → paste the resolved, deduped list into
the session's `Refs` section; resolve any `UNRESOLVED ADR-NNN` lines by hand or drop them.

## Step 4d — Feature dossier gate (judgment — do not silently no-op)

For each feature/domain this session touched (files changed, ADRs linked, explicit mentions), pick one:

- **CREATE** `features/<slug>.md` (from `feature.md`) — new feature/domain, no dossier, novelty ≥60%
  (the `/v-work` §3b threshold); below it, UPDATE instead.
- **UPDATE** — the session changed its **contracts, behaviors/rules, gotchas, or coupling**. Edit the
  affected sections, add the session wikilink under `## Sessions`; when behavior changed, add the durable
  test-shaped rules to `## Behaviors & rules` (keep each rule in one section; cross-link if also a trap).
- **SKIP** — no durable domain knowledge (pure bugfix, cosmetic, config bump).

**Requirements id chain (feature mode — `/v-work` AND `/v-team`):** when a `requirements.md` exists for
this work, each dossier Behavior bullet realising a requirement carries its `REQ-NN` inline
(`[REQ-07] precondition → expected`) and records only **established** (built) rules — unshipped spec
rules stay in `requirements.md`. `/v-team` `04-execute-loop.md` §5.4a defers here.

Report per feature: `created | updated | skipped: <reason>`.

## Step 4e — Feature status rollup (feature mode only)

When this session worked a `_features/<feature>/` workspace, **derive** that feature's `header.md`
`status:` from the session rows across every `projects/*/plan.md` `## Sessions` table, and write it:

| every row | status |
|---|---|
| `todo`, or no rows at all | `planning` |
| any row `doing` or `done`, but not all | `in-progress` |
| every row `done` or `dropped` | `shipped` |

**Derive it, never ask.** This field exists in two places today — the header and the rows — and only
the rows get written, so nine of twelve features currently claim `planning` while their own shards say
otherwise. That is what makes `/v-pm status` unable to tell you what is really moving. Writing it here,
on the way out of every session, is what keeps the two in step.

Report the rollup only when it **changed** the field.

## Step 5 — Indexes + push

- **`_moc.md`:** `$VC index-moc --vault <vault> --session <filename> --goal "<goal>"` (idempotent,
  keeps last 5).
- **`_feature-index.md`:** created → add row; updated → set "Last touched" = today; skipped → no-op.
- **claude-mem:** no action — its SessionEnd hook auto-captures; `mcp-search` is read-only.
- **Push:** unless `behaviour.vault_autosync` is `false`, commit and push everything this capture
  wrote. This is the step that gets the session out of this machine — do it last, after the indexes:

  ```bash
  $VAULT_FRAMEWORK_PATH/bin/vault-sync.sh push <vault> -m "capture <slug>" <session file> <indexes> <new ADRs/indications/dossiers>
  ```

  Never raw `git`, never `git add -A`. Exit 4 (vault lives inside the code repo) is silent — the code
  repo's own commit covers it. Contract: `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`.

## Output

```
Captured: <vault>/sessions/<filename>.md
  Dedupe: <new | appended-to-PREV | continues-from-PREV>
  Indexes updated: <_moc.md, _feature-index.md, decisions/_inventory.md, indications/_index.md>
  ADR candidates: <N found, M promoted>     Indications: <N found, M promoted | skipped (toggle off)>
  Features: <created: a · updated: b · skipped: c>     Refs: <K links>
  Sync: <only when it did NOT push — not a git repo / no upstream / push failed>
```

Omit the `Sync` line entirely on a clean push; a vault that reached its remote is the expected
outcome. One line per item; no further commentary unless asked. Re-runs are safe: same-minute slug overwrites
in place, the script's index/dedupe steps are idempotent, already-promoted candidates are not re-offered,
and an already-updated dossier with no new changes resolves to SKIP.
