---
description: Capture this session as a vault sessions/*.md doc. Runs dedupe vs recent sessions, auto-updates indexes, extracts ADR candidates, cross-links Refs.
---

# /v-capture — Enhanced session capture

Force-write this session into the project vault: dedupe vs recent sessions, session doc, ADR +
indication candidates, feature dossier gate, Refs cross-linking, index updates, OV push.

Prefers OpenViking and claude-mem. If either is down, surface it and skip that push (Step 5) —
degrade gracefully, never halt, never skip *silently*.

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

## Step 5 — Indexes + push

- **`_moc.md`:** `$VC index-moc --vault <vault> --session <filename> --goal "<goal>"` (idempotent,
  keeps last 5).
- **`_feature-index.md`:** created → add row; updated → set "Last touched" = today; skipped → no-op.
- **OpenViking:** probe `memory_health()` — if unreachable, tell the user and skip. Else
  `memory_store(text=<summary: goal, decisions, files, gotchas, session link>, role="assistant")`.
  OV is an MCP plugin (`mcp__plugin_openviking-memory_*`) — never `curl` it.
- **claude-mem:** no action — its SessionEnd hook auto-captures; `mcp-search` is read-only.

## Output

```
Captured: <vault>/sessions/<filename>.md
  Dedupe: <new | appended-to-PREV | continues-from-PREV>
  Indexes updated: <_moc.md, _feature-index.md, decisions/_inventory.md, indications/_index.md>
  ADR candidates: <N found, M promoted>     Indications: <N found, M promoted | skipped (toggle off)>
  Features: <created: a · updated: b · skipped: c>     Refs: <K links>
  OV: <pushed | memory_health unreachable — user notified>     claude-mem: auto-capture on session end
```

One line per item; no further commentary unless asked. Re-runs are safe: same-minute slug overwrites
in place, the script's index/dedupe steps are idempotent, already-promoted candidates are not re-offered,
and an already-updated dossier with no new changes resolves to SKIP.
