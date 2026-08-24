---
type: guide
tags: [framework, process, guide]
---

# Vault Guide — How to work with the vault

This is the process document for any project using the vault framework. It is generic and tied to no
single project. A repo overrides parts of it in its own `VAULT.md` (§1.1), its `CLAUDE.md`, or
`<project-vault>/conventions.md`.

The vault is Markdown knowledge in a fixed folder layout. Search for an existing document before you
write a new one. Capture a session after real work and an ADR after a decision, and keep the index files
current.

---

## 1. Layer model

Three layers each own different content. Never mix them.

| Layer | Owns | Source of truth | Storage |
|------|------|------|------|
| **Framework** | Process docs, templates, commands. Generic. | `git@github.com:karoldabro/vault.git` | Installed once per machine at `$VAULT_FRAMEWORK_PATH` — a Claude Code plugin cache dir, or a git clone (default `~/workspace/vault/`). Read globally, never copied into a project. |
| **Project** | Features, decisions, sessions, MOC, architecture for one product. Specific. | Per-project vault (global `~/vault/<project>/` or in-repo `<code-repo>/vault/`) | Resolved per command — see §1.1 |
| **Machine** | Local state: coupled-groups, auto-memory dirs, install config. Not committed. | Local-only | `~/vault/_global/` (incl. `config.md`), `~/vault/<project>/memory/parent` |

**How to tell the project layer from the machine layer:** content that someone cloning your project repo
would not need belongs to the machine layer.

---

## 1.1 Vault location & config resolution

The framework is one global install, never a submodule. Every command resolves two paths when a run
starts.

**Framework path** — `$VAULT_FRAMEWORK_PATH`. It holds `vault-guide.md`, `templates/`,
`tool-playbook.md`, `personas/`, `lib/`, `bin/`, and the commands. Every reference to a template or a
guide resolves under it. Resolved in order, first hit wins:

1. **`${CLAUDE_PLUGIN_ROOT}`**, when a command file's text shows it as an absolute path. Claude Code
   substituted the placeholder at load time, so the framework is installed as a plugin. It wins because
   it is the only value guaranteed to match the files currently running.
2. **`<code-repo>/VAULT.md`** → the `framework_path` key.
3. **`~/vault/_global/config.md`** → `framework_path`, captured at install time by `setup.sh`.
4. **Built-in default** `~/workspace/vault`.

Under a plugin install the path is a versioned cache directory that every plugin update changes, so
nothing writes it to `config.md` or to any `VAULT.md`. Under a symlink install (`install.sh`) it is a
stable clone path and `config.md` is authoritative. The two install modes exclude each other — see
`INSTALL.md`.

**Vault path** — resolved in order, first hit wins:

1. **`<code-repo>/VAULT.md`** → the `vault_path` key. Relative paths resolve against the repo root, so
   `vault_path: ./vault` keeps the vault inside the repository; an absolute path such as `~/vault/givore`
   keeps it global. This is how a repo opts into a non-default location.
2. **`~/vault/_global/config.md`** → `vault_home`, the global default chosen at install.
3. **Built-in default** `~/vault/<slug>/`, with the slug resolved from `coupled-groups.md` or the repo
   basename.

`VAULT.md` is optional and sits at the repo root; the template is
`$VAULT_FRAMEWORK_PATH/templates/VAULT.md`. It carries five bounded sections. Every command reads them
once at its start (`01-analyze.md` §1.4) and carries them forward, so steps 2 to 6 never re-read the
file:

