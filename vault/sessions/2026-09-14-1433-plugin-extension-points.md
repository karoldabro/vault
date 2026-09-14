---
type: session
project: vault
date: 2026-09-14
topic: plugin-extension-points
files_touched: [lib/plugin-registry.sh, bin/vault-plugin.sh, bin/vault-init.sh, bin/gate.sh, tests/unit/plugin-registry.bats, templates/plugin/, templates/VAULT.md, VAULT.md, vault-guide.md, README.md, .claude-plugin/plugin.json, checks/ext-SC-1.sh, checks/ext-SC-2.sh, checks/ext-SC-3.sh, checks/ext-SC-4.sh, checks/ext-SC-5.sh, checks/ext-SC-7.sh, vault/check-budget.md]
decisions: [ADR-030]
tags: [session, plugins, extension, quality-gates]
---

# plugin-extension-points

## Goal

Give the framework extension points so a separate repo can extend it, and move the code-quality gate
out into `vault-quality-gates` as its first consumer.

## Did

- Designed the code-quality gate, then split it out. `github.com/karoldabro/vault-quality-gates`
  (private) carries its plan, the file-format contract and six check scripts. Nothing is built there.
- Built two framework extension points and shipped them at 1.6.0, then 1.6.1:
  `init` runs a plugin's `extend/init.sh` during `bin/vault-init.sh`; `dod-keys` makes
  `bin/gate.sh config` require a plugin's `VAULT.md` keys, only in repos naming it in `plugins:`.
- Wrote `lib/plugin-registry.sh` and `bin/vault-plugin.sh` (`add`/`remove`/`list`/`doctor`), the only
  writer of `~/vault/_global/plugins.tsv`.
- Shipped `templates/plugin/` and proved it: registered the skeleton verbatim, ran it twice against a
  `VAULT.md` with no trailing newline, and confirmed one `plugins:` line and a passing config gate.
- Wrote [[../decisions/ADR-030-framework-extension-points]],
  [[../indications/plugin-extension-never-aborts-host]] and
  [[../features/plugin-extensions]]; added seven `check-budget.md` rows.
- 31 bats cases. Each check script was proven able to fail by removing the guard behind it.

## Learned

- **`setup.sh:423-427` skips `install.sh` whenever the framework is plugin-installed**, which is how
  this machine runs. Two of four designed extension points could never have fired here.
- **`install.sh:169-175` only symlinks a hook**; registration is separate at `:207-232` and needs the
  event, matcher and flag. A point handed the hooks directory ships a hook Claude Code never calls.
- **23 Claude Code plugins already compose on this machine**, each with its own commands and
  `hooks/hooks.json`. Command and hook registration needs nothing from this framework.
- **Claude Code's plugin manifest already has `dependencies`** — "Plugins that must be enabled for
  this plugin to function" — and its name pattern accepts an `@^` version constraint. A hand-rolled
  `min_framework` field would have been a second, unenforced place to say one thing.
- **`marketplace.json` `source` takes a git URL**: `{"source": "url", "url": "…git", "sha": "…"}`.
  Verified against 400+ installed plugins, so one marketplace can list a plugin from another repo.
- **`/bin/sh` is dash here and all 29 framework scripts are bash.** Running a point as `sh <script>`
  kills it on its first array, and that crash then reads as the plugin declining.
- **`realpath` cannot detect a symlink on its own.** `cd && pwd -P` resolves links too, so both sides
  match. Compare `realpath` against `realpath -s`.
- **`local IFS=,` stays in force for an inner loop.** It made every extension point read as
  unimplemented until the comma splitting was done by hand.
- **`bin/rule-count.sh --assert` exits 1 on `main`** (`OVER: 175 rule lines, budget 173`) and nothing
  runs it. `./bin/release-check.sh` also counts untracked `.serena/` files as shipped.

## Behaviors & rules

- A plugin point runs as a child process through its own shebang with stdin closed → it can neither
  redefine the host's functions nor consume the host's input; edge: never `sh <script>`, which runs a
  bash point under dash.
- A point exits 1 → one warning says it declined. A point exits above 1 → the warning says it could
  not run and names the code. The host exits 0 either way.
- A plugin's declared keys are required only where the repo's flat `plugins:` scalar names it → a
  registered plugin never refuses a repo that did not ask for it; edge: a second `plugins:` line is
  refused, because the reader takes the first and would drop the rest in silence.
- An init point adds its name to `plugins:` → it must write every key its own `dod-keys.tsv` declares
  in the same pass, or it leaves `gate.sh config` refusing the repo it just onboarded.
- Registration refuses a path that traverses a symlink, a declared point whose file is absent or not
  executable, and a point the framework does not implement → nothing is written to the registry.
- A registry row whose path stopped resolving → one warning and the row stays; removing it would
  erase a decision the operator made.
- `bin/vault-init.sh` runs `gate.sh config` before and after the points, warning only when the first
  passed and the second refused → a pre-existing refusal is never blamed on a plugin.

## Next

- **Session C:** write `extend/{plugin.tsv,init.sh,dod-keys.tsv}` and `.claude-plugin/plugin.json` in
  `vault-quality-gates`, plus a `marketplace.json` entry here. That reaches SC-6 and SC-7, the last
  two unmet criteria in [[../plans/2026-09-14-1327-framework-extension-points]].
- Nothing is registered on this machine; `~/vault/_global/plugins.tsv` does not exist.
- `./bin/release-check.sh` fails on untracked `.serena/memories/_session-log.md`. Adding `.serena/`
  to `.gitignore` clears it.
- The quality gate itself is designed and unbuilt: 47 work items over five sessions, in the plugin
  repo's own plan.
- The reviewers hit their round cap on both plans, so the last round of fixes to each went unreviewed.

## Refs

- [[../decisions/ADR-030-framework-extension-points]] — the two points, and why two of four were cut.
- [[../architecture/plugin-extension-contract]] — the three file formats and how a point is executed.
- [[../indications/plugin-extension-never-aborts-host]] — the rule for anyone editing the call sites.
- [[../features/plugin-extensions]] — every contract file and the behaviour rules.
- [[../plans/2026-09-14-1327-framework-extension-points]] — the plan, sessions A and B done.
- [[../indications/unreadable-is-not-no]] — why a point that could not run is told apart from one
  that declined.
- [[../indications/hooks-never-fail-their-host]] — the same rule for the other kind of hook.
