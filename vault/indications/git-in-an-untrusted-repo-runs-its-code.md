---
type: indication
project: vault
slug: git-in-an-untrusted-repo-runs-its-code
scope: repo
tags: [indication, security, git, probes]
---

# git-in-an-untrusted-repo-runs-its-code

## Rule
Call git on a repo you do not trust only through `probe_git` in `lib/probe-scope.sh`. It switches off the
repo's fsmonitor, hooks, attributes file, lazy fetch and network protocols, and replaces every filter
command in the repo's config. Recognition test: `tests/unit/probe.bats` T-20, T-29 and T-29b pass.

## Rationale
Four routes ran a repo's own command during a plain file listing or comparison: `core.fsmonitor`, a
`filter.<name>.clean` command, lazy fetch through `remote.origin.uploadpack`, and hooks. A `-c key=value`
override splits at the first `=`, so a filter named `a=b` escaped it; the overrides travel in
`GIT_CONFIG_KEY_n` variables. ADR-009 says `/v-cr` never runs pull-request code outside its sandbox.

## Examples
- Do: list changed files with `probe_changed`, which returns 2 when git fails.
- Don't: run `git diff` or `git ls-files` directly inside a repo a pull request supplied.

## Applies-to
`lib/probe-scope.sh`, `bin/probe.sh`, and any later script that runs git in a repo under review.