| Section | Keys | Effect |
|---------|------|--------|
| `config` | `vault_path`, `framework_path`, `slug` | Path + identity resolution (above). |
| `structure` | `add_folders: [...]`, `rename: {std: alias}`, `optional: [...]` | Scaffold extra folders, alias standard ones locally, silence "missing folder" for optional ones. |
| `behaviour` | `load_context_extra: [...]`, `capture_indications: true\|false`, `suggest_rename: true\|false`, `vault_autosync: true\|false` | Folders Step 2 loads beyond defaults; whether capture runs the indication scan; whether step 1 suggests a session rename (below); whether an out-of-repo vault is pulled and pushed automatically (below). |
| `hooks` | `<phase>: <prose>` | Per-project instruction injected at a lifecycle phase (below). Prose only, never run as a shell command. |
| `tools` | `task_tracker`, `task_tracker_mcp`, `task_tracker_key`, `guidance` | Per-project tool guidance, such as which task-tracker MCP this repo uses (Jira, Asana), so the lifecycle can fetch ticket context. A suggestion, not a gate. |

Commands ignore unknown keys. A repo with no `VAULT.md` gets every default and a global vault.

**Cross-project feature workspaces** live outside any single project vault, in `~/vault/_features/`,
which is its own committed vault. `/v-pm` writes them; a per-project `/v-team <feature>` session reads
them through a `features/<feature>` symlink. Full protocol: §13.

### Vault git sync — out-of-repo vaults

A vault under `~/vault/<slug>/` sits outside the code repo's commits. Left alone it is committed only
when someone remembers and pushed only by hand. So every v-* command that reads or writes a vault routes
git through `$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh` and **never through raw `git`**:

```bash
vault-sync.sh pull <vault>                        # before reading vault context
vault-sync.sh push <vault> -m "<subject>" [paths] # after the vault writes land
```

Exit codes, all non-fatal: `0` synced · `1` a git operation failed, and a conflicting rebase is aborted
with the worktree left clean · `3` not a git repo, noted once, and `git init` never runs for the user ·
`4` the vault lives inside the code repo, so the code commit covers it and sync skips silently ·
`5` no upstream, so `push` committed locally and said so.

**A sync failure never halts a lifecycle and never blocks a capture.** You can recover knowledge that
was written but not pushed; you cannot recover knowledge never written. `/v-ask` is excluded from sync
entirely, because it promises no git write and a pull rewrites the worktree.
`behaviour.vault_autosync` governs it, defaulting to on and falling back to `vault_autosync` in
`~/vault/_global/config.md`. Full contract:
`$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`.

### Lifecycle hooks — phases, precedence & failure modes

A hook attaches a prose instruction to a lifecycle phase. Both `/v-work` and `/v-team` honor them. The
command reads the hook once at step 1 (§1.4) into the carried config, then surfaces it and treats it as
binding for that phase. The value goes into the agent's prompt and is **never run as a shell command**.

There are **14 phases**: two global bookends plus a `pre_`/`post_` pair around each machine step.

| Phase | Fires |
|-------|-------|
| `on_start` | Lifecycle begins — first action after config resolution (§1.4), before any step work. |
| `pre_analyze` / `post_analyze` | Around ANALYZE (step 1). |
| `pre_load_context` / `post_load_context` | Around LOAD CONTEXT (step 2). |
| `pre_propose` / `post_propose` | Around PROPOSE (step 3). `post_propose` fires before the approval gate. |
| `pre_execute` / `post_execute` | Around EXECUTE (step 5). `pre_execute` fires after the gate is approved. |
| `pre_commit` / `post_commit` | Around `git commit` (step 6 §5.1). `post_commit` runs after the commit, before `/v-capture`. |
| `pre_capture` / `post_capture` | Around `/v-capture` (step 6 §5.4). |
| `on_end` | Lifecycle ends by any path: success, gate rejection, or abort. |

The APPROVAL GATE (step 4) takes no hook, because it is your decision rather than a machine phase. In
`/v-team` the panel rounds and the review-loop rounds take no hook either: `pre_/post_propose` and
`pre_/post_execute` fire at the loop's outer boundary, not once per critic round.

Precedence and failure modes — the framework never halts:

1. A hook never runs as a shell command. It is prose guidance.
2. On a conflict, `CLAUDE.md` and `indications/` rules beat a hook. Surface the conflict at the approval
   gate rather than quietly obeying the hook.
