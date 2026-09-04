---
type: guide
tags: [framework, process, guide]
---

# Vault Guide — How to work with the vault

This is the process document for any project using the vault framework. A repo overrides parts of it in
its own `VAULT.md` (§1.1), its `CLAUDE.md`, or `<project-vault>/conventions.md`.

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

**How to tell project from machine:** content that someone cloning your repo would not need is machine
layer.

---

## 1.1 Vault location & config resolution

Every command resolves two paths when a run starts.

**Framework path** — `$VAULT_FRAMEWORK_PATH`. It holds `vault-guide.md`, `templates/`,
`tool-playbook.md`, `personas/`, `lib/`, `bin/`, and the commands. Resolved in order, first hit wins:

1. **`${CLAUDE_PLUGIN_ROOT}`**, when a command file's text shows it as an absolute path. Claude Code
   substituted the placeholder at load time, so this is the only value guaranteed to match the files
   currently running.
2. **`<code-repo>/VAULT.md`** → the `framework_path` key.
3. **`~/vault/_global/config.md`** → `framework_path`, captured at install time by `setup.sh`.
4. **Built-in default** `~/workspace/vault`.

A plugin install puts the framework in a versioned cache directory that every update changes, so nothing
writes it to `config.md` or to any `VAULT.md`. A symlink install gives a stable path, and `config.md` is
authoritative. The two modes exclude each other — see `INSTALL.md`.

**Vault path** — resolved in order, first hit wins:

1. **`<code-repo>/VAULT.md`** → the `vault_path` key. Relative paths resolve against the repo root, so
   `vault_path: ./vault` keeps the vault in the repository; `~/vault/givore` keeps it global.
2. **`~/vault/_global/config.md`** → `vault_home`, the global default chosen at install.
3. **Built-in default** `~/vault/<slug>/`, slug from `coupled-groups.md` or the repo basename.

`VAULT.md` is optional, sits at the repo root, and templates from
`$VAULT_FRAMEWORK_PATH/templates/VAULT.md`. Every command reads its five sections once at start
(`01-analyze.md` §1.4) and carries them forward. Unknown keys are ignored; no `VAULT.md` means every
default and a global vault.

| Section | Keys | Effect |
|---------|------|--------|
| `config` | `vault_path`, `framework_path`, `slug` | Path + identity resolution (above). |
| `structure` | `add_folders: [...]`, `rename: {std: alias}`, `optional: [...]` | Scaffold extra folders, alias standard ones locally, silence "missing folder" for optional ones. |
| `behaviour` | `load_context_extra: [...]`, `capture_indications: true\|false`, `suggest_rename: true\|false`, `vault_autosync: true\|false` | Folders Step 2 loads beyond defaults; whether capture runs the indication scan; whether step 1 suggests a session rename; whether an out-of-repo vault is pulled and pushed automatically (below). |
| `hooks` | `<phase>: <prose>` | Per-project instruction injected at a lifecycle phase (below). Prose only, never run as a shell command. |
| `tools` | `task_tracker`, `task_tracker_mcp`, `task_tracker_key`, `guidance` | Which task-tracker MCP this repo uses (Jira, Asana), so the lifecycle can fetch ticket context. A suggestion, not a gate. |

**Cross-project feature workspaces** live in `~/vault/_features/`, outside any single project vault and
its own committed vault. `/v-pm` writes them; a per-project `/v-team <feature>` session reads them
through a `features/<feature>` symlink. Protocol: §13.

### Vault git sync — out-of-repo vaults

A vault under `~/vault/<slug>/` sits outside the code repo's commits, so every v-* command routes git
through `$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh` and **never through raw `git`**:

```bash
vault-sync.sh pull <vault>                        # before reading vault context
vault-sync.sh push <vault> -m "<subject>" [paths] # after the vault writes land
```

Exit codes, all non-fatal: `0` synced · `1` a git operation failed, and a conflicting rebase is aborted
with the worktree left clean · `3` not a git repo, noted once, and `git init` never runs for the user ·
`4` the vault lives inside the code repo, so the code commit covers it and sync skips silently ·
`5` no upstream, so `push` committed locally and said so.

