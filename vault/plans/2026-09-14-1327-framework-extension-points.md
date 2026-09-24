---
type: plan
project: vault
slug: framework-extension-points
repos: [vault, vault-quality-gates]
status: proposed
process_record: 2026-09-14-1327-framework-extension-points.trail.md
session:
tags: [plan, plugins, extension, install]
---

# framework-extension-points — plan

## Task

Give this framework two extension points so a separate repo can scaffold its own per-repo files
during `bin/vault-init.sh` and declare its own required `VAULT.md` keys. Keywords: `plugin`,
`registry`, `extension-point`, `vault-init`, `dod-keys`.

The first consumer is `https://github.com/karoldabro/vault-quality-gates`, which holds the
code-quality gate and is released on its own.

## Open & deferred

| item | state |
|---|---|
| One consumer exists. Each point is the narrowest seam that consumer declares. A second consumer will change the shape. | open — accepted risk |
| `${CLAUDE_PLUGIN_ROOT}` is reported unset on SessionStart and UserPromptSubmit hooks in four open Claude Code issues. Neither point here uses it, but the consumer's own session hook would. Unverified on this machine. | open — the consumer's risk, not this plan's |
| The registry names paths whose scripts the framework executes. Registering a plugin is a trust decision covering every future commit of that repo, not just the one reviewed at registration. W-2 refuses any path the operator did not name; nothing is auto-discovered. | open — stated, not eliminated |
| Commands and Claude Code hooks need no framework change: 23 plugins already compose on this machine, each shipping its own `hooks/hooks.json` and commands. A plugin that wants `/v-guard` ships its own `.claude-plugin/plugin.json`. | closed |
| `setup.sh` skips `install.sh` whenever the framework is plugin-installed, which is this machine's mode. Any point called from `install.sh` would never fire here. | closed — no such point |

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Which points does the one real consumer declare | yes | the consumer's own plan work items W-31 to W-47 | answered | init and dod-keys; its commands ship as a Claude Code plugin |
| Q-2 | How is a plugin discovered | yes | `lib/plugin-detect.sh`, `~/vault/_global/config.md` | answered | A machine-local registry the operator writes with `bin/vault-plugin.sh add` |
| Q-3 | May a plugin's key make `gate.sh config` refuse | yes | `bin/gate.sh:428-452` | answered | Only in a repo whose `VAULT.md` lists that plugin |
| Q-4 | How does a plugin declare which framework it needs | yes | the plugin-manifest schema at schemastore.org; 400+ installed plugins under `~/.claude/plugins/marketplaces/` | answered | Claude Code's own `dependencies` key, with an `@^` constraint; this framework probes `points`, not a version |

## Extension contract