3. A hook needing a down MCP: try it, fall back, and say so. Never halt.
4. Malformed or empty hook prose: skip it and note it. Do not fail the run.

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
├── plans/                   # /v-team plans + their .trail.md sidecars (opt-in via add_folders)
├── processes/               # Repeatable workflows
├── requirements/            # /v-pm business-logic specs — the knowledge center (single-repo). SPEC stage (optional)
│   ├── _index.md
│   └── <slug>.md ...
├── research/                # User research, qual data, secondary/literature research (optional)
├── serena/                  # Serena memories mountpoint (symlink; .gitignored)
└── sessions/                # Time-bound work logs
    ├── _exploration-plan.md (optional)
    └── YYYY-MM-DD-HHMM-<slug>.md ...
```

An underscore prefix (`_*`) marks a meta, index, or mountpoint file, and always sorts to the top of its
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

Skip an index update and the duplicate check (§7) will not find your work.

---

## 4. Templates

They live in `$VAULT_FRAMEWORK_PATH/templates/`, by default `~/workspace/vault/templates/`.

| Template | Use for |
|----------|---------|
| `decision.md` | New ADR. Sequential ID from `_inventory.md`. |
| `feature.md` | New feature dossier. |
| `indication.md` | New working rule / pattern / standard. Catalogued in `indications/_index.md`. |
| `session.md` | New session log. Usually written by `/v-capture`. |
| `plan.md` | `/v-team` converged plan + work items + test backlog. Current truth only; lives in `plans/`. |
| `trail.md` | The plan's process record — findings, rejected options, `per-round metrics`. Sibling `plans/<slug>.trail.md`, named by the plan's `process_record` key. |
| `project-moc.md` | First-time project setup. |
| `process.md` | Repeatable workflow. |
| `architecture.md` | System-level design doc. |
| `VAULT.md` | Per-repo config (written into the code repo by `/v-init`). |

Copy the template, fill in the frontmatter, write the content. Never edit a template from inside a
project.

---

## 5. Stub conventions

A stub is a placeholder document waiting to be filled. A document is a stub if it carries any of:

- Frontmatter `status: stub`
- `<!-- TODO -->` placeholders in the body
- Under 40 lines of actual content, counting neither frontmatter nor headings

When you fill a stub, remove the `status: stub` frontmatter and every `<!-- TODO -->` marker, and
overwrite the stub in place. Never create a second document.

Find stubs with:

```bash
grep -rilE "status: ?stub|<!-- TODO -->" <project-vault>/
# Or by length:
find <project-vault>/ -name "*.md" \
  | xargs wc -l | awk '$1 < 40 && $2 != "total" { print }'
