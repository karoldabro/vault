# Commands

Slash commands provided by the vault framework. Installed into `~/.claude/commands/` by `../install.sh` (run once per machine after cloning the framework).

Each file is a Claude Code slash command definition. The `description:` frontmatter field is what shows when users invoke the command help.

| File | Slash command | What it does |
|------|---------------|--------------|
| `v-init.md` | `/v-init` | Bootstrap a project vault for the current code repo. |
| `v-migrate.md` | `/v-migrate` | Convert a submodule-based vault to the global framework model. |
| `v-work.md` | `/v-work` | Vault-aware development lifecycle. |
| `v-team.md` | `/v-team` | Persona-critique lifecycle: parallel project-specific critics loop over plan + diff. |
| `v-cr.md` | `/v-cr` | Automated code review on a remote PR: auto-detect forge (GitHub/Bitbucket) + task (Jira/Asana), critic swarm, post inline+summary comments. |
| `v-ask.md` | `/v-ask` | Read-only, vault-aware Q&A. Loads context, answers, no edits/approval/capture. |
| `v-do.md` | `/v-do` | Small low-risk change — no approval gate; orient → execute → self-review, capture optional. |
| `v-capture.md` | `/v-capture` | Enhanced session capture. |
| `v-resume.md` | `/v-resume` | Force fresh context recall (vault + OpenViking). |
| `v-sync.md` | `/v-sync` | Re-ingest curated knowledge into OpenViking. |
| `v-link.md` | `/v-link` | Declare two projects as coupled. |
| `v-backfill.md` | `/v-backfill` | Targeted ingest of past Claude Code sessions. |
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

See `../vault-guide.md` §11 for the command reference (and §1.1 for vault path/config resolution).

## Why symlinks instead of copies

Pulling the framework repo updates the symlinked commands instantly — no per-machine reinstall. If you'd rather have copies, edit `install.sh`.
