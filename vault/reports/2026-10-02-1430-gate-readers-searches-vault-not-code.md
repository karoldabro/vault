---
type: report
project: vault
slug: gate-readers-searches-vault-not-code
date: 2026-10-02
status: fixed
severity: major
found_by: bin/gate.sh all --phase close
found_in: closing S1 of the givore-video-loop plan in agent-control, whose vault lives in ~/vault/agent-control
files: [bin/gate.sh]
tags: [report, gate]
---

# gate-readers-searches-vault-not-code — report

## What is wrong

`bin/gate.sh` `cmd_readers` searches the plan's own git repo for code that reads each `## Artifact lifecycles` identifier. For a vault outside the code repo, that repo is the vault, so every bare identifier is refused.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `bin/gate.sh` | `checks_root` returns `git -C <plan dir> rev-parse --show-toplevel`; `cmd_readers` greps that root for readers and resolves declared paths against it, so `~/...` paths are reported missing |

## Consequence

Already happened. The close gate on `~/vault/agent-control/plans/2026-10-02-1500-givore-video-loop.md` refused `creatives`, `effects` and two more identifiers. All of them have readers in `~/workspace/agent-control/agent_control/`. It also noted that `~/agent-factory/video-loop.json` and `VIDEO_LOOP.md` do not exist, although both exist. Every plan in a global `~/vault/<slug>/` vault with an artifact table fails its close gate.

## Cause

`checks_root` serves two jobs: locating `checks/` scripts, which live in the vault, and locating code, which lives in the repos named by the plan's `repos:` frontmatter or `VAULT.md`. `cmd_readers` uses it for the second job. A `~` in a declared path is not expanded.

## How to see it

```bash
F=~/.claude/plugins/cache/kdabro-vault/vault/1.11.0
$F/bin/gate.sh all ~/vault/agent-control/plans/2026-10-02-1500-givore-video-loop.md --phase close
# REFUSED `creatives` is declared and no code reads it
grep -rIl --exclude-dir=.git --exclude='*.md' -e creatives ~/workspace/agent-control | head -3
```

## Repair

`/v-do` in `~/workspace/vault`. Add a `code_roots` helper that maps the plan's `repos:` entries to repo paths. It reads `~/vault/_global/config.md` or the repo whose `VAULT.md` names this vault, and falls back to `checks_root`. `cmd_readers` greps every code root and expands a leading `~` before the existence check. Add a test: a vault repo and a separate code repo, an identifier read only in the code repo, gate exits 0.

## Not now because

The defect is in the vault framework, outside the agent-control video-loop work that hit it.

## Closes when

`gate.sh all <plan> --phase close` on the givore-video-loop plan reports no reader refusal while `creatives` is read in `~/workspace/agent-control`. The framework suite has the two-repo test passing.