**A sync failure never halts a lifecycle and never blocks a capture.** `/v-ask` is excluded entirely: it
promises no git write, and a pull rewrites the worktree. `behaviour.vault_autosync` governs it, defaults
to on, and falls back to `vault_autosync` in `~/vault/_global/config.md`. Contract:
`$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`.

### Lifecycle hooks — phases, precedence & failure modes

A hook attaches a prose instruction to a lifecycle phase. `/v-work` and `/v-team` read it once at step 1
(§1.4), then treat it as binding for that phase. The value goes into the agent's prompt and is **never
run as a shell command**. There are **14 phases**: two bookends plus a `pre_`/`post_` pair per step.

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

The APPROVAL GATE (step 4) takes no hook, because it is your decision. In `/v-team`, `pre_/post_propose`
and `pre_/post_execute` fire at the loop's outer boundary, not once per round.

Precedence and failure modes — the framework never halts:

1. A hook never runs as a shell command. It is prose guidance.
2. On a conflict, `CLAUDE.md` and `indications/` rules beat a hook. Surface the conflict at the approval
   gate rather than quietly obeying the hook.
3. A hook needing a down MCP: try it, fall back, and say so.
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

An underscore prefix (`_*`) marks a meta, index, or mountpoint file, and sorts to the top of its folder.

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

They live in `$VAULT_FRAMEWORK_PATH/templates/`. Copy one, fill in the frontmatter, write the content.
Never edit a template from inside a project.

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

---

## 5. Stub conventions

A document is a stub if it carries any of: frontmatter `status: stub`, a `<!-- TODO -->` placeholder, or
under 40 lines of content excluding frontmatter and headings.

When you fill a stub, remove the `status: stub` frontmatter and every `<!-- TODO -->` marker, and
overwrite it in place. Never create a second document.

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
often produces both. Four folders are easy to confuse:

- **`indications/`** — intra-project: patterns, standards and instructions for working on this repo
  ("controllers stay thin", "migrations are reversible"). Every `/v-work` run reads it early; capture
  grows it (§7b).
- **`guides/`** — cross-project: the contract one repo publishes so others can build against it. Written
  by `/v-guide`.
- **`features/`** — subject-matter: what a domain does, its scope, contracts, coupling and gotchas.
- **`requirements/`** — the plan-time **spec** `/v-pm` writes: business rules `REQ-NN` with acceptance
  criteria and a glossary, **aspirational by design** and written before the code. `features/` is its
  *established* counterpart, carrying each `REQ-NN` once the work ships. Never collapse the two.

---

## 7. Duplicate avoidance protocol

Run this before writing any new document. `/v-work` and `/v-capture` run it for you; run it by hand for a
one-off write.

1. **Extract keywords**: 3 to 6 short keywords from the intended title or topic.
2. **Grep the vault**:
   ```bash
   for kw in <keywords>; do
     grep -ril "$kw" <project-vault>/{decisions,features,indications,sessions,processes,architecture} 2>/dev/null
   done | sort -u
   ```
3. **Check indexes**: `_feature-index.md`, `decisions/_inventory.md`, `_moc.md`, for a slug or topic match.
4. **Search claude-mem when installed**: `search(<topic>)`, top 5 hits. Not installed → say so once; the
   grep in step 2 stands on its own.
5. **Apply the rule**: when an existing document covers more than 60% of the topic, update it.
6. **Naming guards**:
   - ADRs take the next free sequential number from `_inventory.md`.
   - Features in a master domain set keep the project's `NN-` prefix.
   - Sessions are always `YYYY-MM-DD-HHMM-<slug>.md`, slug at most 6 words, kebab-case.
   - No two documents share a slug across folders.

A document missing from the grep means the indexes were not updated. Fix that first.

---

## 7b. Growing `indications/` (working rules)

