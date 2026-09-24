---
type: decision
project: vault
id: ADR-032
slug: remove-memory-and-edit-mcps
status: accepted
scope: repo
date: 2026-09-24
tags: [adr, install, tools, mcp]
---

# ADR-032 — the framework prescribes no memory plugin, edit MCP or code graph

## Context

The framework installed or prescribed claude-mem (a memory plugin), MorphLLM Fast Apply (an edit MCP),
Graphify (a code graph rebuilt on every commit), `bun` (a claude-mem dependency), and the Context7,
Sequential and Magic MCPs. The operator decided to drop all of them.

Claude transcripts on the operator's machine show how little the graph was used. 3 of 2388 sessions ran
`graphify query`, `path` or `explain`, and 26 sessions called Serena tools 524 times. The count came from
`~/.claude/projects/**/*.jsonl` on 2026-09-24.

## Decision

1. **Serena is the one optional developer tool.** `setup.sh --full` installs it. Every command treats it
   as absent by design on a machine whose `install_mode` is not `full`, and reads or greps instead.
2. **Two install profiles.** `--light` is the default and installs no optional tool. `--full` adds Serena.
   `--minimal`, `--with-claude-mem` and `--with-graphify` exit 2 as unknown flags.
3. **Recall is grep over the vault**, and structural questions are answered by grep, Glob or Serena.
   Edits use `Edit` and `Write`.
4. **Project-wired MCPs stay.** A repo's task tracker in the `VAULT.md` `tools` section, and PostHog, BOE
   or CRM data in personas, are the project's own choice, not the framework's.
5. **Removal from a machine is the user's step.** `docs/uninstall-removed-tools.md` lists the commands;
   neither `setup.sh` nor `bin/vault-uninstall.sh` removes these tools.

## Consequences

- `bin/vault-init.sh` no longer installs a graph hook, and `--no-graphify` is an unknown flag.
- `lib/installers.sh` loses the `bun`, `pipx` and plugin-marketplace helpers, which only these tools used.
- A machine config that still reads `install_mode: minimal` behaves as `light`.
- `tool-playbook.md` keeps its section numbers, because `templates/VAULT.md` copies cite them in every
  project vault.
