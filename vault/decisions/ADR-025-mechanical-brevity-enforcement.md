---
type: decision
project: vault
id: ADR-025
slug: ADR-025-mechanical-brevity-enforcement
status: accepted
date: 2026-09-03
tags: [decision, communication, hooks, enforcement]
---

# ADR-025 — Measure replies instead of restating the rules

## Context

The brevity rules load twice at the start of every session — through `~/.claude/CLAUDE.md` and the
director output style — and replies are still long. Nothing measures a user-facing line. The file
side has had `bin/doc-lint.sh` and a `PostToolUse` hook since [[ADR-023-document-writing-standard]];
the terminal side has 37 files binding a prose contract and no check at all, which
[[user-facing-communication]] already recorded as a known gap.

Three constraints shaped the answer. Claude Code documents memory files as context rather than
enforced configuration, and the report that output styles are ignored
(`anthropics/claude-code#6450`) is closed `not planned`. Numeric per-artifact targets move output
40–60% where the phrase "be concise" does not. Models released in 2025–2026 are on average more
verbose than their predecessors, so this worsens on its own.

## Decision

**We will measure each reply and report only what it overran.**

- `bin/output-lint.sh` measures one reply: lines, words, sentences over 25 words, banned filler.
- `scripts/output-lint-hook.sh` (`Stop`) records that measurement per session and appends it to
  `~/.claude/brevity-log.jsonl`.
- `scripts/brevity-reminder-hook.sh` (`UserPromptSubmit`) names, at the next turn, the limits the
  previous reply broke — and prints nothing when it broke none.
- `commands/_shared/communication.md` and `output-styles/director.md` gain a worked before/after
  table and a table of the numbers.
- Both hooks are inert until `install.sh --enable-brevity`; `BREVITY=off` silences them.

Three triggers, each a written rule rather than an invented threshold: a sentence over 25 words,
banned filler from `lib/doc-lint-patterns.tsv`, and over 15 lines in a **decision block**, which is
recognised by carrying two of its six field labels (Recommendation, Impact, Options, What I assumed,
Open points, The ask). Codes that ban a shouty token — `PROSE4`, `PROC5` — match case-sensitively,
so "the major risk is cost" does not trip them.

### Rejected

- **Restating the caps every turn.** They already load twice and are ignored; a third copy costs
  tokens and adds no information.
- **Printing the measurement with its target every turn.** A limit shown after a reply that met it
  becomes a figure to fill, and most turns are not decision blocks, so a two-line answer would drift
  up toward fifteen.
- **Exit 2 from the `Stop` hook.** Exit 2 blocks the stop and continues the conversation, so the
  model appends more text to a reply that was already too long.
- **Generating `output-styles/director.md` from the shared contract.** The two files deliberately
  differ — the style drops the evidence note, adds the document rules, and renames four headings — so
  a generator would carry that wording inside itself rather than remove the duplication.
- **Editing the reply itself.** No hook sees a reply before the user does.
- **A `PreToolUse` gate.** No tool call carries the assistant's prose.

## Consequences

Correction always lands one turn late. Nothing blocks: a broken hook degrades to the behaviour
before this decision.

`bin/doc-lint.sh` now sources `lib/sentence-count.sh`. It runs from a live `PostToolUse` hook, so the
source is guarded — an absent library skips the sentence check and the linter still exits normally,
rather than aborting under `set -e` and returning shell errors to the model as findings.

Three assumptions remain untested: what a `Stop` hook actually receives, what the reminder costs per
turn, and whether naming a broken limit shortens the next reply. Nothing in the sources tests the
third.

**Known blind spot.** A padded paragraph of short sentences, carrying no banned filler and no
decision fields, measures clean. That is closest to what the operator actually complained about — a
paragraph where one sentence would do — and none of the three triggers catches it. No cheap measure
of redundancy exists, and an invented word-count threshold would fire on legitimate long answers.
The review below decides whether to keep looking or to accept the limit.

### Review — 2026-09-10, owner: the operator

```
jq -s 'map(.lines) | add/length' ~/.claude/brevity-log.jsonl
```

**Either result ends the experiment.** If the median is not below the 2026-09-03 baseline, or if the
reminder fired on almost no turns, re-run `install.sh` without `--enable-brevity`, delete the two
hook entries from `~/.claude/settings.json`, and record the negative result. A reminder that never
fires means the complaint is about something a line count does not measure.

Before switching it on, replay the measurer over replies the operator would call too long
(`printf '%s' "$reply" | bin/output-lint.sh`) and check it fires on them. If it does not, the
triggers are wrong and no amount of logging will show that.

## Refs

- [[ADR-018-decision-communication-contract]] — the prose contract this makes measurable.
- [[ADR-023-document-writing-standard]] — the file-side machinery this reuses rather than copies.
- [[user-facing-communication]] — the working rule, which now names the measurement path.
- [[enforced-not-just-stated]] — a stated threshold names the function computing it and ships a test
  proven to fail without it; `bin/output-lint.sh` and `tests/unit/brevity-hooks.bats` satisfy it.
- [[decision-communication]] — the evidence base, including the accuracy floor below which terseness
  collapses correctness.