Capture promotes indications ADR-style, aimed at how-we-work statements rather than decisions.
`behaviour.capture_indications` gates it and defaults to on.

1. **Scan** the session for convention-shaped phrasing: `convention:`, `pattern:`, `rule:`, `standard`,
   `always <verb>`, `never <verb>`, `we use .* for`, `prefer .* over`, `the .* way is`, and
   testing-approach statements.
2. **Present** each match as a one-line candidate; you promote the ones worth keeping.
3. **Write** each promoted candidate to `indications/<slug>.md` from `indication.md`, and append a row to
   `indications/_index.md`.

---

## 8. Cross-linking

- Use relative Obsidian wikilinks: `[[../features/foo]]`, never absolute URLs.
- Back-link every new document from at least one index: `_moc.md`, `_feature-index.md`, or
  `decisions/_inventory.md`.
- Sessions carry a `Refs` section listing every wikilink to related ADRs, features, and prior sessions.
- ADRs link to the features they affect, in a `Cross-repo impact` or `Affects` section.
- Nothing maintains bidirectional links for you. Add the reverse yourself when it carries weight.

---

## 9. Keeping the vault current

Check this after `/v-work` finishes, or when you tidy by hand:

- [ ] New feature/process doc → linked from `_moc.md`?
- [ ] Feature touched → dossier created or updated per the gate (§6 / capture), `_feature-index.md` reconciled?
- [ ] New ADR → appended to `decisions/_inventory.md`?
- [ ] New working rule/pattern surfaced → promoted to `indications/` + `_index.md`?
- [ ] New tag used → registered in `_tags.md`?
- [ ] Stub upgraded → frontmatter `status: stub` removed?
- [ ] Session has its `Refs` section populated?

Weekly, or once per milestone: list stubs with `grep -rl "status: stub"` and either promote or delete the
old ones, then spot-check `_moc.md` for broken wikilinks in Obsidian's graph view.

---

## 10. Required tools

Vault commands prefer these tools and fall back cleanly when one is missing; `setup.sh` installs them
(see [INSTALL.md](INSTALL.md)). The floor under all of them is grep over the vault markdown.

| Tool | Purpose | Install |
|------|---------|---------|
| **Serena** | Symbol-aware code navigation and refactoring. MCP: `activate_project`, `find_symbol`, `rename`, `replace_symbol_body`. | `setup.sh --with-serena` |
| **MorphLLM Fast Apply** | Bulk multi-file edits at 10k+ tok/sec. MCP: `morph_edit(target_filepath, instructions, code_edit)`. | not auto-installed (paid key): `claude mcp add` — see ADR-005 |
| **claude-mem** | Project history — progressive disclosure search. MCP: `search`, `timeline`, `get_observations`. Read-only; it auto-captures via its SessionEnd hook. | `setup.sh --with-claude-mem` |

**Which tool to reach for, and in what order, lives in [`tool-playbook.md`](tool-playbook.md)** — cost
hierarchy, health checks, fallbacks, and a worked example per tool.

---

## 11. Commands reference

Commands arrive either as a Claude Code plugin (`/plugin marketplace add karoldabro/vault`, then
`/plugin install vault@kdabro-vault`) or from `$VAULT_FRAMEWORK_PATH/install.sh`, which symlinks
`commands/` into `~/.claude/commands/` and `output-styles/` into `~/.claude/output-styles/`. Pick one
mode; running both installs every command twice. All commands assume the tools in §10.

**How every command writes to you:** `commands/_shared/communication.md`, bound at the top of each
command and each step file owning a `## Required output` block. `output-styles/director.md` applies the
same rules to every Claude Code session, opt-in through `/config` → Output style → *director*. An output
style never reaches a spawned subagent, so `v-team/steps/03-propose-loop.md` §(e).7 caps subagent text
instead. Decision record: [[ADR-018-decision-communication-contract]] in `vault/decisions/`.

