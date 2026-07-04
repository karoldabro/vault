---
description: Generate a cross-project integration guide (API contract, data structures, enums, data flow) from an existing feature.
argument-hint: "<feature-slug> [--source <project-slug>] [--for <project-slug,...>]"
---

# /v-guide — Integration Guide Generator

Generate a structured **integration guide** from a feature that already exists in one project, so other projects can implement it without repeating the same prompt. The guide captures the external contract only: API endpoints, request/response shapes, data structures, enums, filtering, and data flow — no implementation code.

Run this once after building a feature. Share the guide path with every consuming project.

**Idempotency:** Re-running with the same `<feature-slug>` overwrites the existing guide, it does not duplicate it.

---

## Tools

| Tool | Health check | Fallback |
|------|-------------|----------|
| OpenViking | `memory_health()` (MCP — never `curl`) | `grep -ril` over `~/vault/<source>/` |
| graphify | `graphify-out/graph.json` present in source repo | grep source repo for routes/models |
| MorphLLM | (MCP — no runtime check) | `Write` / `Edit` |

---

## Step 1 — Resolve arguments

Parse `$ARGUMENTS`:

1. **`<feature-slug>`** (required) — first positional arg. Stop with usage error if absent:
   ```
   Usage: /v-guide <feature-slug> [--source <project>] [--for <project,...>]
   ```

2. **`--source <project-slug>`** (optional) — source project whose vault holds the feature. Default: detect from `$PWD` by matching against known vaults in `~/vault/`. If `$PWD` is not inside a known project, stop and ask the user to pass `--source` explicitly.

3. **`--for <project-slug,...>`** (optional) — comma-separated target project slugs the guide is intended for. Default: all projects coupled with `<source>` (read `~/vault/_global/coupled-groups.md`). Used only for the output summary line — does not change what is written.

4. **Validate** source vault exists: `ls ~/vault/<source>/`. Stop if missing.

---

## Step 2 — Load feature context

Query cheapest-first. Stop when you have enough to fill the guide template.

### 2.1 OpenViking
```
memory_health()            # confirm reachable
memory_recall(query="<feature-slug> api endpoints data structures")
```
Look for: prior sessions describing the feature, ADRs, pitfalls, API shapes already documented.

### 2.2 Vault feature doc
Read `~/vault/<source>/features/<feature-slug>.md` if it exists.  
Also scan `~/vault/<source>/features/` for partial matches (slug may have a numeric prefix).

### 2.3 ADRs
```bash
grep -ril "<feature-slug>" ~/vault/<source>/decisions/ 2>/dev/null
```
Read every matching ADR for data shape decisions, enum definitions, versioning choices.

### 2.4 Graphify (structural — source repo)
If `<source-repo>/graphify-out/graph.json` exists:
```bash
graphify query "<feature-slug> routes endpoints"
graphify query "<feature-slug> models schema"
graphify query "<feature-slug> enums constants"
```
Fallback: `grep -ril "<feature-slug>" <source-repo>/app/Http/Controllers/ <source-repo>/routes/ 2>/dev/null | head -20`

### 2.5 Fallback
If all above come up thin, grep the source repo for the feature slug across routes, models, and request classes:
```bash
grep -ril "<feature-slug>" <source-repo>/{routes,app} 2>/dev/null | head -30
```

---

## Step 3 — Extract contract

From the loaded context, extract **only the external-facing contract**:

- **Overview** — what the feature does (2–5 sentences, no implementation)
- **Data flow** — sequence of calls: who sends what, what comes back
- **Enums & constants** — every named value the API emits or accepts
- **Data structures** — JSON shapes for every entity (keys + meaning, no types/classes)
- **API endpoints** — method, path, description, auth requirement
- **Request/response shapes** — per endpoint: body, query params, response, errors
- **Filtering & pagination** — all supported filter params, sort fields, pagination pattern

If a section cannot be determined from context, mark it `<!-- TODO: fill from source -->` rather than inventing values.

---

## Step 4 — Write guide

1. Instantiate `$VAULT_FRAMEWORK_PATH/templates/integration-guide.md` (default `~/workspace/vault/templates/`):
   - Copy template structure
   - Fill all sections from Step 3 extraction
   - Set frontmatter: `source_project`, `feature_slug`, `generated` (today's date)
   - Remove `status: stub` from frontmatter once content is filled

2. Create `guides/` directory if absent:
   ```bash
   mkdir -p ~/vault/<source>/guides/
   ```

3. Save guide:
   - Target path: `~/vault/<source>/guides/<feature-slug>.md`
   - Use MorphLLM `morph_edit` if available; fallback `Write`

---

## Step 5 — Cross-link + index

### 5.1 Update `_moc.md`
Open `~/vault/<source>/_moc.md`. Find or create a `## Guides` section. Add entry:
```markdown
## Guides
- [[guides/<feature-slug>]] — <Feature Name> integration contract
```
Do not duplicate if entry already exists.

### 5.2 Back-link in feature doc
If `~/vault/<source>/features/<feature-slug>.md` exists, add (or update) a line near the top:
```markdown
Integration Guide: [[../guides/<feature-slug>]]
```

### 5.3 Push to OpenViking
Probe `memory_health()` first; if unreachable, surface and skip (never halt). Then:

```
memory_store(
  text="Integration guide for <feature-slug> in <source>: covers endpoints, request/response shapes, enums, data flow. Path: ~/vault/<source>/guides/<feature-slug>.md",
  role="assistant"
)
```

(OV exposes only `memory_store(text, role)` / `memory_recall` / `memory_health` / `memory_forget` — there is no `content=`/`tags=` signature.)

---

## Step 6 — Output

```
Guide written:  ~/vault/<source>/guides/<feature-slug>.md
MOC updated:    ~/vault/<source>/_moc.md
Targets:        <project1>, <project2>  (share this path with each team)
Sections:       Overview · Data Flow · Enums (N) · Endpoints (N) · Request/Response · Filtering
TODOs:          N sections need manual fill (grep "TODO" in the guide)
```

If any section was left as `<!-- TODO -->`, surface a count and remind the user to fill before sharing.
