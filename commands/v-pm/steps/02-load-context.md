# Step 2 — LOAD CONTEXT (plan mode)

Ground the plan in what the vault already knows — **before** the panel drafts anything. A cross-project
planner must load context from **every participant's vault**, not one. Query **cheapest-first** (the
`CLAUDE.md` precedence: vault + OV → graph → source); stop as soon as you have enough. Do **not** read
source code here.

## Tools — health check + fallback (probe once; warn + fall back, never halt)

| Tool | Check | Fallback |
|------|-------|----------|
| OpenViking | `memory_health()` (MCP plugin — never `curl`) | `Grep` over `~/vault/` |
| claude-mem | `search("test", limit=1)` via mcp-search | skip; note it |
| graphify | `<repo>/graphify-out/graph.json` present | grep the repo |

## 2.1 OpenViking — always first, across every participant
For each participant `<proj>` (plus `_global` and the `_features/` vault), call
`memory_recall(query=<necessity keywords + proj>)`. Surface: related **ADRs / decisions**, **existing
feature dossiers** that overlap this necessity, prior **cross-project plans**, past **sessions**, and
**coupling** notes. This is the cheapest layer and covers the whole vault — do it before anything else.

## 2.2 claude-mem — project history
Per participant, `search()` → `timeline()` → `get_observations()` to see how the relevant area evolved
(filter by type / date when it narrows fast). Skip if unavailable; note it.

## 2.3 Existing knowledge to honor
- **`_features/`** — is there already a workspace or dossier for an adjacent feature? Reuse its contracts
  / decisions; don't reinvent the seam.
- **Per-project `conventions.md` / `indications/`** — working rules that constrain each project (they
  override generic defaults).
- **`_global/coupled-groups.md`** — the declared coupling for the participants (already read at intake).
- **Graph** (`graphify query "<question>"`) — for a structural question about an existing seam, prefer
  the graph over grepping source.

## 2.4 Cross-project coupling map
Per participant, note what it already exposes / consumes that this feature touches (endpoints, enums,
shared types). This seeds the **contract critic** in Step 3 and flags where the new plan meets existing
code.

## Required output — the LOAD CONTEXT digest
```
Vaults loaded: [<proj>… + _global + _features]   (OV: <ok|fallback> · claude-mem: <ok|skip>)
Related ADRs / decisions: [...]
Existing features / dossiers: [overlap → reuse, don't reinvent]
Prior cross-project plans: [...]
Conventions / indications that constrain this: [...]
Coupling touchpoints: [per participant]
```
This digest is **passed to every critic in Step 3** (they plan grounded in project knowledge, not blind)
and referenced by the draft. Mark LOAD CONTEXT `completed` → Step 3.
