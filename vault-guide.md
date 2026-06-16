---
type: guide
tags: [framework, process, guide]
---

# Vault Guide — How to work with the vault

Canonical process doc for any project using the vault framework. Generic and project-agnostic. Project-specific overrides live in the repo's `VAULT.md` (§1.1), the project's own `CLAUDE.md`, or `<project-vault>/conventions.md`.

> **TL;DR**: The vault is markdown-only knowledge organized in a fixed folder layout. Before writing a new doc, search for duplicates. After meaningful work, capture a session. After a decision, capture an ADR. Update indexes when files appear or change.

---

## 1. Layer model

Three layers. Each owns different content. Don't mix.

| Layer | Owns | Source of truth | Storage |
|------|------|------|------|
| **Framework** | Process docs, templates, commands. Generic. | `git@github.com:karoldabro/vault.git` | Installed once per machine at `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault/`). Read globally — **never** vendored into a project. |
| **Project** | Features, decisions, sessions, MOC, architecture for one product. Specific. | Per-project vault (global `~/vault/<project>/` or in-repo `<code-repo>/vault/`) | Resolved per command — see §1.1 |
| **Machine** | Local state: coupled-groups, auto-memory dirs, OV index, install config. Not committed. | Local-only | `~/vault/_global/` (incl. `config.md`), `~/vault/<project>/memory/parent`, OV index |

Rule of thumb: if a teammate cloning your project repo wouldn't need it, it belongs in machine layer, not project.

---

## 1.1 Vault location & config resolution

The framework is a single global install; it is **not** a submodule. Every command resolves two paths
at the start of a run:

**Framework path** — `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault`, captured at install in
`~/vault/_global/config.md`). Holds `vault-guide.md`, `templates/`, `tool-playbook.md`, commands. Any
template or guide reference resolves under it.

**Vault path** — resolved in precedence order (first hit wins):

1. **`<code-repo>/VAULT.md`** → `vault_path` key. Relative paths resolve against the repo root, so
   `vault_path: ./vault` keeps the vault **inside the repository**; an absolute path
   (`~/vault/givore`) keeps it global. This is how a repo opts into a non-default location.
2. **`~/vault/_global/config.md`** → `vault_home` (the global default chosen at install).
3. **Built-in default** `~/vault/<slug>/`, slug resolved from `coupled-groups.md` or the repo basename.

`VAULT.md` (optional, repo root — template in `$VAULT_FRAMEWORK_PATH/templates/VAULT.md`) carries three
bounded sections, read on **every** command and folded into the lifecycle:

| Section | Keys | Effect |
|---------|------|--------|
| `config` | `vault_path`, `framework_path`, `slug` | Path + identity resolution (above). |
| `structure` | `add_folders: [...]`, `rename: {std: alias}`, `optional: [...]` | Scaffold extra folders, alias standard ones locally, silence "missing folder" for optional ones. |
| `behaviour` | `load_context_extra: [...]`, `capture_indications: true\|false` | Folders Step 2 loads beyond defaults; whether capture runs the indication scan. |

Unknown keys are ignored. Absent `VAULT.md` → all defaults, global vault.

---

## 2. Folder map (per-project vault)

```
<project-vault>/
├── _moc.md                  # Map of Contents — entry point, hand-edited
├── _feature-index.md        # Master cross-reference table (optional but recommended)
├── _tags.md                 # Tag registry (optional)
├── architecture/            # System-level design docs
│   └── _overview.md
├── business/                # Strategy, roadmap, competitors (optional)
├── community/               # Off-product channels (optional)
├── decisions/               # ADRs (Architecture Decision Records)
│   ├── _inventory.md
│   ├── README.md
│   └── ADR-001-<slug>.md ...
├── design/                  # Brand, accessibility (optional)
├── features/                # Subject-matter dossiers, one per feature/domain
│   └── <NN>-<slug>.md or <slug>.md
├── graphify/                # Code graph slices (symlinks; .gitignored)
├── guides/                  # Cross-project integration contracts (API shapes, enums, data flow; no impl code)
├── indications/             # How to work ON this project: patterns, standards, testing rules
│   ├── _index.md
│   └── <slug>.md ...
├── legal/                   # Policies, sub-processors (optional)
├── marketing/               # Channels, listings (optional)
├── memory/                  # Auto-memory mountpoint (symlink; .gitignored)
├── operations/              # Runbook, support, vendors (optional)
├── plans/                   # /v-team converged plans + critique trails (opt-in via add_folders)
├── processes/               # Repeatable workflows
├── research/                # User research, qual data (optional)
├── serena/                  # Serena memories mountpoint (symlink; .gitignored)
└── sessions/                # Time-bound work logs
    ├── _exploration-plan.md (optional)
    └── YYYY-MM-DD-HHMM-<slug>.md ...
```