| Command | Purpose | Key tools |
|---------|---------|-----------|
| `/v-setup` | Install or repair the machine-level stack — prerequisites, `~/vault/_global/`, optional tools. Wraps `setup.sh`, shows what it will run, asks first. `--doctor` checks without changing anything. | — |
| `/v-init` | Bootstrap a project vault for the current repo: creates the vault (global, or in-repo with `--in-repo`), writes `VAULT.md`, scaffolds folders + indexes, wires CLAUDE.md. | git |
| `/v-work` | Vault-aware dev lifecycle: load context → propose (with the duplicate check) → approval → execute → commit + capture. | claude-mem, Serena, MorphLLM |
| `/v-team` | Persona-critique lifecycle for big or high-stakes work. Reuses v-work steps 01/02/05; PROPOSE + EXECUTE run panel loops where project-specific critics (from `VAULT.md` `project_type`/`personas`, then stack auto-detect; defined in `personas/`) review plan + diff, propose fixes + tests, and loop to convergence. | Agent panel, claude-mem, Serena, MorphLLM |
| `/v-ask` | Read-only, vault-aware Q&A. Loads context cheapest-first; no edits, no gate, no capture. Hands off when the answer implies a change. | claude-mem, graphify, Serena |
| `/v-do` | Small low-risk change, no approval gate. Orient → execute → self-review; capture off by default. Escalates to `/v-work` above ~5 files, `/v-team` for architecture, schema, auth, billing or cross-repo. | claude-mem, Serena, MorphLLM |
| `/v-capture` | Capture this session as `sessions/*.md`. Runs the duplicate check, updates indexes, extracts ADR candidates, cross-links Refs. | claude-mem auto-capture (SessionEnd hook) |
| `/v-link` | Declare two projects coupled, so context loading sweeps both. Updates `~/vault/_global/coupled-groups.md`. | — |
| `/v-guide` | Generate a cross-project integration guide (API contract, data structures, enums, data flow) from a feature. | claude-mem, graphify, MorphLLM |
| `/v-reconcile` | Bring a document up to `_shared/document-standard.md`: split the record out to a sidecar, rewrite, then prove with `doc-lint --compare` that no constraint was dropped. Approval-gated per file. | claude-mem, graphify, `bin/doc-lint.sh` |
| `/v-pm` | Cross-project feature planning: a business→product→architect→contract pipeline drafts a shared plan + contract into `_features/`, then per-project `/v-team` sessions coordinate via file threads (§13). | Agent |

`attic/` holds `/v-migrate`, whose one-shot migration finished; `bin/vault-migrate.sh` still works.
OpenViking is no longer a dependency, and `/v-sync` and `/v-backfill` went with it; to take an older
install off a machine, see [docs/removing-openviking.md](docs/removing-openviking.md).

---

## 12. Project-specific overrides

Two layers, checked in order:

1. **`<code-repo>/VAULT.md`** (§1.1) — structured config, machine-read on every command.
2. **`_moc.md` / `<project-vault>/conventions.md`** — prose conventions config cannot express: the
   feature numbering scheme, a sub-repo session prefix (`api-`, `app-`), whether `architecture/` or
   `business/` is used, and extra tags.

The framework assumes none of these. Read `VAULT.md`, then the project's conventions.

### 12.1 `/v-team` panel knobs (settable in `VAULT.md`)

| Knob | Default | Bounds | Governs |
|------|---------|--------|---------|
| `team_max_parallel_critics` | 3 (business packs 4) | hard max 5 | Critics per panel round (`personas/_resolution.md` §2, business selection §2.2) |
| `team_max_rounds` | 2 | hard ceiling | PROPOSE design-loop rounds (`v-team/steps/03-propose-loop.md`) |
| `team_max_review_rounds` | 2 | hard ceiling | EXECUTE diff-review-loop rounds (`v-team/steps/04-execute-loop.md`) |
| `team_max_test_designers` | 3 | — | Test-design generators in PROPOSE sub-phase (f2) |

An unset knob takes the default. A cap hit with open blockers escalates to the user.

---


## Session gates

