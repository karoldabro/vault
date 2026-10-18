---
type: feature
project: vault
slug: plugin-extensions
status: established
since: 1.6.0
tags: [plugins, extension, install]
---

# Plugin extensions — how a separate repo extends this framework

Three points, a registry the operator writes by hand, and one CLI. A plugin reaches per-repo
onboarding, the config gate and the EXECUTE quality checks; everything else it needs, Claude Code
already gives it.

Decision and the rejected alternatives: `vault/decisions/ADR-030-framework-extension-points.md`;
the `check` point: `vault/decisions/ADR-034-three-execute-loops.md`.
Byte-level contract: `vault/architecture/plugin-extension-contract.md`.
Rule for anyone editing the call sites: `vault/indications/plugin-extension-never-aborts-host.md`.

## Contracts

| file | role |
|---|---|
| `lib/plugin-registry.sh` | `vault_plugin_list` · `vault_plugin_path` · `vault_plugin_check_points` · `vault_plugin_run_point` · `vault_plugin_dod_keys` · `vault_plugin_opted_in` · `vault_plugin_check_declared` · `vault_plugin_run_check` |
| `bin/vault-check.sh` | the one caller of the `check` point; falls back to `lint_command` / `test_command`; owns the max(80, floor) coverage rule |
| `bin/vault-plugin.sh` | `add` · `remove` · `list` · `doctor`; the only writer of the registry |
| `bin/vault-init.sh` | runs the `init` point, and validates the slug before it reaches `sed` or a plugin |
| `bin/gate.sh` | `plugin_keys` inside `cmd_config` |
| `~/vault/_global/plugins.tsv` | the registry: `name<TAB>path<TAB>points`, mode 0600, machine-local |
| `templates/plugin/` | the skeleton a plugin author copies |
| `tests/unit/plugin-registry.bats` | registration, points, opt-in |
| `tests/unit/vault-check.bats` | the `check` point and the fallback |
| `checks/ext-SC-{1,2,3,4,5,7}.sh` | the gate checks |

## The three points

| point | plugin file | called from | arguments |
|---|---|---|---|
| `init` | `extend/init.sh` | `bin/vault-init.sh`, after `VAULT.md` is written | `<code-repo> <vault-dir> <slug>` |
| `dod-keys` | `extend/dod-keys.tsv` | `bin/gate.sh config` | none; read as data |
| `check` | `extend/check.sh` | `bin/vault-check.sh`, only for a repo whose `plugins:` line names the plugin | `<static\|tests> <repo> <base>` |

## Behaviors & rules

- Given a registered plugin declaring `init`, when `bin/vault-init.sh` runs, then its
  `extend/init.sh` runs once with the repo path, vault dir and slug in that order.
- Given a repo with no `VAULT.md`, when the points would run, then none runs and the skip is printed;
  no `VAULT.md` is fabricated.
- Given a point that exits 1, when it returns, then one warning says it declined and the host exits 0.
- Given a point that exits above 1, then the warning says it could not run and names the code; a
  crashed script is never recorded as one that chose to do nothing.
- Given a point that reads stdin, then it reads nothing: stdin is closed, so the host keeps its own.
- Given a registry row whose path no longer resolves, then one warning names it and the row stays.
- Given a repo whose `VAULT.md` names a plugin, when `bin/gate.sh config` runs, then every key that
  plugin declares is required and its `why` is printed in the refusal.
- Given a repo that does not name the plugin, then none of its keys is required.
- Given a `plugins:` value with whitespace after a comma, then every name still matches.
- Given more than one `plugins:` line, then the gate refuses; only the first is ever read.
- Given a name in `plugins:` that is not registered, then one note says so and no key is required.
- Given `absent: <reason>` as a plugin-declared key's value, then the gate passes, exactly as for a
  built-in key.
- Given `add` on a directory with no `extend/plugin.tsv`, a declared point whose file is absent or is
  not executable, a path traversing a symlink, or a point this framework does not implement, then
  registration is refused and no registry row is written.
- Given `add` on a name already registered, then the row is replaced and the old path printed.
- Given a registry holding two rows with one name, then `vault_plugin_list` refuses; a silent
  first-wins would hide the second path.
- Given a plugin path containing a space, then it registers, runs, and the next row is unaffected.
- A `check` point exiting above 2, a missing `check.sh` or an unreadable registry → `bin/vault-check.sh` exits 2 and never falls back.
- A registered `check` plugin the repo's `plugins:` line does not name → never runs.

## Exit codes

`bin/vault-plugin.sh`: 0 done · 1 refused · 2 usage. `vault_plugin_run_point` always returns 0.
`vault_plugin_run_check` and `bin/vault-check.sh`: 0 measured and acceptable · 1 measured and worse ·
2 could not measure.

## Sessions

- [[../sessions/2026-09-14-1433-plugin-extension-points]] — built both points, the registry, the CLI
  and the skeleton; cut two designed points on evidence.
- [[../sessions/2026-10-18-1257-quality-loops]] — the `check` point and `bin/vault-check.sh`.

## Not covered

Machine-level prerequisite installation, command and hook registration (Claude Code's own), and any
plugin-to-plugin dependency beyond the manifest `dependencies` key.
