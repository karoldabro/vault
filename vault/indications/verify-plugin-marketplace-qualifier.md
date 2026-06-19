---
type: indication
project: vault
slug: verify-plugin-marketplace-qualifier
scope: repo
tags: [indication]
---

# verify-plugin-marketplace-qualifier

## Rule
A Claude Code plugin's qualified install id is `<plugin-name>@<marketplace-name>`, where
marketplace-name is the `name` field in the repo's `marketplace.json` — never the repo owner or path.
Verify it against `marketplace.json` before wiring `claude plugin install`; never assume owner == marketplace.

## Rationale
`claude plugin marketplace add <owner>/<repo>` registers the marketplace under its declared `name`, which
often differs from the owner/repo. Guessing the qualifier (e.g. `claude-mem@claude-mem` when the real name
is `thedotmack`) fails only on a **fresh** install. A test stub that echoes the wrong qualifier still
satisfies a grep-key idempotency check, so the bug stays invisible until a real machine hits it.

## Examples
- Do: `thedotmack/claude-mem` → `marketplace.json` `name: thedotmack`, plugin `claude-mem` → install `claude-mem@thedotmack`.
- Do: `Castor6/openviking-plugins` → name `openviking-plugin` → install `claude-code-memory-plugin@openviking-plugin`.
- Don't: derive the qualifier from the owner or repo slug (`claude-mem@claude-mem`).

## Applies-to
`lib/installers.sh`, `setup.sh`, `tests/unit/setup-autoinstall.bats`
