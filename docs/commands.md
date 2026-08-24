# Commands

The vault framework's slash commands live in `../commands/`. They reach Claude Code either through the
plugin install, where Claude Code scans `commands/` itself, or through `../install.sh`, which symlinks
the same tree into `~/.claude/commands/`. `../INSTALL.md` covers both routes.

Each file is a Claude Code slash-command definition. Its `description:` frontmatter field is what users
see in the command help.

**Nothing but command definitions may live in `../commands/`.** A plugin install turns every `.md` under
it into an invocable command, which is why this file sits in `docs/` and retired commands sit in
`../attic/`. `../tests/unit/plugin-install.bats` guards that.

Each command resolves `$VAULT_FRAMEWORK_PATH` in its own header before using it, preferring
`${CLAUDE_PLUGIN_ROOT}` when Claude Code substituted one. That is what lets the same file work from a
plugin cache directory and from a git clone. `../vault-guide.md` §1.1 holds the resolution order.

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
| `v-reconcile.md` | `/v-reconcile` | Rewrite an existing document to the writing standard; verified with `doc-lint --compare` so no constraint is lost. |
| `v-pm.md` | `/v-pm` | Cross-project feature planning: a critic pipeline drafts a shared plan + contract into `_features/`, then per-project `/v-team` sessions coordinate via file-based threads. |

Multi-step commands (`v-work`, `v-team`, `v-cr`) keep their steps in a sibling subdirectory
(`v-work/steps/`, `v-team/steps/`, `v-cr/steps/`) and load them on demand. `/v-team` reuses `/v-work`'s
steps 01, 02 and 05 and adds looped variants for propose and execute; its critic definitions live in
`../personas/` as shared lenses plus per-stack packs.

`/v-cr` is the **review** sibling: it points the panel at a remote PR or MR instead of authoring code,
reusing the single-pass panel in `_shared/critic-panel.md`, the persona resolution, and the forge and
task adapters under `v-cr/adapters/` and `v-cr/tasks/`. Pure parsing logic lives in
`../lib/forge-detect.sh` and `../lib/cr-helpers.sh`, both unit-tested.

`/v-ask` and `/v-do` are the **light siblings**: single-file, no step subdirectory, no approval gate. Use
them when the gated lifecycle costs more than it returns — `/v-ask` for a grounded read-only answer,
`/v-do` for a small low-risk change. Both escalate to `/v-work` or `/v-team` the moment scope grows.

## Shared modules (`_shared/`)

- **`critic-panel.md`** — the single-pass critic panel (ground → select → generate → verify →
  synthesize), reused as-is by `/v-cr` and wrapped in a fix-and-reloop by `/v-team`.
- **`communication.md`** — how every command writes **to the user**. Bound at the top of each `v-*.md`
  and each step file owning a `## Required output` block. It governs user-facing prose only:
  machine-read schemas, vault documents and commit messages fall outside it, and forge comments defer to
  `/v-cr`'s own brevity rule, which serves a different reader.
  `../tests/unit/communication-contract.bats` guards it; `../vault/decisions/ADR-018-*` records it.
- **`document-standard.md`** — how every command writes a **file**. `../bin/doc-lint.sh` enforces its
  checkable half; `../tests/unit/document-standard.bats` guards it.
- **`vault-sync.md`** — how commands pull and push an out-of-repo vault through
  `../bin/vault-sync.sh`.

`../output-styles/director.md` applies the same writing rules to sessions outside a v-* command. The
plugin loads it directly and `install.sh` links it into `~/.claude/output-styles/`; either way it is
opt-in through `/config`.

`../vault-guide.md` §11 holds the full command reference, and §1.1 the vault path and config resolution.

## Why symlinks instead of copies

This applies to the `install.sh` route only. Pulling the framework repo updates the symlinked commands
at once, with no per-machine reinstall. Edit `install.sh` if you would rather have copies.

The plugin install makes the opposite trade: it copies into a versioned cache, so an update is a
deliberate `/plugin update` rather than a side effect of `git pull`.