```

---

## 6. When to save what (decision tree)

Decide by the kind of artifact you hold.

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

**Session or feature:** a session captures *this work*; a feature captures *the topic*. One piece of work
often produces both, a new or updated feature dossier plus the session log.

Four folders are easy to confuse, and each does a different job:

- **`indications/`** is intra-project: the patterns, standards, and instructions for working on this repo
  ("controllers stay thin", "tests use factories not fixtures", "migrations are reversible"). Every
  `/v-work` run reads it early, and capture grows it ADR-style (§7b).
- **`guides/`** is cross-project: the contract one repo publishes so other repos can build against it
  (API endpoints, enums, data flow). `/v-guide` writes it.
- **`features/`** is subject-matter: what a domain does — scope, contracts, coupling, gotchas. It is the
  dossier for a feature, not the rules for working on the codebase.
- **`requirements/`** is the plan-time **spec** that `/v-pm` writes: what the product must do and why,
  as business rules `REQ-NN`, acceptance criteria and a glossary. It is **aspirational by design** and
  written before the code, and it grounds rich tests and AI product understanding. `features/` is its
  *established* counterpart: once the work ships, `/v-team` and `/v-capture` write the built behaviour
  into the dossier carrying each `REQ-NN` id. Spec (requirements) becomes established (features); never
  collapse the two.

---

## 7. Duplicate avoidance protocol

Run this check before writing any new document. `/v-work` and `/v-capture` run it for you; run it by
hand for a one-off write.

Grep over the vault is the floor, and claude-mem adds semantic reach when installed.

1. **Extract keywords**: 3 to 6 short keywords from the intended title or topic.
2. **Grep the vault**:
   ```bash
   for kw in <keywords>; do
     grep -ril "$kw" <project-vault>/{decisions,features,indications,sessions,processes,architecture} 2>/dev/null
   done | sort -u
   ```
3. **Check indexes**: open `_feature-index.md`, `decisions/_inventory.md`, `_moc.md`, and look for a slug
   or topic match.
4. **Search claude-mem when it is installed**: run `search(<topic>)` and read the top 5 hits. It catches
   semantic matches grep misses. Not installed → say so once; the grep in step 2 stands on its own.
5. **Apply the rule**: when an existing document covers more than 60% of the topic, update it instead of
   creating a new file.
6. **Naming guards**:
   - ADRs take the next free sequential number from `_inventory.md`.
   - Features in a master domain set keep the project's `NN-` prefix.
   - Sessions are always `YYYY-MM-DD-HHMM-<slug>.md`, slug at most 6 words, kebab-case.
   - No two documents share a slug across folders.

The check is deterministic: the same input gives the same result. A document missing from the grep means
the indexes were not updated; fix that first.

---

## 7b. Growing `indications/` (working rules)

Capture detects and promotes indications ADR-style, by the same mechanism as ADR candidates, aimed at
how-we-work statements rather than decisions.

1. **Scan** the session and recent conversation for convention-shaped phrasing: `convention:`, `pattern:`,
   `rule:`, `standard`, `always <verb>`, `never <verb>`, `we use .* for`, `prefer .* over`,
   `the .* way is`, and testing-approach statements.
2. **Present** each match as a one-line candidate; you promote the ones worth keeping.
3. **Write** each promoted candidate to `indications/<slug>.md` from `indication.md`, and append a row to
   `indications/_index.md`.

`behaviour.capture_indications` in `VAULT.md` gates this, and defaults to on. `/v-work` Step 2 reads
`indications/` first-class, so an existing rule constrains the work instead of being rediscovered.

---

## 8. Cross-linking

- Use relative Obsidian wikilinks: `[[../features/foo]]`, never absolute URLs.
- Back-link every new document from at least one index: `_moc.md`, `_feature-index.md`, or
  `decisions/_inventory.md`.
- Sessions carry a `Refs` section listing every wikilink to related ADRs, features, and prior sessions.
- ADRs link to the features they affect, in a `Cross-repo impact` or `Affects` section.
- Nothing maintains bidirectional links for you. When you add `A → B`, add the reverse yourself if it
  carries weight.

---

## 9. Keeping the vault current

Check this list after `/v-work` finishes, or when you tidy by hand:

- [ ] New feature/process doc → linked from `_moc.md`?
- [ ] Feature touched → dossier created or updated per the gate (§6 / capture), `_feature-index.md` reconciled?
- [ ] New ADR → appended to `decisions/_inventory.md`?
- [ ] New working rule/pattern surfaced → promoted to `indications/` + `_index.md`?
- [ ] New tag used → registered in `_tags.md`?
- [ ] Stub upgraded → frontmatter `status: stub` removed?
- [ ] Session has its `Refs` section populated?

Weekly, or once per milestone:

- Find stubs older than N days and either promote or delete them.
- List them with `grep -rl "status: stub"`.
- Spot-check `_moc.md` for broken wikilinks. Obsidian's graph view shows dangling links.

---

## 10. Required tools

Vault commands prefer these tools and fall back cleanly when one is missing. `setup.sh` sets them up
once — see [INSTALL.md](INSTALL.md). The floor under all of them is grep over the vault markdown, which
needs nothing installed.

| Tool | Purpose | Install |
|------|---------|---------|
| **Serena** | Symbol-aware code navigation and refactoring. MCP: `activate_project`, `find_symbol`, `rename`, `replace_symbol_body`. | `setup.sh --with-serena` |
| **MorphLLM Fast Apply** | Bulk multi-file edits at 10k+ tok/sec. MCP: `morph_edit(target_filepath, instructions, code_edit)`. | not auto-installed (paid key): `claude mcp add` — see ADR-005 |
| **claude-mem** | Project history — progressive disclosure search. MCP: `search`, `timeline`, `get_observations`. Read-only; it auto-captures via its SessionEnd hook. | `setup.sh --with-claude-mem` |

### Token-cost hierarchy (cheapest → most expensive)

Work down this list and stop once you have enough context. Each layer costs roughly 10 to 100 times less
than the next.

| Priority | Source | Cost | Use for |
|----------|--------|------|---------|
| 1 | claude-mem `search` → `timeline` → `get_observations` | ~100→300→1000 tok | Project history, progressive disclosure |
| 2 | Graphify `query` / `path` | ~hundreds tok | **Structural questions** — what calls X, where is Y defined, which modules touch Z. The post-commit hook rebuilds `graph.json` free of LLM cost; query it, never grep |
| 3 | Serena `find_symbol`, `get_symbols_overview` | real-time | Semantic code navigation — read a symbol, not the whole file |
| 4 | Grep over `~/vault/` | ~100–2000 tok | Vault decisions, ADRs, past sessions, pitfalls. Also the standing substitute for layer 1 when claude-mem is absent |
| 5 | Grep / Read over source | ~1000–20k tok | Last resort — only after layers 1–4 come up empty |

Reading 40 source files costs about 20k tokens and a vault hit costs about 100 to 2000, so the wrong
default wastes 100 times the tokens. Query the graph before you grep, and read a symbol before you read
a whole file.

The graph stays fresh through a per-project post-commit hook (`graphify hook install`, wired by
`/v-init`), so layer 2 is always available at no token cost. [`tool-playbook.md`](tool-playbook.md)
carries the full rules and copy-paste examples for every tool.

---

## 11. Commands reference

Commands arrive either as a Claude Code plugin (`/plugin marketplace add karoldabro/vault`, then
`/plugin install vault@kdabro-vault`) or from `$VAULT_FRAMEWORK_PATH/install.sh`, which symlinks
`commands/` into `~/.claude/commands/` and `output-styles/` into `~/.claude/output-styles/`. Pick one
mode; running both installs every command twice. All commands assume the tools in §10.

**How every command writes to you.** `commands/_shared/communication.md` is a shared module bound at the
top of each command and each step file that owns a `## Required output` block. It governs user-facing
prose only: answer first, no jargon, options carry their consequences, report exceptions rather than
normality, and cap what you read at an approval gate at about 15 lines with the design detail kept in the
artifact. Machine-read schemas, vault documents, commit messages and the model's reasoning fall outside
it, and forge comments defer to `/v-cr`'s own rule because they have a different reader. The decision
record behind it is [[ADR-018-decision-communication-contract]] in `vault/decisions/`.

