---
type: session
project: vault
date: 2026-09-03
topic: mechanical-brevity-enforcement
continues: [[2026-08-21-1015-document-writing-standard]]
files_touched:
  - bin/output-lint.sh
  - bin/doc-lint.sh
  - lib/sentence-count.sh
  - lib/prose-match.sh
  - lib/hook-common.sh
  - lib/doc-lint-patterns.tsv
  - scripts/output-lint-hook.sh
  - scripts/brevity-reminder-hook.sh
  - scripts/doc-lint-hook.sh
  - commands/_shared/communication.md
  - output-styles/director.md
  - install.sh
  - hooks/hooks.json
  - INSTALL.md
  - tests/Dockerfile
  - tests/unit/brevity-hooks.bats
  - tests/unit/communication-contract.bats
  - tests/unit/install.bats
  - tests/unit/document-standard.bats
decisions: [ADR-025-mechanical-brevity-enforcement]
tags: [session]
---

# mechanical-brevity-enforcement

## Goal

Stop Claude writing a paragraph where a sentence would carry the same information, by measuring
replies instead of restating the brevity rules a third time.

## Did

- Wrote `bin/output-lint.sh`: reads a reply on stdin, prints lines, words, sentences over 25 words,
  banned-filler hits and whether the reply is a decision block. Measures only — no writes, no
  network, always exit 0.
- Added two hooks. `scripts/output-lint-hook.sh` (`Stop`) records each reply's numbers to
  `~/.claude/brevity-state.<session_id>.json` and appends a row to `~/.claude/brevity-log.jsonl`.
  `scripts/brevity-reminder-hook.sh` (`UserPromptSubmit`) names, at the next turn, only the limits
  that reply broke, and prints nothing when it broke none.
- Extracted three shared libraries rather than copying: `lib/sentence-count.sh` (30 words for
  documents, 25 for replies, table rows counted for replies and skipped for documents),
  `lib/prose-match.sh` (code-block blanking plus the case rule), `lib/hook-common.sh` (framework
  resolution, off-switch, state path). Every source is guarded.
- Added a `prose` group to `lib/doc-lint-patterns.tsv` that only `bin/output-lint.sh` requests, and
  had it also read the existing `reference` and `process` rows instead of duplicating them.
- Gave `commands/_shared/communication.md` and `output-styles/director.md` a worked before/after
  table and a table of the numbers, inside the contract's own 120-line cap.
- Replaced `install.sh`'s per-hook copies with a `HOOK_ROWS` list and three loops, added
  `--enable-brevity`, and passed row values to the settings editor as JSON rather than pasted text.
- Added `python3` to `tests/Dockerfile`, which turned two long-failing install tests green.
- Wrote [[ADR-025-mechanical-brevity-enforcement]] and updated [[user-facing-communication]].

## Learned

- `echo "-e"` in bash prints **nothing** — bash reads it as `echo`'s own flag. `bin/doc-lint.sh`'s
  `case_flag()` had returned `-e` this way since it was written, so its case-sensitive branch worked
  only because the value never arrived. Rewriting the call through `printf` surfaced it: `grep -e`
  means "the next argument is the pattern", which silently turned the real pattern into a filename.
- Claude Code memory files are documented as context, not enforced configuration, and the
  output-styles-ignored report `anthropics/claude-code#6450` is closed `not planned`. The brevity
  caps already load twice per session here — `~/.claude/CLAUDE.md` and the director output style —
  and replies stayed long, so a third copy was never the fix.
- A `Stop` hook must not exit 2. Exit 2 blocks the stop and continues the conversation, so the model
  appends more text to a reply that was already too long.
- `commands/_shared/communication.md` is pinned by name in `tests/unit/communication-contract.bats`:
  twelve exact headings and several exact phrases. A rewrite that improves the wording turns the
  suite red, and the phrases wrap across lines, so a `grep -q` probe fails on a reflow alone.
- Numeric per-artifact targets cut output 40–60%; the phrase "be concise" does not
  (https://neuraltrust.ai/blog/output-length-control). Models released 2025–2026 are on average more
  verbose than their predecessors (YapBench, https://arxiv.org/abs/2601.00624v1).

## Behaviors & rules

- A reply breaks no limit → the reminder prints nothing; text before a prompt always means something
  went over.
- A reply carries a sentence over 25 words → the reminder names that count and the ceiling; edge: a
  sentence of exactly 25 words does not count.
- A reply carries two of the six decision-block field labels and exceeds 15 lines → the reminder
  names the 15-line cap; edge: a reply containing only a table is not a decision block, and a long
  decision written as prose is.
- A reply quotes a banned phrase inside a code fence or inline backticks → no finding; asserted in
  the model's own voice → a finding.
- A pattern code whose lowercase form is ordinary English (`BLOCKER`, `MAJOR`) matches on case, so
  "the major risk is cost" produces no finding.
- A hook cannot do its job → it exits 0 and does nothing; edge: `bin/doc-lint.sh` with a missing
  shared library skips that one check and still lints the rest.
- `install.sh` runs without a flag → the settings file is not touched; with `--enable-brevity` →
  exactly one entry per hook, and entries the user already had are preserved.

## Next

- **Nobody has switched it on.** `install.sh --enable-brevity` registers both hooks; until then
  nothing measures anything.
- Before switching on, replay the measurer over replies that are genuinely too long
  (`printf '%s' "$reply" | bin/output-lint.sh`) and check it fires. If it does not, the triggers are
  wrong and logging will not reveal that.
- **2026-09-10 review**, in [[ADR-025-mechanical-brevity-enforcement]]: uninstall if the median reply
  length has not dropped, or if the reminder almost never fired.
- Known blind spot: a padded paragraph of short sentences, with no filler and no decision fields,
  measures clean. That is closest to the original complaint and no trigger catches it.
- Four unit tests still fail, all predating this session: an unrecognised document type gets the
  loosest cap; `bin/doc-lint.sh --compare` misses a dropped constraint; `commands/v-reconcile.md`
  has no frontmatter description; a v-team PROPOSE output probe fails.

## Refs

- [[ADR-025-mechanical-brevity-enforcement]] — the decision and its 2026-09-10 stop condition.
- [[ADR-018-decision-communication-contract]] — the prose contract this makes measurable.
- [[ADR-023-document-writing-standard]] — the file-side machinery this reuses rather than copies.
- [[user-facing-communication]] — the working rule, updated with the measurement path.
- [[enforced-not-just-stated]] — the rule this session satisfies for its own thresholds.
- [[decision-communication]] — the evidence base.
- [[2026-08-21-1015-document-writing-standard]] — the file-side session this continues.
