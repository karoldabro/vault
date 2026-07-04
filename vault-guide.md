---
type: guide
tags: [framework, process, guide]
---

# Vault Guide — How to work with the vault

This is the process doc for any project using the vault framework. It's generic and not tied to one
project. Project-specific overrides live in the repo's `VAULT.md` (§1.1), the project's own `CLAUDE.md`,
or `<project-vault>/conventions.md`.

> **TL;DR**: The vault is Markdown knowledge in a fixed folder layout. Before you write a new doc, search
> for one that already covers it. After real work, capture a session. After a decision, capture an ADR.
> Keep the index files current.

---

## 1. Layer model

There are three layers. Each owns different content, and you shouldn't mix them.

| Layer | Owns | Source of truth | Storage |
|------|------|------|------|
| **Framework** | Process docs, templates, commands. Generic. | `git@github.com:karoldabro/vault.git` | Installed once per machine at `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault/`). Read globally, never copied into a project. |
| **Project** | Features, decisions, sessions, MOC, architecture for one product. Specific. | Per-project vault (global `~/vault/<project>/` or in-repo `<code-repo>/vault/`) | Resolved per command — see §1.1 |
| **Machine** | Local state: coupled-groups, auto-memory dirs, OV index, install config. Not committed. | Local-only | `~/vault/_global/` (incl. `config.md`), `~/vault/<project>/memory/parent`, OV index |

A quick test: if someone cloning your project repo wouldn't need it, it belongs in the machine layer, not
the project.

---

## 1.1 Vault location & config resolution

The framework is one global install, not a submodule. Every command resolves two paths when a run starts.

**Framework path** — `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault`, captured at install time in
`~/vault/_global/config.md`). It holds `vault-guide.md`, `templates/`, `tool-playbook.md`, and the
commands. Any reference to a template or guide resolves under it.

**Vault path** — resolved in order, first hit wins:

1. **`<code-repo>/VAULT.md`** → the `vault_path` key. Relative paths resolve against the repo root, so
   `vault_path: ./vault` keeps the vault inside the repository; an absolute path like `~/vault/givore`
   keeps it global. This is how a repo opts into a non-default location.
2. **`~/vault/_global/config.md`** → `vault_home`, the global default chosen at install.
3. **Built-in default** `~/vault/<slug>/`, with the slug resolved from `coupled-groups.md` or the repo
   basename.

`VAULT.md` (optional, at the repo root; template in `$VAULT_FRAMEWORK_PATH/templates/VAULT.md`) carries
five bounded sections. They're read once at the start of every command (`01-analyze.md` §1.4) and carried
forward through the run, so steps 2–6 don't re-read the file:

| Section | Keys | Effect |
|---------|------|--------|
| `config` | `vault_path`, `framework_path`, `slug` | Path + identity resolution (above). |
| `structure` | `add_folders: [...]`, `rename: {std: alias}`, `optional: [...]` | Scaffold extra folders, alias standard ones locally, silence "missing folder" for optional ones. |
| `behaviour` | `load_context_extra: [...]`, `capture_indications: true\|false`, `suggest_rename: true\|false` | Folders Step 2 loads beyond defaults; whether capture runs the indication scan; whether step 1 suggests a session rename (below). |
| `hooks` | `<phase>: <prose>` | Per-project instruction injected at a lifecycle phase (below). Prose only, never run as a shell command. |
| `tools` | `task_tracker`, `task_tracker_mcp`, `task_tracker_key`, `guidance` | Per-project tool guidance, e.g. which task-tracker MCP this repo uses (Jira, Asana, …) so the lifecycle can fetch ticket context. A suggestion, not a gate. |

Unknown keys are ignored. No `VAULT.md` means all defaults and a global vault.

**Cross-project feature workspaces** live outside any single project vault, in `~/vault/_features/` —
its own committed vault, wired into `/v-sync`. `/v-pm` writes them; per-project `/v-team <feature>`
sessions read them through a `features/<feature>` symlink. Full protocol: §13.

### Lifecycle hooks — phases, precedence & failure modes

A hook attaches a prose instruction to a lifecycle phase. Both `/v-work` and `/v-team` honor them. The
hook is read once at step 1 (§1.4) into the carried config, then surfaced and treated as binding for that
phase. It's instruction-only: the value goes into the agent's prompt and is never run as a shell command.

There are **14 phases** — two global bookends plus a `pre_`/`post_` pair around each machine step:

| Phase | Fires |
|-------|-------|
| `on_start` | Lifecycle begins — first action after config resolution (§1.4), before any step work. |
| `pre_analyze` / `post_analyze` | Around ANALYZE (step 1). |
| `pre_load_context` / `post_load_context` | Around LOAD CONTEXT (step 2). |
| `pre_propose` / `post_propose` | Around PROPOSE (step 3). `post_propose` fires before the approval gate. |
| `pre_execute` / `post_execute` | Around EXECUTE (step 5). `pre_execute` fires after the gate is approved. |
| `pre_commit` / `post_commit` | Around `git commit` (step 6 §5.1). `post_commit` runs after the commit, before `/v-capture`. |
| `pre_capture` / `post_capture` | Around `/v-capture` (step 6 §5.5). |
| `on_end` | Lifecycle ends by any path: success, gate rejection, or abort. |

The APPROVAL GATE (step 4) is not hookable — it's your decision, not a machine phase. In `/v-team`, the
panel and review-loop rounds aren't hookable either: `pre_/post_propose` and `pre_/post_execute` fire at
the loop's outer boundary, not once per critic round.

Precedence and failure modes (the framework never halts):

1. A hook is never run as a shell command. It's prose guidance.
2. On a conflict, `CLAUDE.md` and `indications/` rules win over a hook. Surface the conflict at the
   approval gate instead of quietly obeying the hook.
3. A hook that needs a down MCP: try it, then fall back and say so. Never halt.
4. Malformed or empty hook prose: skip it and note it. Don't fail the run.

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
├── requirements/            # /v-pm business-logic specs — the knowledge center (single-repo). SPEC stage (optional)
│   ├── _index.md
│   └── <slug>.md ...
├── research/                # User research, qual data (optional)
├── serena/                  # Serena memories mountpoint (symlink; .gitignored)
└── sessions/                # Time-bound work logs
    ├── _exploration-plan.md (optional)
    └── YYYY-MM-DD-HHMM-<slug>.md ...
```

An underscore prefix (`_*`) marks a meta, index, or mountpoint file. It always sits at the top of its
folder.

---

## 3. Index files — when to touch

| File | Touched when |
|------|--------------|
| `_moc.md` | New feature, process, architecture, **or requirements** doc appears. New section is added. |
| `_feature-index.md` | A feature row changes (new tables, new pages, new doc). |
| `decisions/_inventory.md` | Every new ADR. Assigns sequential ID. |
| `indications/_index.md` | Every new indication (working rule/pattern/standard). |
| `requirements/_index.md` | Every new `/v-pm` requirements doc (single-repo knowledge center). |
| `_tags.md` | New tag introduced. |

If you skip the index update, the dedupe protocol (§7) won't find your work.

---

## 4. Templates

In `$VAULT_FRAMEWORK_PATH/templates/` (default `~/workspace/vault/templates/`):

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

To use one: copy it, fill in the frontmatter, write the content. Never edit the template itself from
inside a project.

---

## 5. Stub conventions

A stub is a placeholder doc waiting to be filled. You can spot one by any of:

- Frontmatter: `status: stub`
- `<!-- TODO -->` placeholders in the body
- Length under 40 lines of actual content (not counting frontmatter and headings)

When you fill a stub, remove the `status: stub` frontmatter and any `<!-- TODO -->` markers, and overwrite
the stub in place. Don't create a second doc.

To find stubs:

```bash
grep -rilE "status: ?stub|<!-- TODO -->" <project-vault>/
# Or by length:
find <project-vault>/ -name "*.md" \
  | xargs wc -l | awk '$1 < 40 && $2 != "total" { print }'