Underscore prefix `_*` = meta / index / mountpoint. Always present at folder top.

---

## 3. Index files — when to touch

| File | Touched when |
|------|--------------|
| `_moc.md` | New feature, process, or architecture doc appears. New section is added. |
| `_feature-index.md` | A feature row changes (new tables, new pages, new doc). |
| `decisions/_inventory.md` | Every new ADR. Assigns sequential ID. |
| `indications/_index.md` | Every new indication (working rule/pattern/standard). |
| `_tags.md` | New tag introduced. |

If you don't update indexes, the dedupe protocol (§7) won't find your work.

---

## 4. Templates

Located in `$VAULT_FRAMEWORK_PATH/templates/` (default `~/workspace/vault/templates/`):

| Template | Use for |
|----------|---------|
| `decision.md` | New ADR. Sequential ID from `_inventory.md`. |
| `feature.md` | New feature dossier. |
| `indication.md` | New working rule / pattern / standard. Catalogued in `indications/_index.md`. |
| `session.md` | New session log. Usually written by `/v-capture`. |
| `plan.md` | `/v-team` converged plan + critique trail + proposed-test backlog. Lives in `plans/`. |
| `project-moc.md` | First-time project setup. |
| `process.md` | Repeatable workflow. |
| `architecture.md` | System-level design doc. |
| `VAULT.md` | Per-repo config (written into the code repo by `/v-init`). |

Instantiate: copy template, fill frontmatter, write content. Never edit the template itself from a project.

---

## 5. Stub conventions

A **stub** is a placeholder doc waiting to be filled. Identify by either:

- Frontmatter: `status: stub`
- Body contains `<!-- TODO -->` placeholders
- File length: `<40` lines of actual content (excluding frontmatter and headings)

Upgrade rule: when filling a stub, **remove** the `status: stub` frontmatter and any `<!-- TODO -->` markers. Don't create a new doc — overwrite the stub in place.

To find stubs:

```bash
grep -rilE "status: ?stub|<!-- TODO -->" <project-vault>/
# Or by length:
find <project-vault>/ -name "*.md" \
  | xargs wc -l | awk '$1 < 40 && $2 != "total" { print }'
```

---

## 6. When to save what (decision tree)

Ask: **what kind of artifact is this?**

| Artifact | Goes in | Filename |
|---------|---------|----------|
| Reusable trade-off / chosen approach with rationale | `decisions/` | `ADR-NNN-<slug>.md` |
| Subject-matter knowledge spanning multiple sessions | `features/` (or `architecture/` if system-level) | `<NN>-<slug>.md` or `<slug>.md` |
| How to work on **this** project: pattern, coding standard, testing convention, instruction | `indications/` | `<slug>.md` |
| Time-bound work log: what you did, what you learned, what's next | `sessions/` | `YYYY-MM-DD-HHMM-<slug>.md` |
| Repeatable workflow (how-to) | `processes/` | `<slug>.md` |
| Per-machine auto-curated rule | `memory/` (machine layer) | auto-managed |
| Integration guide (cross-project API contract) | `guides/` | `<slug>.md` |

If unsure between session and feature: session captures **this work**; feature captures **the topic**. Often a session leads to a new/updated feature doc plus the session log itself.

**`indications/` vs `guides/` vs `features/`** — easy to confuse, different jobs:

- **`indications/`** is *intra-project*: the patterns, standards, and instructions for working **on this
  repo** ("controllers stay thin", "tests use factories not fixtures", "migrations are reversible"). Read
  early in every `/v-work` run; grown ADR-style at capture (§7b).
- **`guides/`** is *cross-project*: the external contract one repo publishes so **other** repos can build
  against it (API endpoints, enums, data flow). Written by `/v-guide`.
- **`features/`** is *subject-matter*: what a domain **does** (scope, contracts, coupling, gotchas) — the
  dossier for a feature, not the rules for working on the codebase.

---

## 7. Duplicate avoidance protocol

**Before writing any new doc, run dedupe.** Both `/v-work` and `/v-capture` invoke this automatically; do it manually for ad-hoc writes.

