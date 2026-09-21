---
type: trail
project: vault
plan: 2026-09-21-1800-plan-time-probes
tags: [trail, record]
---

# plan-time-probes — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-21-1800-plan-time-probes.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Auditors return block rows with a verdict | auditors run their own `--names` queries and add rows | a row an auditor adds has no tool run behind it that the orchestrator can check, so it could not carry `[confirmed]` |
| The stage filters rows with `--paths` | a `--max-cost S` run that skips the M probes | every skipped probe prints a `skipped:` line, so the block would read INCOMPLETE on every run |
| `spec-symbols` lives in `probes/similar-symbols.sh` | a new `probes/spec-symbols.sh` | it needs the same Reuse-map reader, and a second reader would be the fourth table reader |
| Constants live in `bin/plan-probes.sh` settings | a `probes/plan-cost.tsv` data file | one more file past the size threshold; the kit already documents environment settings with defaults |
| No path filter at the plan stage | `--paths` keeps rows of files the spec lists | the useful reuse rows point at code the spec does not list, so the filter dropped 13 of 14 real rows |
| The panel runs before `budget` | `budget` first, from an estimated block size | the block file exists only after the panel runs, and the panel costs no model tokens |
| `verify` compares whole rows | `verify` calls `cited`, which matches probe, file and line | an auditor could keep the key and rewrite severity or message, and `012` matches line 12 |
| One auditor now, two in S11 | three auditors now | the `sql-*` probes ignore the spec and cannot fire in this repo, so two auditors would have nothing to read |

## Findings & dispositions

### Round 1

Three reviewers (architect, consumer, skeptic) ran once. The plan was revised once and not re-reviewed.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-1 | BLOCKER | confirmed | three `budget` inputs have no source at step (b2) and the flow runs `budget` before the block exists | applied: panel first, named flags, PT-3, W-8, W-13 |
| architect, consumer | architect-1, consumer-2 | MAJOR | confirmed | the path filter drops 13 of 14 real reuse rows | applied: no filter, PT-1, SC-1 |
| architect, consumer, skeptic | architect-4, consumer-3, skeptic-3 | MAJOR | confirmed | `cited` checks three fields; the return line and its writer are undefined | applied: PT-2, W-8, SC-3, the `auditor-reuse.tsv` row |
| architect, consumer, skeptic | architect-5, consumer-4, skeptic-4 | MAJOR | confirmed | a spec outside the repo has an absolute path the core rejects | applied: PT-9, SC-2, Q-2 |
| skeptic | skeptic-1 | MAJOR | confirmed | the cell split is undefined and 2 of 29 real cells would give false errors | applied: PT-9, SC-2, W-2 |
| skeptic | skeptic-2 | MAJOR | confirmed | a wrong confirmed error row traps the session | applied: operator accepts a named open row at the gate, PT-2 |
| skeptic, consumer | skeptic-5, consumer-5 | MAJOR | confirmed | the 50% limit cannot bind | applied: stated as an accepted limit and proven on synthetic inputs, SC-4 |
| architect | architect-6 | MAJOR | confirmed | 17 paths passes the split threshold | deferred: S11 takes part of the scope; minority flag at the gate |
| architect | architect-2 | MAJOR | confirmed | the arch gate owns Reuse-map rows | rejected: the gate is form-only by design; minority flag at the gate |
| architect | architect-7 | MINOR | confirmed | two auditors and three probes cannot fire here | applied: one auditor, PT-1, PT-5 |
| architect, skeptic | architect-8, skeptic-6, skeptic-7 | MINOR | confirmed | `--posture`, `--base` and exit-code merging of the plan stage | applied: W-9, SC-1 |
| architect | architect-9 | MINOR | confirmed | `plan-probes.md` restates block rules | applied: PT-8, W-12 |
| architect | architect-10 | MINOR | confirmed | a missing stopword causes the noise | applied: W-10 |
| consumer | consumer-6, -7, -8 | MINOR | advisory | note emitters, `measure` window, falsifier of HALF-BUILT | applied: PT-4, Open & deferred, E-1 with `tier.txt` |
| skeptic | skeptic-8, -9, -10 | MINOR | confirmed | branch order in `similar-symbols.sh`, detect cell, projected round term | applied: PT-9, W-11, W-8 |

### Round 2 — review of the implementation

Two reviewers (correctness, security) read the diff once. Every confirmed finding was fixed, and the graders and the unit cases were extended.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| correctness | correctness-1 | MAJOR | confirmed | `./src/a.js`, `:42`, `#L3` and a trailing colon in a Reuse-map path gave a false error row | applied: path normalisation, T-15 |
| correctness | correctness-2, -3, -7 | MINOR | confirmed | escaped pipe, heading variants, missing column, a directory as spec, an oversized token | applied: `reuse-map-unreadable`, `-f` check, 200-character cap, T-16 |
| correctness | correctness-4 | MINOR | confirmed | large settings overflowed 64-bit arithmetic; a base of 0 divided by zero | applied: per-value maxima, base of at least 1, T-17 |
| correctness | correctness-5, -6 | MINOR | confirmed | a last line with no newline was skipped; `--base` and `--paths` accepted at the plan stage; one bad usage field aborted `measure` | applied |
| security | security-1, -7 | MINOR | confirmed | `tier.txt` written through a symlink; `mkdir` without `--`; predictable temp name | applied: symlink refusal, `mkdir -p --`, `mktemp` |
| security | security-2, -3 | MINOR | confirmed | control bytes in a file name, in kept lines and in `open:` fields reached the terminal | applied: `clean` and `strip` |
| security | security-4 | NIT | advisory | the auditor envelope had no marker around the rows | applied: markers and an ignore line |
| security | security-5, -6 | NIT | confirmed | a symlinked path reads as missing; the other checks came out clean | deferred: the message is accurate enough and nothing leaks |

## Metrics

## Advisory test hints

Reviewer test proposals, input to the test design and not authoritative:

- probe-panel plan stage keeps a similar-symbol row of a file the spec does not list (architect-t1, consumer-t1)
- `verify` with an auditor line that changes message, severity or line spelling (architect-t2, consumer-t2, skeptic-t2)
- `probe.sh run plan --only spec-symbols` with a spec outside the repo (architect-t3, skeptic-t1)
- `budget` with a missing or empty block and critics 0 (consumer-t3)
- `budget` inputs that reach `block-only` and `skip`; a bad `--only` id ends ERROR (skeptic-t3)

## Rejected / deferred
