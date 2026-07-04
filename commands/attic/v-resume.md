---
description: Force a fresh recall from vault + OpenViking. Optional argument scopes the query (topic, project, or "all").
argument-hint: "[topic | project-slug | 'all']"
---

Force fresh context recall. Override / supplement the OpenViking plugin's auto-recall hook.

## Resolve scope

Argument `$ARGUMENTS` determines what to pull:

- **No argument** → current project (resolve from `$PWD` against `~/vault/_global/coupled-groups.md`). Recent sessions + active features + recent decisions.
- **A project slug** (e.g. `vivi`, `vivi/api`, `digitally-core`) → that project's recent context.
- **A topic** (anything else, e.g. `bouncer`, `tenancy`, `Process tracker`) → semantic search across all vault projects.
- **`all`** → top-N recent context across every project in the vault.

## Pull layered context

For **project scope**, in this order, stop early when you have enough:

1. `~/vault/<project>/_moc.md` — map of contents.
2. Last 3 entries by mtime under `~/vault/<project>/sessions/`.
3. Most recent 3 files under `~/vault/<project>/decisions/` (or `shared/decisions/` via the symlink).
4. `~/vault/<project>/memory/` — auto-memory observations.
5. If a coupled group exists for this project, sample one recent session from each peer (light touch — peer MOC + last session only).

For **topic scope**:

1. Call OV `memory_recall(query=<topic>)` MCP tool. Read top 5 hits.
2. In parallel, call claude-mem `search(query=<topic>)` → `timeline(anchor=<top_hit_id>)` for project history context.
3. If OV is unreachable: call `memory_health()` to diagnose. Only fall back to `Grep` over `~/vault/` after confirming OV is down — grep is slower and misses semantic matches.

For **`all`**:

1. `~/vault/_moc.md`.
2. Last 1 session per project under `~/vault/*/sessions/`.

## Hard rule

- Do NOT read source code in this command. Vault + memory only. The whole point is to skip the source-read.
- If the *next* user prompt is likely structural (what calls X, where is Y, module deps), note that
  the graphify graph is available — `graph.json` is kept fresh by the post-commit hook — and answer
  from `graphify query` / `graphify path` rather than grepping source. Don't dump the graph here.
  See `$VAULT_FRAMEWORK_PATH/tool-playbook.md` (default `~/workspace/vault/`) §3.

## Output

A compact briefing (≤500 words total) summarizing what was pulled. Use wikilinks `[[../decisions/0042-foo]]` so the user can follow up. End with: "Ready. Ask away."
