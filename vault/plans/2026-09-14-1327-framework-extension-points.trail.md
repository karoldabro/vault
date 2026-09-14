---
type: trail
project: vault
plan: 2026-09-14-1327-framework-extension-points
tags: [trail, record]
---

# 2026-09-14-1327-framework-extension-points — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-14-1327-framework-extension-points.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Two extension points, `init` and `dod-keys` | Four points, adding `setup` and `install` | The one consumer declares neither. `setup.sh:423-427` skips `install.sh` whenever the framework is plugin-installed, which is this machine's mode, so an `install` point could never fire here. |
| Commands and Claude Code hooks come from the plugin's own manifest | A `commands` point feeding `link_tree`, and an `install` point feeding `HOOK_ROWS` | 23 plugins already compose on this machine, each shipping its own commands and `hooks/hooks.json`. A parallel mechanism would duplicate a working one. |
| `points` is probed against what the framework implements | `min_framework` compared as three dotted numbers | `./bin/release-check.sh` exits 1 on `main` right now: six shipped files changed and the version is still `1.5.0`. It moved in 7 of 173 commits, so it cannot answer whether a point exists. |
| A point is executed through its own shebang as `"<script>" <args> </dev/null` | Sourcing it, or running it as `sh <script>` | A sourced point redefines the host's functions and ends `vault-init.sh` when it calls `exit 1`. Forcing `sh` runs a bash or python point under `dash`, and the syntax error then reads as a plugin that declined. |
| `extend/dod-keys.tsv` carries `key` and `why` | A third `profile` column | Nothing read `profile`. `bin/gate.sh` has `cmd_readers` precisely to refuse a field with no reader. |
| A plugin merges into the existing `plugins:` line | Appending its own line | `bin/gate.sh:439` reads the key with `head -1`, so a second line is silently dropped and that plugin's keys are never required. |
| The registry stores `realpath` and refuses symlinked paths | Storing the path as given | A path validated once and executed later can be swapped underneath. The stored real path narrows that window; it does not close it. |

## Findings & dispositions

### Round 1

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| skeptic | 1 | BLOCKER | confirmed | the install point could symlink a hook but never register its event, so Claude Code would never call it | applied — point deleted |
| skeptic | 2 | BLOCKER | confirmed | `setup.sh` skips `install.sh` in plugin mode, so the install point could never fire on this machine | applied — point deleted |
| architect | 1 | BLOCKER | confirmed | the plan built two points its only consumer does not declare | applied — both deleted |
| architect | 2 | BLOCKER | confirmed | the install point never fires in the install mode this machine uses | applied — point deleted |
| consumer | 1 | BLOCKER | confirmed | the plan never said whether a point is executed or sourced, and the stub aborts the host under one | applied — child process, stdin closed, T-3 |
| consumer | 2 | BLOCKER | confirmed | the registry file's columns, header and separator were never stated | applied — written into the contract |
| consumer | 3 | BLOCKER | confirmed | the init point appended to a `VAULT.md` that may not exist, fabricating one that blocks every later session | applied — skipped when absent, W-3 and W-7 |
| security | 1 | BLOCKER | confirmed | a plugin `setup.sh` would run after `setup.sh:233` cached sudo, so `sudo -n` inside it succeeds unprompted | applied — the setup point is deleted, so the window does not exist |
| skeptic | 4 | MAJOR | confirmed | the consumer's largest framework-side need is five command files and no point carried a command | applied — commands ship in the plugin's own Claude Code manifest |
| skeptic | 5 | MAJOR | confirmed | `min_framework` compares a version stale on `main` that moved 7 times in 173 commits | applied — `points` probe; the version is printed only |
| skeptic | 6 | MAJOR | confirmed | two plugins each appending a `plugins:` line means `head -1` drops the second | applied — merge, and more than one line is a refusal |
| skeptic | 3 | MAJOR | confirmed | the setup point had no consumer content and its `install_mode` argument reads empty | applied — point deleted |
| skeptic | 7 | MAJOR | confirmed | four new refusal paths and no row in the register that decides when a refusing check is deleted | applied — W-20 |
| security | 2 | MAJOR | confirmed | `link_one` does not refuse a symlink, so an install point could repoint a shipped hook at its own script | applied — the install point is deleted |
| security | 3 | MAJOR | confirmed | appending to a `VAULT.md` with no trailing newline fuses two keys and `gate.sh config` accepts it | applied — W-7 ensures the newline, W-3 re-runs `gate.sh config` and warns naming the plugin |
| security | 4 | MAJOR | confirmed | the plan specified both plugin files byte for byte and never the registry row, the one file that decides what executes | applied — header written into the contract |
| security | 5 | MAJOR | confirmed | `add` validated a path once and nothing revalidated it at run time | applied — `realpath`, symlink refusal, and a regular-file re-check before each run |
| security | 6 | MAJOR | confirmed | the plan left open whether a point is sourced into the host shell | applied — same fix as consumer-1 |
| consumer | 4 | MAJOR | confirmed | a space after the comma made the second plugin's name unmatchable | applied — W-4 strips whitespace; W-5's example carries the space |
| consumer | 6 | MAJOR | confirmed | the `profile` column had no legal values and `why` had no reader | applied — `profile` dropped, `why` printed in the refusal |
| consumer | 8 | MAJOR | confirmed | `gate.sh` had no way to find the registry | applied — `${VAULT_HOME:-$HOME/vault}/_global/plugins.tsv` |
| architect | 3 | MAJOR | confirmed | Claude Code already composes commands and hooks across plugins | applied — the open row is closed with the evidence |
| skeptic | 8 | MINOR | confirmed | `profile` had no reader in any work item | applied — dropped |
| skeptic | 9 | MINOR | confirmed | the two TSV formats inherited none of the parsing rules written for the consumer's TSVs | applied — stated once in the contract |
| skeptic | 10 | MINOR | confirmed | the open question about Claude Code composition was answered by 23 plugins already composing | applied — row closed |
| security | 7 | MINOR | confirmed | `slug` is an unvalidated directory basename that already breaks `vault-init.sh`'s own `sed` | applied — W-3 validates it |
| security | 8 | MINOR | confirmed | the registry would inherit umask 002 and be created group-writable | applied — mode 0600 |
| security | 9 | MINOR | confirmed | the plan cited `sandbox.md` as settling a question the two documents answer oppositely | applied — W-18 and W-9 state that registration trusts every future commit |
| skeptic | 11 | NIT | confirmed | SC-6 was marked blocked on a git remote it does not need | applied — the repo exists and SC-6 runs locally |

