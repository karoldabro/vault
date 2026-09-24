---
type: session
project: vault
date: 2026-09-24
topic: remove claude-mem, MorphLLM and Graphify from the framework
files_touched: [setup.sh, lib/installers.sh, bin/vault-uninstall.sh, bin/vault-init.sh, tool-playbook.md, docs/uninstall-removed-tools.md, tests/unit/setup-autoinstall.bats]
decisions: [ADR-032]
tags: [session, install, tools, mcp]
---

# remove claude-mem, MorphLLM and Graphify from the framework

## Goal
Remove all support for claude-mem, MorphLLM Fast Apply, Graphify, `bun`, `pipx` and the Context7,
Sequential and Magic MCPs from the framework, keep Serena optional, and give users an uninstall guide.

## Did
- Rewrote `setup.sh` to two profiles, `--light` (no optional tools, default) and `--full` (Serena).
  `--minimal`, `--with-claude-mem` and `--with-graphify` exit 2.
- Deleted the `bun`, `pipx`, `pick_python`, plugin-marketplace and graphify helpers from
  `lib/installers.sh`, the plugin removal from `bin/vault-uninstall.sh`, and the graph hook step and
  `--no-graphify` from `bin/vault-init.sh`.
- Purged the tools from commands, `tool-playbook.md`, `vault-guide.md`, `INSTALL.md`, personas,
  templates, decisions, indications, plans and sessions. Deleted `vault/indications/pin-pipx-python.md`
  and its session; renamed the zstd session to `vault/sessions/2026-06-19-1526-setup-zstd-fixes.md`.
- Wrote `docs/uninstall-removed-tools.md` and `vault/decisions/ADR-032-remove-memory-and-edit-mcps.md`.
- Removed the claude-mem and graphify lines from `~/.claude/CLAUDE.md` (backup at
  `~/.claude/CLAUDE.md.bak-2026-09-24`) and the claude-mem memory file.
- Committed `457504c`. `checks/mcp-purge-SC-1.sh` to `SC-6.sh` all exit 0; the close gate passes.
- Bumped `.claude-plugin/plugin.json` to 2.0.0 in `ecf8396`, a major version because setup flags were
  removed. Committed the operator's pending `scripts/completion-hook.sh` fix (`21f35fc`) and
  `output-styles/director.md` example row (`6856a38`), and pushed `main`.

## Learned
- Graphify ran in 3 of 2388 Claude sessions on this machine; Serena tools ran 524 times in 26 sessions.
  The counts come from grepping `~/.claude/projects/**/*.jsonl` for Bash `graphify query|path|explain`
  commands and `mcp__serena__` tool names.
- `checks/mcp-purge-SC-1.sh` matches `Context7`, `Sequential` and `Magic` case-sensitively, because
  `magic` is also a real project vault's name.
- The graded tests in `tests/unit/plan-probes.bats` pass and fail between runs of the same commit, so a
  before/after suite comparison sees them as noise.

## Behaviors & rules
- `setup.sh` with no flag, no TTY and no `--yes` → installs nothing and records `install_mode: light`.
- `setup.sh --with-serena` with no profile flag → records `install_mode: full`.
- `setup.sh --minimal`, `--with-claude-mem` or `--with-graphify` → exits 2 with "Unknown flag".
- `bin/vault-uninstall.sh --tools` → runs `uv tool uninstall serena-agent` and never calls `claude plugin uninstall`.

## Next
- The operator runs `docs/uninstall-removed-tools.md` on this machine. Graphify is still installed,
  `~/.claude-mem` and the `thedotmack` marketplace exist, and 7 repos keep a graphify post-commit hook.
  This repo's untracked `graphify-out/` is no longer gitignored.
- Other project vaults under `~/vault/` may still mention the removed tools.

## Refs
- [[../decisions/ADR-032-remove-memory-and-edit-mcps]] — the decision this session implemented.
- [[../decisions/ADR-021-install-profiles]] — rewritten to the two profiles.
- [[../features/install-distribution]] — the installer dossier, now linking the uninstall guide.
- `vault/plans/2026-09-24-1651-remove-mcp-tools.md` — the plan, with every work item and verdict.
