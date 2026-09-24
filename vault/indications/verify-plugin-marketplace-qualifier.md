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
often differs from the owner/repo. A guessed qualifier fails only on a **fresh** install. A test stub
that echoes the wrong qualifier still satisfies a grep-key idempotency check, so the bug stays invisible
until a real machine hits it.

## Examples
- Do: `karoldabro/vault` → `.claude-plugin/marketplace.json` `name: kdabro-vault`, plugin `vault` →
  install `vault@kdabro-vault`.
- Don't: derive the qualifier from the owner or repo slug (`vault@karoldabro`, `vault@vault`).

## Applies-to
`.claude-plugin/marketplace.json`, `README.md`, `commands/v-plugin.md`, `bin/vault-plugin.sh`
