---
description: Capture this session as a vault sessions/*.md doc. Runs dedupe vs recent sessions, auto-updates indexes, extracts ADR candidates, cross-links Refs.
---

# /v-capture — Enhanced session capture

Force-write this session into the project vault. This command:

1. **Dedupes** vs the last 10 sessions and offers to append to an existing one if topics overlap.
2. **Auto-updates** `_moc.md` and `_feature-index.md` when affected.
3. **Extracts ADR candidates** by regex-scanning the session for decision-shaped sentences.
4. **Cross-links** `Refs` by scanning content for `[[wikilinks]]`, `ADR-NNN`, and `features/NN-` patterns.

OV-optional: every OV call has a grep fallback.

---

## Resolve project

1. From `$PWD` or the most-touched file path in this session, derive the project slug.
2. Match against `~/vault/_global/coupled-groups.md` if present.
3. Confirm `~/vault/<slug>/` exists. If not, stop and tell the user to run `/v-init` (from inside the code repo) first.

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
ls -t ~/vault/<slug>/sessions/*.md 2>/dev/null | head -10
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

Use template `~/vault/<slug>/_process/templates/session.md` (or `~/workspace/vault/templates/session.md` if submodule absent).

Path: `~/vault/<slug>/sessions/YYYY-MM-DD-HHMM-<slug>.md`.

If a sub-slug applies (multi-repo product, e.g. `vivi/api`), prefix the filename: `api-YYYY-MM-DD-HHMM-<slug>.md`.

Fill honestly from actual conversation:
- **Goal** — one sentence.
- **Did** — concrete steps. Real file paths.
- **Learned** — non-obvious facts. Gotchas. Surprises.
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

## Step 5 — Cross-link Refs

Scan session body for these patterns and materialize all into the `Refs` section:

- `[[wikilink]]` patterns already present.
- `ADR-\d+` references → resolve to `[[../decisions/ADR-NNN-<slug>]]` by looking up the inventory.
- `features/NN-<slug>` → resolve to `[[../features/NN-<slug>]]`.
- File paths under `~/vault/<slug>/` → wikilink form.

Deduplicate. Sort alphabetically.

---

## Step 6 — Update indexes

### `_moc.md`

If a "Sessions (recent)" block exists, prepend a line:
```
- [[sessions/YYYY-MM-DD-HHMM-<slug>]] — <goal>
```

Keep only the last 5 entries (older ones can be found by browsing `sessions/`).

### `_feature-index.md`

For each affected feature (frontmatter `features:` array or wikilinks to `features/*`):
- Find the row in the table.
- If a "Last touched" column exists, update the date.
- Otherwise no-op.

---

## Step 7 — Push to OpenViking (optional)

If OV is reachable:
```bash
curl -sf --max-time 1 http://127.0.0.1:1933/health
```

Call the OV `add_episode` MCP tool (registered by the openviking plugin) with:
- `project`: resolved slug
- `type`: `session`
- `content`: markdown body
- `source_path`: session file path

If OV unreachable, skip silently — the vault file will be ingested on next OV reindex.

---

## Output

```
Captured: ~/vault/<slug>/sessions/<filename>.md
  Dedupe: <new | appended-to-PREV | continues-from-PREV>
  Indexes updated: <_moc.md, _feature-index.md, decisions/_inventory.md>
  ADR candidates: <N found, M promoted>
  Refs: <K links cross-linked>
  OV: <pushed | skipped>
```

One line per item. No further commentary unless the user asks.

---

## Idempotency

Re-running `/v-capture` on the same session within the same minute:
- Same filename slug → overwrite is OK (content updates).
- Do NOT duplicate the MOC line: check for existing wikilink to the same session file before prepending.
- Do NOT re-extract ADR candidates that were already promoted in a prior run.