`bin/gate.sh` refuses a session that cannot show its work. It runs at three points and a nonzero
exit stops the lifecycle rather than warning.

| when | subcommand | it refuses |
|---|---|---|
| ANALYZE, first thing | `config <repo>` | `VAULT.md` omits `dod_profile`, `test_command`, `lint_command` or `delivery_command`. `absent: <reason>` is legal; an omitted key is not |
| PROPOSE, before work items | `criteria <plan>` | no success criteria; a criterion whose check is not a committed executable; no criterion of `kind: delivery` |
| close, before staging | `all <plan> --phase close` | a criterion with no verdict, a declared identifier no code reads, a defect repair with no failing-before test |

**A criterion names a committed script, never a command typed into the plan.** `verdict --run`
executes it and writes the verdict and the captured output into the plan itself, so those two cells
are the only part a session never authors. Full contract: `vault/architecture/session-gates.md`.
Reasoning and the measurements behind it: `vault/decisions/ADR-026-mechanical-session-gates.md`.

`scripts/completion-hook.sh` blocks a turn end when a work item is marked done and its criterion has
no verdict. Turn it on with `install.sh --enable-gate`; silence it with `COMPLETION=off`.
`GATE=off` disables every check, whole-run only.

## 13. Cross-project feature workspaces (`/v-pm`)

`/v-pm` plans a feature **once**, project-agnostically. Each project's `/v-team <feature>` session reads
that plan and coordinates through files, so you stop carrying context between sessions by hand.

**Use it only for a feature spanning 2 or more repos worked in separate sessions.** For a single-project
feature `/v-pm` hands straight off to `/v-team`.

### Home & ownership
`~/vault/_features/` is its **own committed vault**, owned by no single project. Each participant project
holds a `features/<feature>` **symlink** into it, gitignored in the project repo (see
`templates/vault.gitignore`).

### Layout
```
~/vault/_features/<feature>/
  requirements.md    business knowledge center — what & why (rules REQ-NN, glossary, variant/state tables) — ONLY /v-pm writes it
  generic-plan.md    project-agnostic plan — how/sequencing + appetite + first slice + options considered — ONLY /v-pm writes it
  contracts.md       structured cross-project interface (the api↔frontend seam); refs rules by REQ-NN
  header.md          participants · status · created · session_opens counter
  conversation/      threads (state encoded in the filename)
  sessions/          planning-session records — v-pm CAPTURE writes the *why* behind the plan
  decisions/         cross-project ADRs extracted at CAPTURE (promotable to a participant vault)
  projects/<proj>/plan.md   each project's self-contained shard (its own /v-team writes it); v-pm seeds only its `## Business rules to satisfy` REQ-NN list and its `## Sessions` appetite line
```

### Business knowledge center (`requirements.md`) — spec → established lifecycle
`requirements.md` is a **SPEC**, aspirational by design. It holds business rules shaped as
`precondition → expected [; edge]`, each with a stable `REQ-NN` id, plus acceptance criteria, a domain
glossary and optional decision or state tables. It grounds rich tests and captures the necessity once.

- **Written for any feature**, one repo or many; `_features/`, `conversation/` and `contracts.md` are
  the delta two or more repos add.
  - **2+ repos:** `requirements.md` in the neutral `_features/<feature>/`, symlinked into each project.
  - **1 repo:** `<project-vault>/requirements/<feature>.md`, with no cross-repo write.
- **Id-traceability chain**, which is what makes the spec *ground* tests rather than describe them:
  `requirements.md` rule `REQ-NN` → `/v-team` LOAD CONTEXT reads it (`00-feature-pickup` §0.2, or the
  `02-load-context` `requirements/` glob) → the `(f2)` test-design fan-out echoes `REQ-NN` into the
  proposed test backlog's `source` → at capture, the **established** `features/<feature>` dossier's
  `## Behaviors & rules` carries the same `REQ-NN`.
- **Spec against established.** `/v-team` and `/v-capture` promote only **built** rules into the dossier;
  the `established, not aspirational` rule (`capture-behaviors-test-shaped`) still governs `features/`.

