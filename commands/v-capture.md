---
description: Capture this session as a vault sessions/*.md doc. Runs dedupe vs recent sessions, auto-updates indexes, extracts ADR candidates, cross-links Refs.
---

# /v-capture — Enhanced session capture

Force-write this session into the project vault. This command:

1. **Dedupes** vs the last 10 sessions and offers to append to an existing one if topics overlap.
2. **Auto-updates** `_moc.md` and `_feature-index.md` when affected.
3. **Extracts ADR candidates** by regex-scanning the session for decision-shaped sentences.
4. **Extracts indication candidates** — reusable working rules / patterns / standards — the same way.
5. **Runs the feature dossier gate** — create / update / skip a `features/` doc per the work done.
6. **Cross-links** `Refs` by scanning content for `[[wikilinks]]`, `ADR-NNN`, and `features/NN-` patterns.

Requires OpenViking and claude-mem. Both push steps are mandatory — do not skip silently.

---

## Resolve project + vault path

1. From `$PWD` or the most-touched file path in this session, derive the project slug.
2. Match against `~/vault/_global/coupled-groups.md` if present.
3. Resolve the vault path per `vault-guide.md` §1.1: `<repo-root>/VAULT.md` → `vault_path`, else
   `~/vault/_global/config.md`, else `~/vault/<slug>/`. Note any `behaviour.capture_indications` toggle.
4. Confirm the vault dir exists. If not, stop and tell the user to run `/v-init` (or `/v-migrate` for an
   old submodule vault) from inside the code repo first.

Below, `<vault>` means the resolved vault path (which may be in-repo, e.g. `<code-repo>/vault`).

---

## Step 1 — Extract session metadata

From the conversation, derive:

- **Goal**: one-sentence statement of what this session set out to do.
- **Topic slug**: kebab-case, ≤6 words, derived from goal.
- **Keywords**: 3–6 short keywords (drives dedupe).
- **Files touched**: list real file paths edited.
- **Affected features/ADRs**: wikilinks discoverable from file paths or explicit mentions.

---

## Step 2 — Dedupe vs recent sessions

```bash
ls -t <vault>/sessions/*.md 2>/dev/null | head -10
```

For each recent session file, grep for the keywords:
```bash
for kw in <keywords>; do
  grep -l "$kw" <recent-session-files> 2>/dev/null
done | sort | uniq -c | sort -rn | head -3
```

Compute overlap: `(matches / total-keywords) * 100`. If `>60%` for any single recent session:

- **Prompt user**: "Topic overlaps with `[[YYYY-MM-DD-HHMM-<prev>]]`. Append to it or write a new session?"
- **If append**: open the prior session, add a `## Continuation YYYY-MM-DD-HHMM` section under existing content.
- **If new**: continue, but add `continues: [[YYYY-MM-DD-HHMM-<prev>]]` to frontmatter.

If `<60%` for all, write a fresh session.

---

## Step 3 — Write session file

Use template `$VAULT_FRAMEWORK_PATH/templates/session.md` (default `~/workspace/vault/templates/session.md`).

Path: `<vault>/sessions/YYYY-MM-DD-HHMM-<slug>.md`.

If a sub-slug applies (multi-repo product, e.g. `vivi/api`), prefix the filename: `api-YYYY-MM-DD-HHMM-<slug>.md`.

Fill honestly from actual conversation:
- **Goal** — one sentence.
- **Did** — concrete steps. Real file paths.
- **Learned** — non-obvious facts. Gotchas. Surprises.
- **Behaviors & rules** — domain rules / expected outcomes / edge cases the work **established or
  validated**, phrased so a test could assert them (suggested shape: `precondition → expected outcome
  [; edge: when X then Y]`). Only rules this session established or validated — never aspirational
  "should build" items (✓ `idempotency key = sha256(file:rule:code)`; ✗ `we should add rate limiting`).
  Keep it modest: ~3–7 bullets. **Omit the section entirely** for sessions with no domain rules (pure
  infra / refactor / config). This is the raw material for later business / feature / integration / UI
  tests, so write it test-shaped — but don't manufacture rules the work didn't touch.
- **Next** — open threads, deferred items.
- **Refs** — see Step 5.

---

## Step 4 — ADR candidate extraction

Regex-scan the session content + recent conversation for decision-shaped sentences:

```
patterns: "we decided", "decided to", "chose .* over", "going with", "agreed to",
          "settled on", "picked .* because", "rejected .* in favor of"
```

For each match, present a one-line summary to the user:

```
ADR candidates found:
  1. "chose Postgres over MySQL because of PostGIS"
  2. "going with bearer tokens, not cookies"
  Promote any to ADR stubs? (y/N + numbers)
```

For each confirmed candidate:
- Read `decisions/_inventory.md`, take next free ADR number.
- Create `decisions/ADR-NNN-<slug>.md` from `decision.md` template, populated with the decision sentence as the title and rationale stub.
- Append row to `decisions/_inventory.md`.

---

## Step 4b — Indication candidate extraction

Skip if `behaviour.capture_indications` is `false` in `VAULT.md`. Otherwise mirror the ADR scan, but for
*how-we-work* statements — reusable working rules, patterns, standards, testing conventions.

Regex-scan the session + recent conversation:

```
patterns: "convention:", "pattern:", "rule:", "standard", "always <verb>", "never <verb>",
          "we use .* for", "prefer .* over", "the .* way is", "<x> should always|never",
          testing-approach statements ("test .* with", "mock .* not")
```

Rule-shaped bullets in a session's `## Behaviors & rules` are natural candidates here — a domain rule
that recurs across features belongs in `indications/` (durable), not just one session. The
always/never/rule: scan above already catches them; no separate pass needed.

Dedupe against existing `indications/_index.md` rows first (don't re-offer a rule already captured).
Present remaining matches as one-line candidates:

```
Indication candidates found:
  1. "controllers stay thin — business logic goes in actions"
  2. "feature tests use factories, never hardcoded fixtures"
  Promote any to indications? (y/N + numbers)
```

For each confirmed candidate:
- Create `indications/<slug>.md` from `indication.md` template (Rule = the statement; fill Rationale /
  Examples / Applies-to from context, leave `<!-- TODO -->` where unknown).
- Append a row to `indications/_index.md`: `| <slug> | <one-line rule> | <applies-to> |`.

---

## Step 5 — Cross-link Refs

Scan session body for these patterns and materialize all into the `Refs` section:

- `[[wikilink]]` patterns already present.
- `ADR-\d+` references → resolve to `[[../decisions/ADR-NNN-<slug>]]` by looking up the inventory.
- `features/NN-<slug>` → resolve to `[[../features/NN-<slug>]]`.
- File paths under `<vault>/` → wikilink form.

Deduplicate. Sort alphabetically.

---

## Step 5b — Feature dossier gate

`features/` goes stale because capture reads it but rarely writes it. Force an explicit decision here —
do not silently no-op. For each feature/domain this session touched (from files changed, ADRs linked, or
explicit mentions), pick exactly one:

- **CREATE** `features/<slug>.md` (from `feature.md`) when the session introduced a new feature/domain
  with no existing dossier. Use the dedupe ≥60% novelty threshold from `/v-work` §3b — below it, it's
  not new, so UPDATE instead.
- **UPDATE** an existing dossier when the session changed its **contracts, behaviors/rules, gotchas, or
  coupling** — a touched file maps to it, a new ADR links to it, an endpoint/table/event/enum changed, or
  a domain rule / acceptance criterion was established. Edit the affected section(s) and add the session
  wikilink under `## Sessions`. When behavior changed, populate `## Behaviors & rules` with the durable
  invariants/acceptance criteria the session established (~3–7 bullets, test-shaped) — keep each rule in
  one section (Behaviors, not duplicated in Gotchas; cross-link if it is also a trap).
- **SKIP** when the work carried no durable domain knowledge (pure bugfix, cosmetic, config bump).

Report the verdict per feature in the output (`created | updated | skipped: <reason>`). Then reconcile
`_feature-index.md` in Step 6.

---

## Step 6 — Update indexes

### `_moc.md`

If a "Sessions (recent)" block exists, prepend a line:
```
- [[sessions/YYYY-MM-DD-HHMM-<slug>]] — <goal>
```

Keep only the last 5 entries (older ones can be found by browsing `sessions/`).

### `_feature-index.md`

For each feature from the Step 5b gate:
- **Created** → add a new row (Feature, Status, Last touched = today, Notes).
- **Updated** → find the row; if a "Last touched" column exists, set it to today.
- **Skipped** → no-op.

### `indications/_index.md`

Already appended in Step 4b for any promoted indication — verify the row is present.

---

## Step 7 — Push to OpenViking + claude-mem

### 7.1 — OpenViking

Probe `memory_health()` first. If unreachable, surface the issue to the user and skip the push — do not fail silently.

Call the OV `memory_store` MCP tool with:
- `text`: session summary (goal, key decisions, files touched, gotchas learned, link to session file)
- `role`: `"assistant"`

OV is a Claude Code MCP plugin (`mcp__plugin_openviking-memory_*`). Never `curl` it — the model has no HTTP reachability, only MCP tools.

### 7.2 — claude-mem

No action needed. claude-mem auto-captures this session via its SessionEnd hook (compression). The `mcp-search` server is read-only — it exposes no write tool. Future `/v-work` sessions will see this session via `search()` → `timeline()` → `get_observations()`.

---

## Output

```
Captured: <vault>/sessions/<filename>.md
  Dedupe: <new | appended-to-PREV | continues-from-PREV>
  Indexes updated: <_moc.md, _feature-index.md, decisions/_inventory.md, indications/_index.md>
  ADR candidates: <N found, M promoted>
  Indication candidates: <N found, M promoted | skipped (capture_indications=false)>
  Features: <created: a · updated: b · skipped: c>
  Refs: <K links cross-linked>
  OV: <pushed via memory_store | memory_health unreachable — user notified>
  claude-mem: auto-capture on session end
```

One line per item. No further commentary unless the user asks.

---

## Idempotency

Re-running `/v-capture` on the same session within the same minute:
- Same filename slug → overwrite is OK (content updates).
- Do NOT duplicate the MOC line: check for existing wikilink to the same session file before prepending.
- Do NOT re-extract ADR candidates that were already promoted in a prior run.
- Do NOT re-offer indication candidates already present in `indications/_index.md`.
- The feature gate is re-runnable: an already-updated dossier with no new changes resolves to SKIP.