Steps (OV is the first dedupe layer — grep only after a confirmed `memory_health()` failure):

1. **Extract keywords**: 3–6 short keywords from the intended title/topic.
2. **Grep the vault**:
   ```bash
   for kw in <keywords>; do
     grep -ril "$kw" <project-vault>/{decisions,features,indications,sessions,processes,architecture} 2>/dev/null
   done | sort -u
   ```
3. **Check indexes**: open `_feature-index.md`, `decisions/_inventory.md`, `_moc.md`. Look for slug or topic match.
4. **OV semantic search (required)**: probe `memory_health()`; if healthy, call `memory_recall` with the topic and read top 5 results. (OV is a Claude Code MCP plugin — reachability is probed via MCP, not `curl`.) Grep (step 2) is the floor, not a substitute — OV catches semantic matches grep misses.
5. **Apply rule**: if any existing doc covers `>60%` of the topic → **update existing**, do not create a new file.
6. **Naming guards**:
   - ADRs: next free sequential number from `_inventory.md`.
   - Features in a master domain set: keep the project's `NN-` prefix.
   - Sessions: always `YYYY-MM-DD-HHMM-<slug>.md`, slug ≤6 words kebab-case.
   - Avoid two docs with the same slug across folders.

Re-running dedupe on the same input should produce stable results. If a doc is missing from the grep, the indexes were not updated — fix that first.

---

## 7b. Growing `indications/` (working rules)

Indications are detected and promoted ADR-style, at capture time — the same mechanism as ADR candidates,
aimed at *how-we-work* statements instead of decisions.

1. **Scan** the session + recent conversation for convention-shaped phrasing: `convention:`, `pattern:`,
   `rule:`, `standard`, `always <verb>`, `never <verb>`, `we use .* for`, `prefer .* over`,
   `the .* way is`, testing-approach statements.
2. **Present** each match as a one-line candidate; the user promotes the ones worth keeping.
3. **Write** each promoted candidate to `indications/<slug>.md` from `indication.md`, append a row to
   `indications/_index.md`.

Gated by `behaviour.capture_indications` in `VAULT.md` (default on). `/v-work` Step 2 reads `indications/`
first-class so an existing rule constrains the work instead of being rediscovered.

---

## 8. Cross-linking

- Use **relative Obsidian wikilinks**: `[[../features/foo]]`, not absolute URLs.
- **Every new doc** must be back-linked from at least one index (`_moc.md`, `_feature-index.md`, or `decisions/_inventory.md`).
- **Sessions** include a `Refs` section listing every wikilink to related ADRs, features, prior sessions.
- **ADRs** link to the features they affect, in a `Cross-repo impact` or `Affects` section.
- Bidirectional links are not auto-maintained. When you add `A → B`, also add the reverse if it's load-bearing.

---

## 9. Keeping the vault current

Post-work checklist (after `/v-work` finishes, or manually):

- [ ] New feature/process doc → linked from `_moc.md`?
- [ ] Feature touched → dossier **created or updated** per the gate (§6 / capture), `_feature-index.md` reconciled?
- [ ] New ADR → appended to `decisions/_inventory.md`?
- [ ] New working rule/pattern surfaced → promoted to `indications/` + `_index.md`?
- [ ] New tag used → registered in `_tags.md`?
- [ ] Stub upgraded → frontmatter `status: stub` removed?
- [ ] Session has `Refs` section populated?

Periodic hygiene (weekly or per-milestone):

- Find stubs older than N days; promote or delete.
- `grep -rl "status: stub"` to enumerate.
- Spot-check `_moc.md` for broken wikilinks: in Obsidian, the graph view surfaces dangling links.

---

## 10. Required tools

All vault commands assume these four tools are installed and reachable. Set them up once with `setup.sh`.

| Tool | Purpose | Install |
|------|---------|---------|
| **OpenViking** | Long-term semantic memory — vault, ADRs, sessions, pitfalls. MCP: `memory_recall`, `memory_store`, `memory_health`. | `setup.sh --with-ov` |
| **Serena** | Symbol-aware code navigation and refactoring. MCP: `activate_project`, `find_symbol`, `rename`, `replace_symbol_body`. | `uv tool install serena-agent@latest --prerelease=allow` |
| **MorphLLM Fast Apply** | Bulk multi-file edits at 10k+ tok/sec. MCP: `morph_edit(target_filepath, instructions, code_edit)`. | `setup.sh --with-morph` |
| **claude-mem** | Project history — progressive disclosure search. MCP: `search`, `timeline`, `get_observations`, `memory_store`. | `setup.sh --with-claude-mem` |