```

---

## 6. When to save what (decision tree)

Ask what kind of artifact you have:

| Artifact | Goes in | Filename |
|---------|---------|----------|
| Reusable trade-off / chosen approach with rationale | `decisions/` | `ADR-NNN-<slug>.md` |
| Subject-matter knowledge spanning multiple sessions | `features/` (or `architecture/` if system-level) | `<NN>-<slug>.md` or `<slug>.md` |
| Plan-time business-logic **spec** (requirements, rules, glossary) — the knowledge center, written by `/v-pm` | `requirements/` (single-repo) or `_features/<f>/requirements.md` (2+ repos) | `<slug>.md` |
| How to work on **this** project: pattern, coding standard, testing convention, instruction | `indications/` | `<slug>.md` |
| Time-bound work log: what you did, what you learned, what's next | `sessions/` | `YYYY-MM-DD-HHMM-<slug>.md` |
| Repeatable workflow (how-to) | `processes/` | `<slug>.md` |
| Per-machine auto-curated rule | `memory/` (machine layer) | auto-managed |
| Integration guide (cross-project API contract) | `guides/` | `<slug>.md` |

Stuck between session and feature? A session captures *this work*; a feature captures *the topic*. Often
one piece of work produces both: a new or updated feature doc plus the session log.

The four categories that are easy to confuse — `indications/`, `guides/`, `features/`, `requirements/` —
each does a different job:

- **`indications/`** is intra-project: the patterns, standards, and instructions for working on this repo
  ("controllers stay thin", "tests use factories not fixtures", "migrations are reversible"). Read early
  in every `/v-work` run, and grown ADR-style at capture (§7b).
- **`guides/`** is cross-project: the contract one repo publishes so other repos can build against it
  (API endpoints, enums, data flow). Written by `/v-guide`.
- **`features/`** is subject-matter: what a domain does (scope, contracts, coupling, gotchas). The dossier
  for a feature, not the rules for working on the codebase.
- **`requirements/`** is the plan-time **spec** (`/v-pm`): what the product *must* do + why (business
  rules `REQ-NN`, acceptance, glossary) — **aspirational by design**, written before the code. It grounds
  rich tests and AI product understanding. `features/` is its *established* counterpart: after the work
  ships, `/v-team`+`/v-capture` write the built behaviour into the dossier, carrying each `REQ-NN` id.
  Spec (requirements) → established (features) is the lifecycle; don't collapse them.

---

## 7. Duplicate avoidance protocol

Before you write any new doc, run dedupe. Both `/v-work` and `/v-capture` do this for you; do it by hand
for one-off writes.

The steps (OV is the first dedupe layer; grep only after a confirmed `memory_health()` failure):

1. **Extract keywords**: 3–6 short keywords from the intended title or topic.
2. **Grep the vault**:
   ```bash
   for kw in <keywords>; do
     grep -ril "$kw" <project-vault>/{decisions,features,indications,sessions,processes,architecture} 2>/dev/null
   done | sort -u
   ```
3. **Check indexes**: open `_feature-index.md`, `decisions/_inventory.md`, `_moc.md`. Look for a slug or
   topic match.
4. **OV semantic search (required)**: probe `memory_health()`; if it's healthy, call `memory_recall` with
   the topic and read the top 5 results. (OV is a Claude Code MCP plugin — check it through MCP, not
   `curl`.) Grep is the floor, not a substitute: OV catches semantic matches grep misses.
5. **Apply the rule**: if an existing doc covers more than 60% of the topic, update it instead of creating
   a new file.
6. **Naming guards**:
   - ADRs: the next free sequential number from `_inventory.md`.
   - Features in a master domain set: keep the project's `NN-` prefix.
   - Sessions: always `YYYY-MM-DD-HHMM-<slug>.md`, slug ≤6 words, kebab-case.
   - Don't give two docs the same slug across folders.

Running dedupe twice on the same input should give the same result. If a doc is missing from the grep,
the indexes weren't updated; fix that first.

---

## 7b. Growing `indications/` (working rules)

Indications are detected and promoted at capture time, ADR-style — the same mechanism as ADR candidates,
but aimed at how-we-work statements rather than decisions.

1. **Scan** the session and recent conversation for convention-shaped phrasing: `convention:`, `pattern:`,
   `rule:`, `standard`, `always <verb>`, `never <verb>`, `we use .* for`, `prefer .* over`,
   `the .* way is`, and testing-approach statements.
2. **Present** each match as a one-line candidate; you promote the ones worth keeping.
3. **Write** each promoted candidate to `indications/<slug>.md` from `indication.md`, and append a row to
   `indications/_index.md`.

This is gated by `behaviour.capture_indications` in `VAULT.md` (on by default). `/v-work` Step 2 reads
`indications/` first-class, so an existing rule constrains the work instead of being rediscovered.

---

## 8. Cross-linking

- Use relative Obsidian wikilinks: `[[../features/foo]]`, not absolute URLs.
- Every new doc should be back-linked from at least one index (`_moc.md`, `_feature-index.md`, or
  `decisions/_inventory.md`).
- Sessions include a `Refs` section listing every wikilink to related ADRs, features, and prior sessions.
- ADRs link to the features they affect, in a `Cross-repo impact` or `Affects` section.
- Bidirectional links aren't maintained for you. When you add `A → B`, add the reverse too if it carries
  weight.

---

## 9. Keeping the vault current

After `/v-work` finishes (or when you're tidying by hand):

- [ ] New feature/process doc → linked from `_moc.md`?
- [ ] Feature touched → dossier created or updated per the gate (§6 / capture), `_feature-index.md` reconciled?
- [ ] New ADR → appended to `decisions/_inventory.md`?
- [ ] New working rule/pattern surfaced → promoted to `indications/` + `_index.md`?
- [ ] New tag used → registered in `_tags.md`?
- [ ] Stub upgraded → frontmatter `status: stub` removed?
- [ ] Session has its `Refs` section populated?

Every so often (weekly, or per milestone):

- Find stubs older than N days and either promote or delete them.
- `grep -rl "status: stub"` to list them.
- Spot-check `_moc.md` for broken wikilinks. Obsidian's graph view shows dangling links.

---

## 10. Required tools

Vault commands assume these four tools are installed and reachable. Set them up once with `setup.sh` (see
[INSTALL.md](INSTALL.md)).

| Tool | Purpose | Install |
|------|---------|---------|
| **OpenViking** | Long-term semantic memory — vault, ADRs, sessions, pitfalls. MCP: `memory_recall`, `memory_store`, `memory_health`. | `setup.sh --with-ov` |
| **Serena** | Symbol-aware code navigation and refactoring. MCP: `activate_project`, `find_symbol`, `rename`, `replace_symbol_body`. | `setup.sh --with-serena` |
| **MorphLLM Fast Apply** | Bulk multi-file edits at 10k+ tok/sec. MCP: `morph_edit(target_filepath, instructions, code_edit)`. | not auto-installed (paid key): `claude mcp add` — see ADR-005 |
| **claude-mem** | Project history — progressive disclosure search. MCP: `search`, `timeline`, `get_observations`, `memory_store`. | `setup.sh --with-claude-mem` |

### Token-cost hierarchy (cheapest → most expensive)

Work down this list and stop once you have enough context. Each layer costs roughly 10–100× less than the
next.

| Priority | Source | Cost | Use for |
|----------|--------|------|---------|
| 1 | OV `memory_recall` | ~100–2000 tok | Vault decisions, ADRs, past sessions, pitfalls |
| 2 | claude-mem `search` → `timeline` → `get_observations` | ~100→300→1000 tok | Project history, progressive disclosure |
| 3 | Graphify `query` / `path` | ~hundreds tok | **Structural questions** — what calls X, where is Y defined, which modules touch Z. `graph.json` is auto-rebuilt by the post-commit hook (free, no LLM); query it, never grep |
| 4 | Serena `find_symbol`, `get_symbols_overview` | real-time | Semantic code navigation — read a symbol, not the whole file |
| 5 | Grep / Read | ~1000–20k tok | Last resort — only after layers 1–4 come up empty |

Reading 40 source files costs about 20k tokens; a vault hit costs about 100–2000. The wrong default wastes
100×.

So: graph before grep, symbol before full-file read. The graphify graph stays fresh through a per-project
post-commit hook (`graphify hook install`, wired by `/v-init`), so layer 3 is always there at no token
cost. The full rules and copy-paste examples for every tool are in [`tool-playbook.md`](tool-playbook.md).

---

## 11. Commands reference

Installed by `$VAULT_FRAMEWORK_PATH/install.sh` (symlinks into `~/.claude/commands/`). All commands
assume the four tools in §10.

| Command | Purpose | Key tools |
|---------|---------|-----------|
| `/v-init` | Bootstrap a project vault for the current code repo. Creates the vault (global `~/vault/<slug>/` or in-repo with `--in-repo`), writes a repo `VAULT.md`, scaffolds folders + indexes, wires CLAUDE.md. | git |
| `/v-work` | Vault-aware dev lifecycle: load context → propose (with dedupe) → approval → execute → commit + capture. | OV, claude-mem, Serena, MorphLLM |
| `/v-team` | Persona-critique lifecycle for big or high-stakes work. Reuses v-work steps 01/02/05; PROPOSE + EXECUTE run panel loops where project-specific critics (resolved from `VAULT.md` `project_type`/`personas`, then stack auto-detect; defined in `personas/`) review the plan + diff, propose fixes + tests, and loop to convergence. | Agent panel, OV, claude-mem, Serena, MorphLLM |
| `/v-ask` | Light sibling — read-only, vault-aware Q&A. Loads context cheapest-first and answers; no edits, no approval gate, no capture. Hands off to `/v-do` or `/v-work` when the answer implies a change. | OV, claude-mem, graphify, Serena |
| `/v-do` | Light sibling — small low-risk change, no approval gate. Orient (vault-lite) → execute → self-review; capture offered, off by default. Escalates to `/v-work` (scope > ~5 files) or `/v-team` (architecture/schema/auth/billing/cross-repo). | OV, claude-mem, Serena, MorphLLM |
| `/v-capture` | Capture this session as a `sessions/*.md` doc. Runs dedupe, updates indexes, extracts ADR candidates, cross-links Refs, pushes to OV. (claude-mem auto-captures via its SessionEnd hook — no explicit write.) | OV `memory_store`; claude-mem auto-capture (SessionEnd hook) |
| `/v-sync` | Re-ingest a project's curated knowledge into OpenViking after content changes. | OV |
| `/v-link` | Declare two projects as coupled (shared memory recall). Updates `~/vault/_global/coupled-groups.md`. | — |
| `/v-backfill` | Targeted ingest of past Claude Code sessions for a project into OpenViking. | OV |
| `/v-guide` | Generate a cross-project integration guide (API contract, data structures, enums, data flow) from an existing feature. | OV, graphify, MorphLLM |
| `/v-pm` | Cross-project feature planning: a business→product→architect→contract pipeline drafts a shared plan + contract into `_features/`, then per-project `/v-team` sessions coordinate via file threads (§13). | OV, Agent |

Archived commands (`commands/attic/`): `/v-migrate` (one-shot migration finished; `bin/vault-migrate.sh`
remains usable), `/v-resume` (superseded by the OV auto-recall SessionStart hook).

---

## 12. Project-specific overrides

Two layers, checked in order:

1. **`<code-repo>/VAULT.md`** (§1.1) — structured config, machine-read on every command: vault path,
   extra or renamed folders, per-step load hints, capture toggles.
2. **`_moc.md` / `<project-vault>/conventions.md`** — prose conventions the framework can't express as
   config:
   - Feature numbering scheme (e.g. a fixed 20-domain set vs free-form slugs).
   - Sub-repo session prefix (e.g. `api-`, `app-`, `dashboard-` for multi-repo products).
   - Whether `architecture/` or `business/` is used.
   - Extra tags beyond the framework default.

The framework never assumes any of these. Check `VAULT.md`, then the project's own conventions, before
applying them.

### 12.1 `/v-team` panel knobs (settable in `VAULT.md`)

| Knob | Default | Bounds | Governs |
|------|---------|--------|---------|
| `team_max_parallel_critics` | 3 | hard max 5 | Critics per panel round (`personas/_resolution.md` §2) |
| `team_max_rounds` | 2 | hard ceiling | PROPOSE design-loop rounds (`v-team/steps/03-propose-loop.md`) |
| `team_max_review_rounds` | 2 | hard ceiling | EXECUTE diff-review-loop rounds (`v-team/steps/04-execute-loop.md`) |
| `team_max_test_designers` | 3 | — | Test-design generators in PROPOSE sub-phase (f2) |

Unset knobs use the defaults above; a cap hit with open blockers always escalates to the user rather
than silently converging.

---

## 13. Cross-project feature workspaces (`/v-pm`)

`/v-pm` plans a feature **once**, project-agnostically, then lets each project's `/v-team <feature>`
session read that plan and coordinate asynchronously through files — so you stop hand-carrying context
between agent sessions. The substrate is a shared workspace plus a file-based conversation.

### Home & ownership
`~/vault/_features/` is its **own committed vault** (own git, ingested by `/v-sync`) — neutral ground
owned by no single project, since a feature spans several. Each participant project gets a
`features/<feature>` **symlink** into it (gitignored in the project repo; see `templates/vault.gitignore`).

### Layout
```
~/vault/_features/<feature>/
  requirements.md    business knowledge center — what & why (rules REQ-NN, glossary, variant/state tables) — ONLY /v-pm writes it
  generic-plan.md    project-agnostic plan — how/sequencing; its "why" back-refs requirements.md — ONLY /v-pm writes it
  contracts.md       structured cross-project interface (the api↔frontend seam); refs rules by REQ-NN
  header.md          participants · status · created · session_opens counter
  conversation/      threads (state encoded in the filename)
  sessions/          planning-session records — v-pm CAPTURE writes the *why* behind the plan
  decisions/         cross-project ADRs extracted at CAPTURE (promotable to a participant vault)
  projects/<proj>/plan.md   each project's self-contained shard (its own /v-team writes it); its `## Business rules to satisfy` REQ-NN list is v-pm-seeded
```

### Business knowledge center (`requirements.md`) — spec → established lifecycle
`/v-pm` authors a **business-logic / requirements** layer so the necessity is captured once, richly —
the user never repeats themselves, and both humans and AI can reason about the product. It is a **SPEC**
(aspirational by design): business rules as test-shaped `precondition → expected [; edge]` each with a
stable `REQ-NN` id, acceptance criteria, a domain glossary (ubiquitous language), and optional
decision/state tables. This is what grounds **rich tests** (the id chain below) and **AI understanding**.

- **Decoupled from the coordination machinery.** The knowledge center is authored for **any** feature
  (1+ repos). The `_features/` workspace + `conversation/` + `contracts.md` are the **2+-repo** delta.
  - **2+ repos:** `requirements.md` in the neutral `_features/<feature>/` (symlinked into each project).
  - **1 repo:** `<project-vault>/requirements/<feature>.md` — the project's own vault (no cross-repo write).
- **Id-traceability chain** (what makes it *ground* tests, not just describe them):
  `requirements.md` rule `REQ-NN` → `/v-team` LOAD CONTEXT reads it (`00-feature-pickup` §0.2 /
  `02-load-context` `requirements/` glob) → the `(f2)` test-design fan-out echoes `REQ-NN` into the
  Proposed-test-backlog `source` → at capture, the **established** `features/<feature>` dossier
  `## Behaviors & rules` carries the same `REQ-NN`. Spec id survives end-to-end to the built behaviour.
- **Spec vs established.** `requirements/` (or `_features/…/requirements.md`) is aspirational; `features/`
  is what shipped. `/v-team`+`/v-capture` promote only **built** rules into the dossier — the
  `established, not aspirational` rule (`capture-behaviors-test-shaped`) still governs `features/`.
`/v-pm`'s **CAPTURE** step (plan mode step 5; also the tail of `reconcile`) is v-pm's own `/v-capture`:
it writes the planning-session record + extracts cross-project ADR candidates, pushes the rationale to
OpenViking (`memory_store`) so each project's LOAD CONTEXT can recall it, and commits the workspace.

There is **no `ledger.md`** — the ledger is a *derived view* computed from thread filenames on read
(`/v-pm status`, reconcile). Nothing writes it, so parallel sessions never race on it.

### Conversation protocol
A thread is one Markdown file whose **filename carries its state**:

| filename | meaning | who moves it |
|----------|---------|--------------|
| `THREAD_<n>_OPEN_→<proj>.md` | question waiting on project `<proj>` | the asker creates it |
| `THREAD_<n>_OPEN_→pm.md` | decision that changes the generic plan / a contract | drained by `/v-pm reconcile` |
| `THREAD_<n>_ANSWERED_<answerer>.md` | answered; waiting for the asker to consume | the answerer renames |
| `THREAD_<n>_RESOLVED.md` | asker consumed the answer | the asker renames |

Frontmatter carries `from` / `to` / `asks`. Template: `templates/_features/THREAD.md`.

### How it reaches execution — auto-pickup
When `/v-team` runs with a `<feature>` (or finds the `features/<feature>` symlink), its **Step 0**
(`v-team/steps/00-feature-pickup.md`) runs before ANALYZE: it answers / acts threads addressed to this
project, surfaces replies to questions this project asked, and runs a **deterministic** field-by-field
drift check of the project's consumed contract against `contracts.md` (the LLM only phrases the
rationale — it never decides *whether* drift exists). New cross-project doubts mid-session become new
threads instead of a ping to you.

### Latency contract (honest by design)
There is **no live agent-to-agent channel**. A reply surfaces only at the **next open** of the asking
project's session — or immediately via **`/v-pm status`**, the cross-feature inbox that lists every open
thread (by target project and `→pm`) with staleness age. `reconcile` flags any thread left OPEN for more
than N session-opens. Run `/v-pm status` when you want to know what's blocked without opening every repo.

### When to use
Only for a feature spanning **2+ repos worked in separate sessions**. A single-project feature makes
`/v-pm` hand straight off to `/v-team` — the workspace is overhead below that bar.