`vault/architecture/plugin-extension-contract.md` carries the two points and their arguments, the
three file formats, how a point is executed, how its two failure kinds are told apart, and the
required outcome of merging the `plugins:` scalar. Every work item below is written against it.

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a registered plugin ships `extend/init.sh` THE SYSTEM SHALL run it during `bin/vault-init.sh` with the repo path, vault dir and slug as arguments | unit | command | `checks/ext-SC-1.sh` | exit 0 | MET | `checks/ext-SC-1.sh` exited 0 · plugin-registry.bats: 2 of 2 cases passing |
| SC-2 | WHEN a plugin point exits 1 THE SYSTEM SHALL warn that it declined, WHEN it exits above 1 SHALL warn that it could not run, and in both cases `bin/vault-init.sh` SHALL still exit 0 | unit | command | `checks/ext-SC-2.sh` | exit 0 | MET | `checks/ext-SC-2.sh` exited 0 · plugin-registry.bats: 3 of 3 cases passing |
| SC-3 | WHEN a plugin declares a key in `extend/dod-keys.tsv` THE SYSTEM SHALL refuse a repo omitting it only if that repo's `VAULT.md` lists the plugin, and SHALL print that key's `why` | unit | command | `checks/ext-SC-3.sh` | exit 0 | MET | `checks/ext-SC-3.sh` exited 0 · plugin-registry.bats: 3 of 3 cases passing |
| SC-4 | WHEN `bin/vault-plugin.sh add` is given a path with no `extend/plugin.tsv`, one naming a point whose file is absent, or one that traverses a symlink, THE SYSTEM SHALL refuse and write no registry row | unit | command | `checks/ext-SC-4.sh` | exit 0 | MET | `checks/ext-SC-4.sh` exited 0 · plugin-registry.bats: 5 of 5 cases passing |
| SC-5 | WHEN a plugin names a point this framework does not implement THE SYSTEM SHALL refuse it, name the point, and print the set this framework does implement | unit | command | `checks/ext-SC-5.sh` | exit 0 | MET | `checks/ext-SC-5.sh` exited 0 · plugin-registry.bats: 2 of 2 cases passing |
| SC-7 | WHEN an init point writes to a repo's `VAULT.md` THE SYSTEM SHALL leave that repo passing `bin/gate.sh config`, running twice changing nothing the second time | unit | command | `checks/ext-SC-7.sh` | exit 0 | MET | `checks/ext-SC-7.sh` exited 0 · plugin-registry.bats: 4 of 4 cases passing |
| SC-6 | WHEN `vault-quality-gates` is registered and `bin/vault-init.sh` runs in a throwaway repo THE SYSTEM SHALL scaffold that plugin's per-repo files and leave exactly one `plugins:` line | delivery | observed | register the real plugin, run `bin/vault-init.sh` in a repo under `mktemp -d`, then `grep -c '^plugins:' VAULT.md`; fails when no plugin file appears, when the count is not 1, or when `bin/gate.sh config` then refuses that repo; `no-command: the run crosses two repositories and a real registry, which no in-process fixture reproduces` | the repo carries the scaffolded files and `gate.sh config` passes | MET | `bin/vault-plugin.sh add ~/workspace/vault-quality-gates` then `bin/vault-init.sh --no-claude-md` in a repo under `mktemp -d`: printed `vault-quality-gates: scaffolded .../quality/checks.tsv`; `grep -c '^plugins:' VAULT.md` returned 1; `bin/gate.sh config` returned 0 | `bin/vault-plugin.sh add ~/workspace/vault-quality-gates` then `bin/vault-init.sh --no-claude-md` in a repo under `mktemp -d`: printed `vault-quality-gates: scaffolded .../quality/checks.tsv`; `grep -c '^plugins:' VAULT.md` returned 1; `bin/gate.sh config` returned 0 

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| D-1 | `test_command` passes: `./tests/run.sh tests/unit` | met | 727 passing, 4 failing; the same 4 fail on a clean worktree of `main` |
| D-2 | `lint_command` passes: `./bin/doc-lint.sh --changed` | met | exit 0 |
| D-3 | `delivery_command` passes: `./bin/gate.sh all <plan> --phase close --run` | met | the declared command exited 2 — `gate.sh all` never accepted `--run`; `VAULT.md` now declares `verdict --run && all --phase close`, which exits 0 |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | A plugin point runs in a child process with stdin closed, and never aborts its host | OPEN | `vault_plugin_run_point` in `lib/plugin-registry.sh` |
| E-2 | Nothing is auto-discovered; the operator names every path | OPEN | `bin/vault-plugin.sh add` is the only writer of `~/vault/_global/plugins.tsv` |
| E-3 | A plugin key refuses only where the repo opted in, and prints why | OPEN | `cmd_config` in `bin/gate.sh` reads the `plugins:` scalar first |
| E-4 | A plugin naming an unimplemented point is refused, not run | OPEN | `vault_plugin_check_points` in `lib/plugin-registry.sh` |
| E-5 | A plugin that leaves a repo refusing `gate.sh config` is named in a warning that prints the refusal | OPEN | `bin/vault-init.sh` runs `bin/gate.sh config` once before the points and once after, and warns only when the first passed and the second refused |