**Optional global style.** `output-styles/director.md` applies the same rules to *every* Claude Code
session, including work that never runs a v-* command. Turn it on with `/config` → Output style →
*director*, or set `"outputStyle": "director"` in `~/.claude/settings.json`; it takes effect after
`/clear` or in a new session. It is deliberately self-contained, because an output style cannot read repo
files. It reaches the main conversation only and never a spawned subagent;
`v-team/steps/03-propose-loop.md` §(e).7 caps subagent-authored text instead.

| Command | Purpose | Key tools |
|---------|---------|-----------|
| `/v-setup` | Install or repair the machine-level stack — base prerequisites, `~/vault/_global/`, and the optional tools. Wraps `setup.sh`, shows what it will run, and asks first. Run once per machine; `--doctor` checks without changing anything. | — |
| `/v-init` | Bootstrap a project vault for the current code repo. Creates the vault (global `~/vault/<slug>/` or in-repo with `--in-repo`), writes a repo `VAULT.md`, scaffolds folders + indexes, wires CLAUDE.md. | git |
| `/v-work` | Vault-aware dev lifecycle: load context → propose (with the duplicate check) → approval → execute → commit + capture. | claude-mem, Serena, MorphLLM |
| `/v-team` | Persona-critique lifecycle for big or high-stakes work. Reuses v-work steps 01/02/05; PROPOSE + EXECUTE run panel loops where project-specific critics (resolved from `VAULT.md` `project_type`/`personas`, then stack auto-detect; defined in `personas/`) review the plan + diff, propose fixes + tests, and loop to convergence. | Agent panel, claude-mem, Serena, MorphLLM |
| `/v-ask` | Light sibling — read-only, vault-aware Q&A. Loads context cheapest-first and answers; no edits, no approval gate, no capture. Hands off to `/v-do` or `/v-work` when the answer implies a change. | claude-mem, graphify, Serena |
| `/v-do` | Light sibling — small low-risk change, no approval gate. Orient (vault-lite) → execute → self-review; capture offered, off by default. Escalates to `/v-work` (scope > ~5 files) or `/v-team` (architecture/schema/auth/billing/cross-repo). | claude-mem, Serena, MorphLLM |
| `/v-capture` | Capture this session as a `sessions/*.md` doc. Runs the duplicate check, updates indexes, extracts ADR candidates, cross-links Refs. claude-mem auto-captures via its SessionEnd hook, so nothing writes to it explicitly. | claude-mem auto-capture (SessionEnd hook) |
| `/v-link` | Declare two projects as coupled, so context loading sweeps both. Updates `~/vault/_global/coupled-groups.md`. | — |
| `/v-guide` | Generate a cross-project integration guide (API contract, data structures, enums, data flow) from an existing feature. | claude-mem, graphify, MorphLLM |
| `/v-reconcile` | Bring an existing document up to `_shared/document-standard.md`: load context, extract the load-bearing set, split the record out to a sidecar, rewrite, then prove with `doc-lint --compare` that no constraint was dropped. Approval-gated per file. | claude-mem, graphify, `bin/doc-lint.sh` |
| `/v-pm` | Cross-project feature planning: a business→product→architect→contract pipeline drafts a shared plan + contract into `_features/`, then per-project `/v-team` sessions coordinate via file threads (§13). | Agent |

