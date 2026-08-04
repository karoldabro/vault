# Commands

Slash commands provided by the vault framework. The sources live in `../commands/`, and reach Claude
Code either through the plugin install (Claude Code scans `commands/` itself) or through
`../install.sh`, which symlinks the same tree into `~/.claude/commands/`. See `../INSTALL.md`.

Each file is a Claude Code slash command definition. The `description:` frontmatter field is what shows when users invoke the command help.

**Nothing else may live in `../commands/`.** Every `.md` under it becomes an invocable command in a
plugin install, so this file sits in `docs/` and retired commands sit in `../attic/`. Guarded by
`../tests/unit/plugin-install.bats`.

Each command resolves `$VAULT_FRAMEWORK_PATH` in its own header before using it, preferring
`${CLAUDE_PLUGIN_ROOT}` when Claude Code substituted one. That is what lets the same file work from a
plugin cache directory and from a git clone. Resolution order: `../vault-guide.md` §1.1.

| File | Slash command | What it does |
|------|---------------|--------------|
| `v-setup.md` | `/v-setup` | Install or repair the tool stack + machine-layer scaffold. Wraps `../setup.sh`. |
| `v-init.md` | `/v-init` | Bootstrap a project vault for the current code repo. |
| `v-work.md` | `/v-work` | Vault-aware development lifecycle. |
| `v-team.md` | `/v-team` | Persona-critique lifecycle: parallel project-specific critics loop over plan + diff. |
| `v-cr.md` | `/v-cr` | Automated code review on a remote PR: auto-detect forge (GitHub/Bitbucket) + task (Jira/Asana), critic swarm, post inline+summary comments. |
| `v-ask.md` | `/v-ask` | Read-only, vault-aware Q&A. Loads context, answers, no edits/approval/capture. |
| `v-do.md` | `/v-do` | Small low-risk change — no approval gate; orient → execute → self-review, capture optional. |
| `v-capture.md` | `/v-capture` | Enhanced session capture. |
| `v-link.md` | `/v-link` | Declare two projects as coupled. |
| `v-guide.md` | `/v-guide` | Generate a cross-project integration guide from an existing feature. |
| `v-pm.md` | `/v-pm` | Cross-project feature planning: a critic pipeline drafts a shared plan + contract into `_features/`, then per-project `/v-team` sessions coordinate via file-based threads. |

Multi-step commands (`v-work`, `v-team`, `v-cr`) keep their steps in a sibling subdirectory
(`v-work/steps/`, `v-team/steps/`, `v-cr/steps/`) loaded on demand. `/v-team` reuses `/v-work`'s steps
01/02/05 and adds looped variants for propose/execute; its critic definitions live in `../personas/`
(shared lenses + per-stack packs). `/v-cr` is the **review** sibling: it points the panel at a remote
PR/MR instead of authoring code, reusing the single-pass panel in `_shared/critic-panel.md`, persona
resolution, and forge/task adapters under `v-cr/adapters/` + `v-cr/tasks/`. Pure parsing logic lives in
`../lib/forge-detect.sh` + `../lib/cr-helpers.sh` (unit-tested).

`/v-ask` and `/v-do` are the **light siblings** — single-file, no step subdirectory, no approval gate.
Use them when the gated lifecycle is overkill: `/v-ask` for a grounded read-only answer, `/v-do` for a
small low-risk change. Both escalate to `/v-work` (or `/v-team`) the moment scope grows.

## Shared modules (`_shared/`)

- **`critic-panel.md`** — the single-pass critic panel (ground → select → generate → verify →
  synthesize), reused as-is by `/v-cr` and wrapped in a fix-and-reloop by `/v-team`.
- **`communication.md`** — how every command writes **to the user**. Bound at the top of each
  `v-*.md` and each step file that owns a `## Required output` block. Governs user-facing prose only;
  machine-read schemas, vault documents and commit messages are out of scope, and forge comments
  defer to `/v-cr`'s own brevity rule (different reader). Guarded by
  `../tests/unit/communication-contract.bats`. See `../vault/decisions/ADR-018-*`.

A matching Claude Code output style ships at `../output-styles/director.md` for sessions outside a
v-* command; the plugin loads it directly, `install.sh` links it into `~/.claude/output-styles/`, and
either way it is opt-in via `/config`.

See `../vault-guide.md` §11 for the command reference (and §1.1 for vault path/config resolution).

## Why symlinks instead of copies

This applies to the `install.sh` path only. Pulling the framework repo updates the symlinked commands
instantly — no per-machine reinstall. If you'd rather have copies, edit `install.sh`. The plugin
install has the opposite trade: it copies into a versioned cache, so an update is a deliberate
`/plugin update` rather than a side effect of `git pull`.