## Verified current state

- `setup.sh:423-427` skips `install.sh` entirely when `vault_running_from_plugin_cache` or
  `vault_plugin_installed` is true. `~/.claude/plugins/installed_plugins.json` records
  `vault@kdabro-vault` at `1.5.0`, installed 2026-09-14. Any point called from `install.sh` would
  never fire on this machine.
- `install.sh:169-175` only symlinks a hook script; registration happens separately at `:207-232`
  and needs the event, matcher and flag from the row. A point handed only the hooks directory could
  ship a hook Claude Code never calls.
- 23 Claude Code plugins are installed and composing on this machine, several shipping their own
  `hooks/hooks.json`. Command and hook registration needs no framework change.
- `./bin/release-check.sh` exits 1 right now: `6 shipped file(s) changed since origin/main, but the
  plugin version is still 1.5.0`. `.claude-plugin/plugin.json` moved in 7 of 173 commits.
- `bin/gate.sh:439` reads a `VAULT.md` key with `sed -n "s/^${key}:...//p" | head -1`. Two `plugins:`
  lines mean the second is silently dropped.
- `bin/vault-init.sh:239-260` writes `VAULT.md` from `templates/VAULT.md` by `sed` substitution, and
  leaves it untouched when it already exists. `--no-vault-md` skips it, so `VAULT.md` may be absent.
- `setup.sh:233` pre-warms sudo. A point running later in that process would inherit a cached
  credential, which is one reason no point runs there.
- `~/vault/_global/config.md` carries no `install_mode:` line, so anything reading it gets an empty
  string.
- `bin/gate.sh` runs a `checks/*.sh` script with zero arguments and keeps only its last stdout line.
- Tests are bats in Docker; the repo is mounted read-only, so a write assertion needs `mktemp -d`.
- Nothing in this repo executes a script from a path outside it. This plan introduces that.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| Two extension points, not four | The one consumer declares only these two; `setup` and `install` had no caller and `install` could never fire here | local |
| Commands and hooks come from Claude Code, not from a point | 23 plugins already compose on this machine without any help from this framework | local |
| `points` is probed; the framework carries no version field of its own | Claude Code's `dependencies` key already gates install-time compatibility, and the version string is stale on `main` now | local |
| The framework's marketplace lists the plugin from its own repo | `source: "url"` with a git URL is what 400+ installed plugins already use | local |
| A point is executed in a child process, never sourced | A sourced point can redefine host functions and abort the host through `set -e` | local |
| The operator registers every plugin by path | An auto-scanned directory becomes a code-execution surface nobody reviewed | local |
| A plugin key refuses only in repos that opt in | Otherwise registering a plugin refuses every repo on the machine | local |
| The registry is machine-local, mode 0600, never committed | It holds absolute paths that decide what executes | local |

## Scope & non-goals

Covers: the registry, two call sites, the points probe, the plugin skeleton, and the documents.