### Token-cost hierarchy (cheapest → most expensive)

Use in order. Stop when you have enough context. Each layer costs 10–100× less than the next.

| Priority | Source | Cost | Use for |
|----------|--------|------|---------|
| 1 | OV `memory_recall` | ~100–2000 tok | Vault decisions, ADRs, past sessions, pitfalls |
| 2 | claude-mem `search` → `timeline` → `get_observations` | ~100→300→1000 tok | Project history, progressive disclosure |
| 3 | Graphify `query` / `path` | ~hundreds tok | **Structural questions** — what calls X, where is Y defined, which modules touch Z. `graph.json` is auto-rebuilt by the post-commit hook (free, no LLM); query it, never grep |
| 4 | Serena `find_symbol`, `get_symbols_overview` | real-time | Semantic code navigation — read a symbol, not the whole file |
| 5 | Grep / Read | ~1000–20k tok | Last resort — only after layers 1–4 come up empty |

Reading 40 source files costs ~20k tokens. A vault hit costs ~100–2000. Wrong default wastes 100×.

**Graph before grep, symbol before full-file read.** The graphify graph stays fresh via a per-project
post-commit hook (`graphify hook install`, wired by `/v-init`) — so layer 3 is always available at no
token cost. Full rules + copy-paste examples for every tool: [`tool-playbook.md`](tool-playbook.md).

---

## 11. Commands reference

Installed by `$VAULT_FRAMEWORK_PATH/install.sh` (symlinks to `~/.claude/commands/`).

All commands require the four tools listed in §10.

| Command | Purpose | Key tools |
|---------|---------|-----------|
| `/v-init` | Bootstrap a project vault for the current code repo. Creates the vault (global `~/vault/<slug>/` or in-repo with `--in-repo`), writes a repo `VAULT.md`, scaffolds folders + indexes, wires CLAUDE.md. | git |
| `/v-migrate` | Convert an existing submodule-based vault to the global model: de-init the `_process/` submodule, write `VAULT.md`, repoint the MOC. | git |
| `/v-work` | Vault-aware dev lifecycle: load context → propose (with dedupe) → approval → execute → commit + capture. | OV, claude-mem, Serena, MorphLLM |
| `/v-team` | Persona-critique lifecycle for BIG/high-stakes work. Reuses v-work steps 01/02/05; PROPOSE + EXECUTE run panel loops where project-specific critics (resolved from `VAULT.md` `project_type`/`personas` then stack auto-detect; defined in `personas/`) review the plan + diff, propose fixes + tests, and loop to convergence. | Agent panel, OV, claude-mem, Serena, MorphLLM |
| `/v-capture` | Capture this session as a `sessions/*.md` doc. Runs dedupe, updates indexes, extracts ADR candidates, cross-links Refs, pushes to OV. (claude-mem auto-captures via its SessionEnd hook — no explicit write.) | OV `memory_store`; claude-mem auto-capture (SessionEnd hook) |
| `/v-resume` | Force fresh context recall from vault + OpenViking + claude-mem. Arg: topic, project slug, or `all`. | OV `memory_recall`, claude-mem `search` |
| `/v-sync` | Re-ingest a project's curated knowledge into OpenViking after content changes. | OV |
| `/v-link` | Declare two projects as coupled (shared memory recall). Updates `~/vault/_global/coupled-groups.md`. | — |
| `/v-backfill` | Targeted ingest of past Claude Code sessions for a project into OpenViking. | OV |
| `/v-guide` | Generate a cross-project integration guide (API contract, data structures, enums, data flow) from an existing feature. | OV, graphify, MorphLLM |

---

## 12. Project-specific overrides

Two layers, checked in order:

1. **`<code-repo>/VAULT.md`** (§1.1) — structured, machine-read on every command: vault path, extra/renamed
   folders, per-step load hints, capture toggles.
2. **`_moc.md` / `<project-vault>/conventions.md`** — prose conventions the framework can't express as
   config:
   - Feature numbering scheme (e.g. fixed 20-domain set vs free-form slugs).
   - Sub-repo session prefix (e.g. `api-`, `app-`, `dashboard-` for multi-repo products).
   - Whether `architecture/` or `business/` is used.
   - Additional tags beyond the framework default.

The framework never assumes these; check `VAULT.md` then the project's own conventions before applying.
