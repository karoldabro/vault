---
type: session
project: vault
date: 2026-09-15
topic: readme-rewrite-and-openviking-removal
files_touched: [README.md, docs/reviewer-packs.md, INSTALL.md, vault-guide.md, tool-playbook.md, bin/vault-uninstall.sh, lib/installers.sh, tests/unit/gitignore.bats, tests/unit/business-personas.bats, tests/unit/testing-personas.bats, tests/unit/setup-autoinstall.bats, tests/integration/setup.bats, tests/integration/vault-uninstall.bats]
decisions: []
tags: [session, docs, readme, cleanup]
---

# readme-rewrite-and-openviking-removal

## Goal
Rewrite `README.md` for a human reader, and delete every live trace of the dependency dropped in
August.

## Did
- Rewrote `README.md`: centred title, four badges, four one-line selling points, install, per-repo
  setup, commands in four tables, a plugin table, and five links out.
- Repaired the command table. A `**Plugins.**` paragraph sat between two table rows, so GitHub
  rendered every row from `/v-ask` down as plain text — `/v-handoff` and `/v-report` among them.
- Gave every command row a `Use it when` column.
- Listed the plugins: `vault` and `vault-quality-gates`, with how to install each.
- Moved the `/v-team` reviewer packs to `docs/reviewer-packs.md` and pointed the two persona tests
  at the new path.
- Deleted `bin/remove-openviking.sh`, `docs/removing-openviking.md` and
  `tests/integration/remove-openviking.bats`, plus the pointer lines in `INSTALL.md`,
  `vault-guide.md`, `tool-playbook.md`, `bin/vault-uninstall.sh` and `lib/installers.sh`.
- Deleted the three guard tests that asserted the name's absence, since they carried the name.

## Learned
- A paragraph between two rows of a Markdown table silently ends the table. Everything after it
  renders as text, so a command can be present in the file and invisible on GitHub.
- `tests/unit/gitignore.bats` required `README.md`, `INSTALL.md`, `vault-guide.md` and
  `tool-playbook.md` to each carry a removal-path link, whatever they said. A file that stopped
  naming the dependency failed the test.
- `scripts/staging-hook.sh` refuses `git add <directory>`. Name each file.

## Next
- The vault's own history still names the dropped dependency in 21 files under `vault/decisions/`,
  `vault/plans/` and `vault/sessions/`. Left as written.
- `~/.claude/CLAUDE.md` still tells the reader to run `bin/remove-openviking.sh`, which no longer
  exists. It is outside this repo.
- `/v-loop` is described in `README.md` as a way of working. `commands/v-loop.md` still restricts it
  to a feature that is already built and running.
- `vault/_moc.md` lists twelve commands; the repo ships seventeen.

## Refs
- [[../decisions/ADR-019-drop-openviking-dependency]]
- [[../features/install-distribution]]