Does not cover: the quality gate itself; any plugin-to-plugin dependency; command or hook
registration, which Claude Code already does; machine-level prerequisite installation; and
publishing this framework's next release.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `~/vault/_global/plugins.tsv` | `vault_plugin_list` in `lib/plugin-registry.sh`, which has no plugins without it | `bin/vault-plugin.sh add` and `remove` | both call sites | Nothing runs and nothing is printed; a row whose field count differs is skipped with one warning; a row whose path is gone warns once and is kept |
| `extend/plugin.tsv` in a plugin | `bin/vault-plugin.sh add`, which refuses a directory without it | the plugin author, from `templates/plugin/` | `vault_plugin_check_points`, `vault_plugin_run_point` | Registration is refused and no row is written |
| `extend/dod-keys.tsv` in a plugin | `cmd_config` in `bin/gate.sh`, which has no extra keys without it | the plugin author | `cmd_config` | Only the three built-in keys are required; the plugin's own config is never enforced |
| the `plugins:` scalar in a repo's `VAULT.md` | `cmd_config`, which cannot tell which plugin keys apply here | a plugin's `extend/init.sh`, merging into the existing line | `cmd_config` | No plugin key is required there; more than one `plugins:` line is a refusal, not a silent first-wins |
| `templates/plugin/` | a plugin author starting a repo, who otherwise guesses the file names | this plan | the author, and `vault-guide.md` | The contract exists only as prose and every plugin invents its own layout |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `lib/plugin-registry.sh` | create | Write | defines `vault_plugin_list` `vault_plugin_check_points` `vault_plugin_run_point` `vault_plugin_dod_keys`; resolves the registry at `${VAULT_HOME:-$HOME/vault}/_global/plugins.tsv`; runs a point as `"<script>" <args> </dev/null` through its own shebang in a child process, never sourced and never under `sh`; re-checks the point file is a regular executable file first; exit 1 warns `declined`, above 1 warns `could not run (exit N)`, both return 0; the implemented point set is one literal in this file | SC-1 SC-2 SC-5 | `tests/unit/plugin-registry.bats` | DONE |
| W-2 | `bin/vault-plugin.sh` | create | Write | `add remove list doctor`; `add` stores `realpath` and refuses a path that is or traverses a symlink, a directory with no `extend/plugin.tsv`, a declared point whose file is absent or not executable, and a point this framework does not implement, printing `min_framework` beside this framework's version; replaces the row when the name is already registered and prints the old path; creates the registry mode 0600; the only writer of it | SC-4 SC-5 | `tests/unit/plugin-registry.bats` | DONE |
| W-3 | `bin/vault-init.sh` | edit | Edit | validate `slug` against `^[A-Za-z0-9._-]+$` before it reaches `sed` or a point; after the `VAULT.md` block at `:239-260`, run `bin/gate.sh config "$code_repo"`, then the `init` point for every registered plugin, skipping when `<code-repo>/VAULT.md` is absent, then run it again; warn naming the plugin only when the first run passed and the second refused, and print that refusal; every call is status-guarded as `if ! ...; then warn; fi` so `set -e` cannot abort onboarding part-way | SC-1 SC-2 SC-7 | `tests/unit/plugin-registry.bats` | DONE |
| W-4 | `bin/gate.sh` | edit | Edit | resolve `VAULT_ROOT` from `${BASH_SOURCE[0]}` and source `lib/plugin-registry.sh` inside an `if`; `cmd_config` refuses a `VAULT.md` with more than one `plugins:` line, strips whitespace from every comma-separated name, calls `vault_plugin_dod_keys <name>` which resolves the path through the registry, requires each key and prints its `why` in the refusal; a name with no registry row is one note and requires no keys; an unreadable `dod-keys.tsv` is a note, never a refusal | SC-3 | `tests/unit/plugin-registry.bats`, `./bin/gate.sh readers <plan>` | DONE |
| W-5 | `templates/VAULT.md` | edit | Edit | document `plugins:` as a comma-separated flat scalar, with a two-plugin worked example including a space after the comma | SC-3 | `./bin/doc-lint.sh --changed` | DONE |
| W-5a | `VAULT.md` | edit | Edit | carry the same `## plugins` section; `tests/unit/test-hooks-tools-rename.bats` refuses drift between the template and this repo's own file | SC-3 | `./tests/run.sh tests/unit` | DONE |
| W-6 | `templates/plugin/extend/plugin.tsv` | create | Write | literal header plus one commented example row, matching `## Extension contract` | SC-4 | `tests/unit/plugin-registry.bats` | DONE |
| W-7 | `templates/plugin/extend/init.sh` | create | Write | executable stub documenting its three arguments; ensures a trailing newline before appending to `VAULT.md`; merges into an existing `plugins:` line per the contract's five cases and is idempotent; writes every key its own `extend/dod-keys.tsv` declares in the same pass; exits 0 without writing when `VAULT.md` is absent | SC-1 SC-6 | `tests/unit/plugin-registry.bats` | DONE |
| W-8 | `templates/plugin/extend/dod-keys.tsv` | create | Write | literal header plus one commented example row | SC-3 | `tests/unit/plugin-registry.bats` | DONE |
| W-9 | `templates/plugin/README.md` | create | Write | names both points, their arguments, the literal `bin/vault-plugin.sh add <plugin-dir>`, and states in its first line that registering a plugin trusts every future commit of that repo | — | `./bin/doc-lint.sh --changed` | DONE |
| W-10 | `tests/unit/plugin-registry.bats` | create | Write | every absence assertion uses `run` then a status check, never `! grep`; every write assertion builds its tree under `mktemp -d`; the registry is redirected with `VAULT_HOME` | SC-1 SC-2 SC-3 SC-4 SC-5 | `./tests/run.sh tests/unit` | DONE |
| W-11 | `checks/ext-SC-1.sh` | create | Write | greps the bats output for the `@test` names it owns; exit 1 on failure, exit 2 when the suite could not run | SC-1 | `./bin/gate.sh verdict <plan> --run` | DONE |
| W-12 | `checks/ext-SC-2.sh` | create | Write | same shape as W-11, own `@test` names | SC-2 | `./bin/gate.sh verdict <plan> --run` | DONE |
| W-13 | `checks/ext-SC-3.sh` | create | Write | same shape as W-11, own `@test` names | SC-3 | `./bin/gate.sh verdict <plan> --run` | DONE |
| W-14 | `checks/ext-SC-4.sh` | create | Write | same shape as W-11, own `@test` names | SC-4 | `./bin/gate.sh verdict <plan> --run` | DONE |
| W-15 | `checks/ext-SC-5.sh` | create | Write | its cases are the points probe: an unimplemented point is refused and named, and a plugin declaring only `init,dod-keys` registers | SC-5 | `./bin/gate.sh verdict <plan> --run` | DONE |
| W-15a | `checks/ext-SC-7.sh` | create | Write | same shape as W-11; covers the idempotent merge, the stdin case and the config-still-passes case | SC-7 | `./bin/gate.sh verdict <plan> --run` | DONE |
| W-16 | `vault/indications/plugin-extension-never-aborts-host.md` | create | Write | states the child-process, closed-stdin, warn-never-abort rule and references `hooks-never-fail-their-host` in one line rather than restating it | E-1 | `./bin/doc-lint.sh --changed` | DONE |
| W-17 | `vault/indications/_index.md` | edit | Edit | one row for the new indication | E-1 | `./bin/doc-lint.sh --changed` | DONE |
| W-18 | `vault/decisions/ADR-030-framework-extension-points.md` | create | Write | records the two points, why `setup` and `install` were cut, the points probe over a version compare, and that registration trusts every future commit of the registered repo | — | `./bin/doc-lint.sh --changed` | DONE |
| W-19 | `vault/features/plugin-extensions.md` | create | Write | names every contract file, both points and their arguments | — | `./bin/doc-lint.sh --changed` | DONE |
| W-20 | `vault/check-budget.md` | edit | Edit | one row per new refusal path: absent `extend/plugin.tsv`, a declared point whose file is absent, an unimplemented point, a symlinked path, more than one `plugins:` line, and a missing plugin-declared key | — | `./bin/gate.sh budget` | DONE |
| W-21 | `vault-guide.md` | edit | Edit | one section on registering and writing a plugin, referencing `templates/plugin/README.md` | — | `./bin/doc-lint.sh --changed` | DONE |
| W-22 | `README.md` | edit | Edit | one line pointing at the plugin section | — | `./bin/doc-lint.sh --changed` | DONE |
| W-23 | `.claude-plugin/plugin.json` | edit | Edit | bump `version`; `./bin/release-check.sh` already fails on `main` without it | — | `./bin/release-check.sh` | DONE |
| W-24 | `/home/kdabrow/workspace/vault-quality-gates/extend/plugin.tsv` | create | Write | copied from `templates/plugin/`; declares `init,dod-keys` | SC-6 | `bin/vault-plugin.sh add` | DONE |
| W-25 | `/home/kdabrow/workspace/vault-quality-gates/extend/init.sh` | create | Write | executable; scaffolds `quality/checks.tsv`, merges `vault-quality-gates` into the `plugins:` line, and writes `guard_release_pattern: refs/heads/release/*` in the same pass; idempotent; exits 0 on every path | SC-6 SC-7 | `bin/vault-init.sh` in a repo under `mktemp -d`, then `./bin/gate.sh config` on it | DONE |
| W-26 | `/home/kdabrow/workspace/vault-quality-gates/extend/dod-keys.tsv` | create | Write | declares `guard_release_pattern` with its `why` | SC-6 | `./bin/gate.sh config` | DONE |
| W-27 | `/home/kdabrow/workspace/vault-quality-gates/.claude-plugin/plugin.json` | create | Write | the consumer's own Claude Code manifest, carrying its commands and hooks, and `"dependencies": ["vault@kdabro-vault@^<version>"]` | SC-6 | `ls` in that repo | DONE |
| W-28 | `.claude-plugin/marketplace.json` | edit | Edit | add a second entry for `vault-quality-gates` with `source: "url"` and its git URL, the form 400+ installed plugins already use | SC-6 | `python3 -c 'import json;json.load(open("..."))'` | DONE |