### Round 2

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| skeptic | 2-1 | BLOCKER | confirmed | `sh "<script>"` runs a bash or python point under `dash`, and the crash is then downgraded to a warning | applied — the point runs through its own shebang, and a non-executable point file is refused at registration |
| skeptic | 2-2 | BLOCKER | confirmed | the consumer's init point makes its own key required and never writes it, so `gate.sh config` refuses the repo it just onboarded | applied — a point adding its name must write its own declared keys in the same pass; W-25, SC-7 |
| consumer | 2-1 | BLOCKER | confirmed | same defect, found independently | applied — same fix |
| skeptic | 2-3 | BLOCKER | confirmed | `gate.sh config` exiting 1 under `set -e` aborts `vault-init.sh` after the vault directory exists and before the CLAUDE.md snippet | applied — every call is status-guarded, and Rollback names the recovery |
| consumer | 2-2 | BLOCKER | confirmed | `bin/gate.sh` sources no library and computes no framework root, so `cmd_config` cannot reach `vault_plugin_dod_keys` | applied — W-4 resolves `VAULT_ROOT` and sources the library inside an `if` |
| consumer | 2-3 | BLOCKER | confirmed | the merge was named and never specified, so two authors would write two incompatible mergers | applied — five cases with required outcomes, in the contract |
| skeptic | 2-4 | MAJOR | confirmed | the re-run blamed the plugin for refusals that predate it | applied — run before and after, warn only when the first passed |
| skeptic | 2-5 | MAJOR | confirmed | `checks/ext-SC-5.sh` asserted the version compare the rewrite deleted | applied — reset to TODO and its cases rewritten to the probe |
| skeptic | 2-6 | MAJOR | confirmed | nine backlog rows had no check script | applied — SC-7 and `checks/ext-SC-7.sh` |
| skeptic | 2-7 | MAJOR | confirmed | no work item creates the consumer's own Claude Code manifest, which the commands answer depends on | applied — W-27 |
| skeptic | 2-8 | MAJOR | confirmed | the contract treated "declined" and "could not run" as one warning | applied — exit 1 against above 1, distinct strings |
| consumer | 2-6 | MAJOR | confirmed | a `plugins:` name with no registry row had no defined behaviour | applied — one note, no keys required, never a refusal |
| consumer | 2-7 | MAJOR | confirmed | `add` on an already-registered name had no defined behaviour | applied — replaces the row and prints the old path |
| consumer | 2-8 | MAJOR | confirmed | E-5 promised an outcome and named a mechanism that only reports it failing | applied — rewritten as a warning guarantee |
| consumer | 2-4 | MAJOR | confirmed | `registered_at` had no format, no reader and no writer | applied — column deleted |
| consumer | 2-5 | MAJOR | confirmed | `version` had no reader and `min_framework` no value an author could look up | applied — `version` deleted; `min_framework` is `-` when unknown and printed by `doctor` |
| skeptic | 2-9 | MINOR | confirmed | an operator on an older framework saw no hint that upgrading is the fix | applied — SC-5's refusal prints both versions |
| skeptic | 2-11 | MINOR | confirmed | nothing recorded that W-4 is what clears the close gate's `readers` refusal | applied — added to W-4's verification |
| skeptic | 2-12 | MINOR | confirmed | 26 items is larger than any plan this repo has finished | applied — three named sessions |

## Metrics

Round 1: four reviewers, 42 findings, all confirmed, 8 confirmed blockers, all applied. The rewrite
deleted two of four extension points and five work items.
Round 2: two reviewers, 19 new findings, all confirmed, 6 confirmed blockers, all applied.
The loop stopped on the round cap, so the round-2 fixes were never reviewed.

## Advisory test hints

## Rejected / deferred

- **A `min_framework` field in `extend/plugin.tsv`.** Claude Code's plugin manifest already defines
  `dependencies`, "Plugins that must be enabled for this plugin to function", whose name pattern
  accepts an `@^` version constraint. Inventing a second version field here would have given the
  operator two places to state one requirement, one of them unenforced.

- **A `commands` extension point** feeding `install.sh`'s `link_tree`. It would install a plugin's
  slash commands the way this framework installs its own. Claude Code already does this for any
  plugin with its own manifest, and `install.sh` does not run at all in plugin-install mode.
- **A `setup` point** for machine-level prerequisites. The one consumer needs `jscpd` and
  `diff-cover`, neither of which appears in any of its work items. Revisit when a consumer names a
  machine-level file it must write.
- **Comparing `min_framework` numerically.** It reads as the obvious compatibility check and would
  give a wrong answer today, because the version on `main` is stale and moves roughly once per
  twenty-five commits.