### Sizing and tracking — a budget, then rows the working session owns
`/v-pm` sets the size and names the starting point; it never enumerates the work, because it does not
read the code it would be slicing.

- **`## Appetite`** (in `generic-plan.md`) — how many sessions the feature is worth in each repo,
  decided before the design is detailed. A **ceiling**: a session that does not fit cuts `[could]` then
  `[should]` rules rather than exceeding it.
- **`## First slice`** — the one cut that runs vertically through the hardest part, so the surprise
  arrives first.
- **`## Sessions`** (in each `projects/<proj>/plan.md`) — the tracker. `/v-pm` seeds the header and the
  appetite; the project's own `/v-team` session writes every row at propose-time `(f3)` and maintains
  it thereafter. Columns: `id · scope · command · status · REQ covered · evidence · last touched ·
  deviation`. `status` is exactly `todo`/`doing`/`done`/`dropped`; `command` is `/v-do`, `/v-work` or
  `/v-team` (never `/v-ask`, which writes nothing and so closes nothing).

The tracker lives in the shard because that is the file the working session already opens. The one
roadmap here that stalled kept its tracker in a separate file nothing forced anyone to read.

**A `done` row without evidence is invalid.** The evidence cell holds a commit or a session-record
path. Four sessions in one feature were once closed as done against a code path that could never run,
because nothing asked for it.

**Expect the rows to be wrong in detail and to say so.** The tracker that worked here shipped all ten
of its sessions and rewrote nearly every row on the way. A recorded deviation is the tracker doing its
job; a row that drifts silently is the defect.

### Status is derived, never hand-kept
A feature's `header.md` `status:` is **rolled up from the session rows** by `/v-capture` Step 4e on the
way out of every session: all `todo` → `planning`; some moving → `in-progress`; all `done` or `dropped`
→ `shipped`. `/v-pm status` reads the rows too, and flags any header that disagrees with them.

Two places once held this field and only one was ever written, which is why nine of twelve features
read `planning` while their own shards read `done`. Derive it; do not maintain a second copy.

`/v-pm`'s **CAPTURE** step — plan mode step 5, and the tail of `reconcile` — writes the planning-session
record, extracts cross-project ADR candidates, and commits the workspace, which is what each project's
LOAD CONTEXT then finds.

There is **no `ledger.md`**. The ledger is a **derived view** computed from thread filenames on read, by
`/v-pm status` and by reconcile. Nothing writes it, so parallel sessions never race on it.

### Conversation protocol
A thread is one Markdown file whose **filename carries its state**. Frontmatter carries `from` / `to` /
`asks`. Template: `templates/_features/THREAD.md`.

| filename | meaning | who moves it |
|----------|---------|--------------|
| `THREAD_<n>_OPEN_→<proj>.md` | question waiting on project `<proj>` | the asker creates it |
| `THREAD_<n>_OPEN_→pm.md` | decision that changes the generic plan / a contract | drained by `/v-pm reconcile` |
| `THREAD_<n>_ANSWERED_<answerer>.md` | answered; waiting for the asker to consume | the answerer renames |
| `THREAD_<n>_RESOLVED.md` | asker consumed the answer | the asker renames |

### How it reaches execution — auto-pickup
When `/v-team` runs with a `<feature>`, or finds the `features/<feature>` symlink, its **Step 0**
(`v-team/steps/00-feature-pickup.md`) runs before ANALYZE. It acts on threads addressed to this project,
surfaces replies, and runs a **deterministic** field-by-field drift check of the project's consumed
contract against `contracts.md` — the model phrases the rationale but never decides whether drift exists.
A new doubt raised mid-session becomes a new thread instead of a message to you.

### Latency contract
There is **no live agent-to-agent channel**. A reply surfaces at the **next open** of the asking
project's session, or immediately through **`/v-pm status`**, the inbox listing every open thread with
its staleness age. `reconcile` flags any thread left OPEN for more than N session-opens.
