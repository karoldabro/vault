---
type: session
project: vault
date: 2026-08-24
topic: docs-writing-standard-pass
files_touched: [README.md, INSTALL.md, vault-guide.md, tool-playbook.md, _moc.md, docs/commands.md, docs/removing-openviking.md]
decisions: []
tags: [session, docs, writing-standard]
---

# docs-writing-standard-pass

## Goal
Rewrite the vault framework's seven reader-facing documents to `commands/_shared/communication.md` and
`commands/_shared/document-standard.md`.

## Did
- Rewrote `README.md`, `INSTALL.md`, `vault-guide.md`, `tool-playbook.md`, `_moc.md`,
  `docs/commands.md` and `docs/removing-openviking.md`. Committed as `6e88195` on branch
  `docs/writing-standard-pass`.
- Fixed `_moc.md`, which linked `commands/v-migrate` and
  `sessions/2026-06-29-1233-humanize-docs` — neither file exists — and omitted `/v-setup`,
  `/v-pm` and `/v-reconcile`. It now lists every live command and points at `vault/_moc.md` for this
  repo's own project vault.
- Cut the measurement story from `docs/removing-openviking.md`, which
  `vault/decisions/ADR-019-drop-openviking-dependency.md` already holds, and led with the remover.
- Verified every phrase the bats suite greps for in `INSTALL.md`, `vault-guide.md` and
  `tool-playbook.md` survived the rewrite.
- Ran `bin/doc-lint.sh --compare <before> <after>` on all seven files; the two real drops it found
  (`~/workspace/vault/bin/vault-migrate.sh` in `README.md`, `/v-work` and `/v-team` in
  `tool-playbook.md`) were restored.

## Learned
- All seven files already passed `bin/doc-lint.sh` before the rewrite. The linter covers only the
  standard's checkable half; rules 2, 3, 4 and 9 are register and stay human judgement.
- `bin/doc-lint.sh` reads backticked text as a quotation. Dropping the backticks around
  `per-round metrics` in `vault-guide.md` turned a clean file into a `PROC6` violation.
- `--compare` reports reworded lines as drops. Every hit needs reading; the count alone misleads.
- `tool-playbook.md` sits against its 250-line cap for type `process`, so any addition needs a
  matching cut.
- The `grep -qi 'task tracker'` assertion in `tests/unit/test-hooks-tools-rename.bats` targets
  `commands/v-work/steps/02-load-context.md`, not `vault-guide.md`, which only ever wrote
  `task-tracker` hyphenated.

## Next
- Eight bats tests fail on `main` and are unrelated to this change: `communication-contract` 33,
  `document-standard` 79/102/108, `install` 150/151, `plugin-install` 163, `research-clarify` 209.
  Test 163 names a real defect — `commands/v-reconcile.md` has no `description:` frontmatter, so the
  plugin install shows it without help text. Tests 150 and 151 fail because the alpine test image has
  no `python3`, which `install.sh --enable-style` needs to edit `settings.json`.
- `docs/claude-online-rules.md`, `CLAUDE.md` and the twelve `commands/*.md` files were left out of
  scope by the approved plan.
- Branch `docs/writing-standard-pass` is unmerged and unpushed.

## Refs
- [[../decisions/ADR-018-decision-communication-contract]]
- [[../decisions/ADR-019-drop-openviking-dependency]]
- [[2026-08-21-1015-document-writing-standard]]
- [[2026-08-21-1422-doc-lint-skip-and-type]]
- [[2026-08-03-1045-decision-communication-contract]]
