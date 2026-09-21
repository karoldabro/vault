---
type: trail
project: vault
plan: 2026-09-21-1330-probe-panel-input
tags: [trail, record]
---

# 2026-09-21-1330-probe-panel-input — process record

Record class. Its contract document is `plans/2026-09-21-1330-probe-panel-input.md`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| one helper runs the kit once per round and hands every critic the same block | each critic runs `bin/probe.sh diff` itself | N runs cost N times, and critics could see different status |
| exit 2 prints `INCOMPLETE` and the review continues | exit 2 blocks the review | the kit exits 2 on this machine today, so every review would block |
| `own` posture runs the repo registry unless the diff edits it | `own` never runs it, or always runs it | never breaks contract C-6; always lets an agent-written row run in its own review |
| origin read from `bin/probe.sh list` | add an origin field to the finding row | C-2 forbids changing the row shape |
| cap in rows and bytes | rows only | a long file path defeats a row cap |
| `own` skips repo code unless the operator opts in | `own` runs it always | a diff can plant a tool directory or edit a script that a committed registry row calls, and the probe runs it unread on every round |
| `--base` required | default `HEAD` | it misses committed work and reports a complete run with no rows |

## Findings & dispositions

### Round 1

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| security | security-1, security-2 | BLOCKER | confirmed | under `own` a planted tool directory or an edited script called by a committed registry row runs | applied: D-1 states that an `own` session already runs repo code; repo rows are advisory |
| security | security-3, security-4 | MAJOR | confirmed | the diff-edits-registry rule misses a symlinked `probes/` and a committed registry | applied: rule removed |
| security | security-5, correctness-3, consumer-1 | MAJOR | confirmed | a repo row can reuse a framework id, so origin by id is forgeable | applied: D-3, an id any repo defines is advisory |
| security | security-6 | MAJOR | confirmed | a file name passes the fence unescaped | applied: D-4 all fields, 200 byte cut |
| security | security-7 | MINOR | confirmed | repo install text reaches the operator line | applied: D-2 |
| correctness | correctness-1 | BLOCKER | confirmed | `--base HEAD` misses committed work | applied: D-1, `--base` required |
| correctness | correctness-2 | MAJOR | confirmed | skipped probes read as complete | applied: D-2 |
| correctness | correctness-4 | MAJOR | confirmed | the audit cannot find a repo registry from a global vault | applied: D-7 |
| consumer | consumer-2 | MAJOR | confirmed | `/v-cr` without a checkout probes the wrong tree | applied: D-1 |
| consumer | consumer-3, consumer-5, consumer-6 | MAJOR | confirmed | operator line and helper syntax underspecified | applied: D-2, D-9 |
| consumer | consumer-4 | MAJOR | confirmed | `/v-work` has no verify stage | applied: D-5, D-6 |
| correctness | correctness-5, correctness-7, consumer-7, consumer-8 | MINOR | confirmed | wrong claim in Verified state, exit-code mapping, unnamed SC-6 sentence | applied |
| correctness | correctness-6 | MINOR | confirmed | `checks/indication-routing-SC-4.sh` fails on `HEAD` | applied: Open & deferred, W-9 verification |

### Round 2

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| security | security-r2-1 | MAJOR | confirmed | replacing `<<<` by `<< <` leaves `>>>` inside a run of four `>` | applied: D-4 random fence token |
| security | security-r2-2 | MAJOR | confirmed | `own` still runs diff-supplied repo code with nobody reading the diff | applied: D-1 default is `--no-repo-code`, opt-in by `PROBE_PANEL_REPO_CODE=yes`; the operator confirms at the gate |
| security | security-r2-3, security-r2-4 | MINOR | confirmed, advisory | install text taken from stderr; `cited` arguments unvalidated | applied: D-2, D-9 |
| correctness | correctness-r2-1 | MAJOR | confirmed | in the framework repo an agent-added registry row is labelled framework origin | applied: D-3 `registry-edited` makes every row advisory |
| correctness | correctness-r2-2, -3, -4 | MINOR | confirmed, advisory | bad `--base` shows no cause; audit fallback finds a stray registry; `mktemp` directory cleanup | applied: D-2, D-7, D-9 |
| consumer | consumer-r2-1 | MAJOR | confirmed | `--base` has no source in any step | applied: D-1 records `PROBE_BASE` in three steps |
| consumer | consumer-r2-2 to -5 | MINOR | confirmed, advisory | posture skips read as a failure; `list` flag under `pr`; unnamed SC-6 sentence; fence contents | applied: D-2, D-3, W-6, D-9 |