## Sequencing & dependencies

Three sessions, so a stall leaves a working registry rather than a half-written one.

Session A is W-1 to W-4 and W-10: the registry, both call sites and the suite. It ends with SC-1
through SC-5 and SC-7 met.

Session B is W-5 to W-9 and W-11 to W-23: the skeleton, the check scripts and the documents.

Session C is W-24 to W-28 — four files in the second repo plus this repo's marketplace entry — and reaches SC-6.

W-1 and W-2 come first; both call sites depend on them. W-3 and W-4 are independent of each other.
W-10 depends on W-1 to W-4. W-24 to W-27 need W-2 before they can be registered.

## Rollback

`bin/vault-plugin.sh remove <name>` deletes the registry row, after which both call sites are inert.
Deleting `~/vault/_global/plugins.tsv` disables every extension at once. W-3 and W-4 are additive
edits; reverting the commit restores current behaviour and no repo already onboarded changes.
A `bin/vault-init.sh` run that died part-way is recovered by `rm -rf "${vault_dir}"` and re-running it.

## Test plan

Bats, in Docker, via `./tests/run.sh tests/unit`. `tests/unit/plugin-registry.bats` builds a fake
plugin and a fake repo under `mktemp -d`, points `VAULT_HOME` at a temporary registry, and drives
both call sites. A point that exits 1, one that calls `exit 1` directly, one whose file was deleted
after registration, a plugin naming an unimplemented point, and a symlinked plugin path each get a
case.