`attic/` holds `/v-migrate`, whose one-shot migration finished; `bin/vault-migrate.sh` still works.

**OpenViking is no longer a dependency.** `/v-sync` and `/v-backfill` existed only to feed it and are
gone with it. To take an older install off a machine, see
[docs/removing-openviking.md](docs/removing-openviking.md).

---

## 12. Project-specific overrides

Two layers, checked in order:

1. **`<code-repo>/VAULT.md`** (§1.1) — structured config, machine-read on every command: vault path,
   extra or renamed folders, per-step load hints, capture toggles.
2. **`_moc.md` / `<project-vault>/conventions.md`** — prose conventions that config cannot express:
   - Feature numbering scheme, such as a fixed 20-domain set against free-form slugs.
   - Sub-repo session prefix, such as `api-`, `app-`, `dashboard-` for a multi-repo product.
   - Whether the project uses `architecture/` or `business/`.
   - Extra tags beyond the framework default.

The framework assumes none of these. Read `VAULT.md`, then the project's own conventions, before
applying them.

### 12.1 `/v-team` panel knobs (settable in `VAULT.md`)

| Knob | Default | Bounds | Governs |
|------|---------|--------|---------|
| `team_max_parallel_critics` | 3 (business packs 4) | hard max 5 | Critics per panel round (`personas/_resolution.md` §2, business selection §2.2) |
| `team_max_rounds` | 2 | hard ceiling | PROPOSE design-loop rounds (`v-team/steps/03-propose-loop.md`) |
| `team_max_review_rounds` | 2 | hard ceiling | EXECUTE diff-review-loop rounds (`v-team/steps/04-execute-loop.md`) |
| `team_max_test_designers` | 3 | — | Test-design generators in PROPOSE sub-phase (f2) |