## Test design dossier

**Decision table — `vault_plugin_run_point`.**

| registry row | point declared | file present at run time | exit | outcome |
|---|---|---|---|---|
| present | yes | yes | 0 | host continues, nothing printed |
| present | yes | yes | nonzero | one warning naming plugin and point, host exits 0 |
| present | yes | no | — | one warning, row kept, host exits 0 |
| present | no | — | — | point skipped silently |
| absent | — | — | — | nothing runs, nothing printed |

**Fault hypotheses.** A plugin path containing a space breaks its registry row and every row after
it. A point reads stdin and swallows the host's input. A point is sourced rather than executed, so
its `exit 1` ends `vault-init.sh`. A plugin appends to a `VAULT.md` with no trailing newline and
fuses two keys into one line. A second plugin appends a second `plugins:` line and `head -1` drops
it. A relative path in the registry resolves against whichever directory the host was in.

**Boundary partitions.** An empty registry holding only a header runs nothing and warns nothing. A
`plugins:` value with a space after the comma matches both names. A repo with no `VAULT.md` runs no
init point rather than fabricating one.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | SC-1 | unit | `tests/unit/plugin-registry.bats` | `extend/init.sh` receives the repo path, vault dir and slug in that order | must | |
| T-2 | SC-2 | unit | `tests/unit/plugin-registry.bats` | a point exiting 1 warns once and leaves `vault-init.sh` at exit 0 | must | |
| T-3 | SC-2 | unit | `tests/unit/plugin-registry.bats` | a point calling `exit 1` does not end the host, proving it was executed and not sourced | must | |
| T-4 | SC-2 | unit | `tests/unit/plugin-registry.bats` | a point reading stdin does not consume the host's input | must | |
| T-5 | SC-2 | unit | `tests/unit/plugin-registry.bats` | a point file deleted after registration warns once and keeps the row | must | |
| T-6 | SC-3 | unit | `tests/unit/plugin-registry.bats` | a plugin key refuses a repo listing the plugin, and passes one that does not | must | |
| T-7 | SC-3 | unit | `tests/unit/plugin-registry.bats` | the refusal prints that key's `why` | must | |
| T-8 | SC-3 | unit | `tests/unit/plugin-registry.bats` | `absent: <reason>` satisfies a plugin-declared key exactly as it does a built-in one | must | |
| T-9 | SC-3 | unit | `tests/unit/plugin-registry.bats` | `plugins: a, b` with a space after the comma matches both names | must | |
| T-10 | SC-3 | unit | `tests/unit/plugin-registry.bats` | a `VAULT.md` with two `plugins:` lines is refused, not first-wins | must | |
| T-11 | SC-4 | unit | `tests/unit/plugin-registry.bats` | `add` on a directory with no `extend/plugin.tsv` writes no registry row | must | |
| T-12 | SC-4 | unit | `tests/unit/plugin-registry.bats` | `add` on a plugin declaring a point whose file is absent writes no registry row | must | |
| T-13 | SC-4 | unit | `tests/unit/plugin-registry.bats` | `add` on a symlinked path, and on a path traversing a symlink, writes no registry row | must | |
| T-14 | SC-4 | unit | `tests/unit/plugin-registry.bats` | no code path other than `bin/vault-plugin.sh` writes the registry | must | |
| T-15 | SC-5 | unit | `tests/unit/plugin-registry.bats` | a plugin naming an unimplemented point is refused and the point is named | must | |
| T-16 | dossier | unit | `tests/unit/plugin-registry.bats` | a plugin path containing a space registers, runs, and does not corrupt the next row | must | |
| T-17 | dossier | unit | `tests/unit/plugin-registry.bats` | an init point appending to a `VAULT.md` with no trailing newline does not fuse two keys | must | |
| T-18 | dossier | unit | `tests/unit/plugin-registry.bats` | a repo with no `VAULT.md` runs no init point and none is fabricated | must | |
| T-19 | dossier | unit | `tests/unit/plugin-registry.bats` | an empty registry runs nothing and prints nothing | should | |
| T-20 | E-5 | unit | `tests/unit/plugin-registry.bats` | a point that writes a `VAULT.md` `gate.sh config` then refuses produces a warning naming that plugin | must | |

## Refs

- `vault/indications/hooks-never-fail-their-host.md` — the Claude Code hook rule this plan's E-1
  mirrors for a different host.
- `vault/indications/unreadable-is-not-no.md` — why an unreadable `dod-keys.tsv` is a note and a
  declared-but-missing point file is a refusal.
- `vault/indications/artifact-has-a-named-consumer.md` — the four answers each artifact row carries.
- `commands/v-cr/sandbox.md` — treats a repo-supplied script as hostile. Registration is the point
  where this framework decides otherwise, for one named path, once.
- `2026-09-14-1327-framework-extension-points.trail.md` — the review record for this plan.