An unset knob takes the default above. A cap hit with open blockers always escalates to the user rather
than converging silently.

---

## 13. Cross-project feature workspaces (`/v-pm`)

`/v-pm` plans a feature **once**, project-agnostically. Each project's `/v-team <feature>` session then
reads that plan and coordinates asynchronously through files, so you stop carrying context between agent
sessions by hand. The substrate is a shared workspace plus a file-based conversation.

### Home & ownership
`~/vault/_features/` is its **own committed vault** with its own git. It is neutral ground owned by no
single project, because a feature spans several. Each participant project holds a `features/<feature>`
**symlink** into it, gitignored in the project repo; see `templates/vault.gitignore`.

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
`/v-pm` authors a business-logic requirements layer, so the necessity is captured once and richly. You
never repeat yourself, and both people and models can reason about the product.

`requirements.md` is a **SPEC** and aspirational by design. It holds business rules shaped as
`precondition → expected [; edge]`, each with a stable `REQ-NN` id, plus acceptance criteria, a domain
glossary in the project's own language, and optional decision or state tables. This is what grounds
**rich tests** through the id chain below, and what grounds AI understanding of the product.

- **Decoupled from the coordination machinery.** The knowledge center is authored for **any** feature,
  one repo or many. The `_features/` workspace, `conversation/` and `contracts.md` are the delta that
  two or more repos add.
  - **2+ repos:** `requirements.md` in the neutral `_features/<feature>/`, symlinked into each project.
  - **1 repo:** `<project-vault>/requirements/<feature>.md` in the project's own vault, with no
    cross-repo write.
- **Id-traceability chain**, which is what makes the spec *ground* tests rather than merely describe
  them: `requirements.md` rule `REQ-NN` → `/v-team` LOAD CONTEXT reads it (`00-feature-pickup` §0.2, or
  the `02-load-context` `requirements/` glob) → the `(f2)` test-design fan-out echoes `REQ-NN` into the
  proposed test backlog's `source` → at capture, the **established** `features/<feature>` dossier's
  `## Behaviors & rules` carries the same `REQ-NN`. The spec id survives end to end, into the built
  behaviour.
- **Spec against established.** `requirements/` (or `_features/…/requirements.md`) is aspirational;
  `features/` is what shipped. `/v-team` and `/v-capture` promote only **built** rules into the dossier;
  the `established, not aspirational` rule (`capture-behaviors-test-shaped`) still governs `features/`.

`/v-pm`'s **CAPTURE** step, which is plan mode step 5 and also the tail of `reconcile`, is v-pm's own
`/v-capture`. It writes the planning-session record, extracts cross-project ADR candidates, and commits
the workspace. Each project's LOAD CONTEXT then finds that committed markdown.

There is **no `ledger.md`**. The ledger is a **derived view** computed from thread filenames on read, by
`/v-pm status` and by reconcile. Nothing writes it, so parallel sessions never race on it.

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
When `/v-team` runs with a `<feature>`, or finds the `features/<feature>` symlink, its **Step 0**
(`v-team/steps/00-feature-pickup.md`) runs before ANALYZE. It answers or acts on threads addressed to
this project, surfaces replies to questions this project asked, and runs a **deterministic**
field-by-field drift check of the project's consumed contract against `contracts.md`. The model only
phrases the rationale; it never decides whether drift exists. A new cross-project doubt raised
mid-session becomes a new thread instead of a message to you.

### Latency contract
There is **no live agent-to-agent channel**. A reply surfaces at the **next open** of the asking
project's session, or immediately through **`/v-pm status`**, the cross-feature inbox listing every open
thread by target project and `→pm`, with its staleness age. `reconcile` flags any thread left OPEN for
more than N session-opens. Run `/v-pm status` to see what is blocked without opening every repo.

### When to use
Use `/v-pm` only for a feature spanning **2 or more repos worked in separate sessions**. For a
single-project feature it hands straight off to `/v-team`, because the workspace costs more than it
returns below that bar.
