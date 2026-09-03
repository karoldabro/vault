---
type: trail
project: vault
plan: 2026-09-03-0929-enforce-brevity-mechanically
tags: [trail, record]
---

# 2026-09-03-0929-enforce-brevity-mechanically — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-03-0929-enforce-brevity-mechanically.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| The reminder names only a limit the previous reply broke | print the caps again each turn | `~/.claude/CLAUDE.md` and the director output style already load the caps, and the output is still long. A third copy costs tokens every turn and adds no information. |
| The reminder names only a limit the previous reply broke | print the measurement with its target every turn | A number with no limit beside it states no problem and changes nothing. A limit printed after a reply that met it becomes a figure to fill: the 15-line cap covers decision blocks only, and most turns are not one. |
| Silence whenever the previous reply met every limit | always print something | The framework's own rule forbids reporting that a normal thing was normal, and silence makes any text before a prompt mean something went over. |
| `Stop` hook logs, never exits 2 | exit 2 to force a rewrite | Exit 2 continues the conversation, so the model appends more text to a reply that was already too long. |
| Correct at the next turn | correct the current reply | No hook sees the reply before the user does. `Stop` fires after the text is on screen. |
| `output-styles/director.md` stays hand-written | generate it from `commands/_shared/communication.md` | The two files deliberately differ — the style drops `## Evidence note`, adds `## Files you write`, and renames four headings. A generator would carry that rewritten wording inside itself, moving the duplication rather than removing it. A generated file naming its source path also fails `tests/unit/communication-contract.bats:180`. |
| `commands/_shared/communication.md` keeps all twelve headings and its 120-line cap | cut it to 70 lines | `tests/unit/communication-contract.bats:22` and `:47` pin the headings and the evidence-note phrases. A 42% cut also puts the carve-outs at risk, and the carve-outs are what stop a cap hiding a warning. |
| Extract to `lib/` before writing new scripts | copy `bin/doc-lint.sh` and `scripts/doc-lint-hook.sh` | Copying leaves three implementations of the framework-root resolution and two of the sentence counter; when one drifts, a hook stops working silently. |
| `--enable-brevity` gates installation | register the hooks on any install run | `install.sh:150` and `tests/unit/install.bats:150` both state that linking and switching on are separate steps and the default must never touch the settings file. |
| Both hooks plus the prose work | prose rewrite alone | Prose alone is what is in place today and is what failed. |
| Both hooks plus the prose work | measure for a week, then decide | Chosen by the operator at the clarify gate: nothing improves during the measuring week. |

## Findings & dispositions

Every confirmed finding was applied. `stage` is `plan 1`, `plan 2` or `diff`.

| stage | persona | id | severity | grounding | issue | disposition |
|---|---------|----|----------|-----------|-------|-------------|
| plan 1 | consumer | consumer-1 | BLOCKER | confirmed | Rewriting the contract deletes text existing tests require, so the step fails its own verification | applied — item 8 keeps all twelve headings and every pinned phrase; no assertion is rewritten |
| plan 1 | consumer | consumer-2 | MAJOR | confirmed | The reminder's literal text was never written down, and its only test counted lines | applied — item 7 fixes the text; bt-4 asserts its content |
| plan 1 | consumer | consumer-3 | MAJOR | confirmed | The installer block being copied deliberately registers nothing, so both hooks would be inert | applied — item 10 adds `--enable-brevity`; bt-7 asserts zero entries without it |
| plan 1 | consumer | consumer-4 | MAJOR | confirmed | The generator had no section map, and stamping its source path breaks an existing test | applied by removal — the generator is dropped |
| plan 1 | consumer | consumer-5 | MINOR | advisory | Concurrent sessions share one state file | applied — per-session filename; raised to a real risk by skeptic-1 |
| plan 1 | consumer | consumer-6 | MINOR | confirmed | No plan row documents the off-switch where the existing one is documented | applied — item 12 |
| plan 1 | skeptic | skeptic-1 | MAJOR | confirmed | Pre-mortem: three live `claude` processes share one state file, so the note quotes the wrong window and he stops reading it | applied — state file keyed by session id |
| plan 1 | skeptic | skeptic-2 | NIT | advisory | Three assumptions are unmeasured | applied — all three moved to the plan's open section; ADR-025's review answers them |
| plan 1 | skeptic | skeptic-3 | MAJOR | confirmed | The sentence saying the 15-line cap yields to a warning has no test, and the reminder would repeat the bare number | applied — kept verbatim by item 8, printed by item 7, asserted by bt-9 |
| plan 1 | skeptic | skeptic-4 | MAJOR | confirmed | The installer would switch the hooks on for everyone | applied — same fix as consumer-3 |
| plan 1 | skeptic | skeptic-5 | MAJOR | confirmed | Same conflict as consumer-1, from the test side | applied with consumer-1 |
| plan 1 | skeptic | skeptic-6 | MAJOR | confirmed | The caps already load twice and are already ignored, so a third copy is not the fix | applied — the reminder now prints a measurement, not a rule; the premise is stated in the plan's open section |
| plan 1 | quality | quality-0 | MINOR | advisory | Reply length today is unmeasured; the YapBench link was not re-fetched under read-only review | applied in part — the unmeasured premise is in the open section; the citation was fetched by the orchestrator on 2026-09-03 |
| plan 1 | quality | quality-1 | MAJOR | confirmed | The over-long-sentence counter already exists in `bin/doc-lint.sh:469` | applied — item 1 extracts `lib/sentence-count.sh` |
| plan 1 | quality | quality-2 | MAJOR | confirmed | Copying the hook bootstrap would leave three copies of the framework-root resolution | applied — item 2 extracts `lib/hook-common.sh` |
| plan 1 | quality | quality-3 | MAJOR | confirmed | Adding a hook means editing five places in `install.sh`, and this adds two hooks | applied — item 10 replaces the per-hook blocks with a list and a loop |
| plan 1 | quality | quality-4 | MAJOR | confirmed | The two prose files are not the same text, so a generator moves the duplication into the script | applied — generator dropped; item 15 locks the parity-probe count instead |
| plan 1 | quality | quality-5 | MINOR | confirmed | The banned-filler phrase list already exists in `lib/doc-lint-patterns.tsv` | applied — item 4 adds a `prose` group; item 5 reads it |
| plan 1 | quality | quality-6 | MINOR | confirmed | `--report` has one reader, once, a week away | applied — dropped; the `jq` line moves into ADR-025's review |
| plan 2 | consumer | consumer-8 | BLOCKER | confirmed | The dry run failed: a number with no target states no problem, so the produced reply was identical to one with no reminder | applied — item 7 prints each number with its target and one imperative; the carve-out sentence that licensed longer output is removed from the reminder and stays in the two contract files |
| plan 2 | consumer | consumer-9 | MAJOR | confirmed | `bin/doc-lint.sh` runs `set -euo pipefail` and sources nothing today; an absent library would abort it and the live hook would present shell errors as findings on every write | applied — item 1 requires a guarded source; bt-12 removes the file and asserts a normal exit |
| plan 2 | consumer | consumer-10 | NIT | confirmed | The verification glob skips two documents without `globstar`, and the capture file was unnamed | applied — item 1 uses `find` and names both capture paths |
| plan 2 | skeptic | skeptic-8 | MAJOR | confirmed | Same defect as consumer-8, reached from the premise side | applied with consumer-8 |
| plan 2 | skeptic | skeptic-9 | MAJOR | confirmed | Pre-mortem: the review that decides whether any of this worked had no date, owner or stop condition, so an unread log leaves the experiment running forever | applied — item 13 carries the date 2026-09-10, the operator as owner, the exact `jq` command, and an uninstall as the stop condition |
| plan 2 | skeptic | skeptic-10 | MAJOR | confirmed | The before-and-after check exercises only the 30-word document setting, so a broken 25-word reply setting passes | applied — bt-13 tests both limits from fixtures |
| plan 2 | skeptic | skeptic-11 | MINOR | confirmed | The reused counter skips pipe-prefixed lines, and an options table is most of a decision block, so the shape the contract cares about most would be measured least | applied — item 1's library takes a skip-tables flag; item 5 sets it off; bt-14 guards it |

| plan 2 | skeptic | skeptic-12 | MAJOR | confirmed | The 15-line cap applies only to a decision block, so printing it every turn offers room to fill on turns whose right answer is two lines | applied — the reminder names only a limit the previous reply actually broke |
| plan 2 | skeptic | skeptic-13 | MAJOR | confirmed | The plan applied report-exceptions-not-normality to a missing measurement but not to a good one, so a short reply still got a report saying it was short | applied — silence whenever the previous reply met every limit; bt-4b guards it |
| plan 2 | skeptic | skeptic-14 | MAJOR | confirmed | Pre-mortem: a fixed target above every prompt would drag short replies up toward the number | applied — the reminder is gated on a breach, and item 13 already carries a date and a stop condition |

| diff | skeptic | skeptic-15 | MAJOR | confirmed | `PROSE4` matched case-insensitively, so "the major risk is cost" was reported as broken | applied — `PROSE4`, `PROC5`, `HIST3`, `HIST4` now match case-sensitively in `bin/output-lint.sh`, mirroring `bin/doc-lint.sh`'s own `case_flag()` |
| diff | skeptic | skeptic-16 | MAJOR | confirmed | A decision block was detected by the presence of a table, so a long prose decision escaped and a short factual table was flagged | applied — detection now counts two of the six field labels the contract names |
| diff | skeptic | skeptic-17 | MAJOR | confirmed | The reminder printed pattern codes, which say nothing the model can act on | applied — `bin/output-lint.sh` emits a `notes` field carrying each pattern's own message, and the reminder prints that |
| diff | skeptic | skeptic-18 | MAJOR | confirmed | Pre-mortem: a padded paragraph of short sentences measures clean, which is the defect actually complained about | applied in part — recorded as a known blind spot in the plan and in ADR-025, with a replay step before switching on. No trigger for it exists; an invented word threshold would fire on legitimate long answers |

| diff | quality | quality-8 | BLOCKER | confirmed | The reply linter's phrase matcher was written from scratch and dropped the document linter's two safeguards: case sensitivity for the shouted codes, and blanking of code blocks | applied — both live in `lib/prose-match.sh` and both linters call them; a reply quoting `BLOCKER` in a fence is silent, one asserting it fires |
| diff | quality | quality-9 | MAJOR | confirmed | The Stop hook and the reminder each built the state filename themselves, so a rename in one would silently stop the pair working | applied — `hook_state_path` in `lib/hook-common.sh`, called by both; it also owns the session-id validation |
| diff | quality | quality-10 | MINOR | confirmed | Hook-row values were pasted into the Python that edits settings, so a matcher containing a quote would break it | applied — the row is passed as JSON through the environment |
| diff | quality | quality-11 | MINOR | confirmed | Same defect as skeptic-17, from the unused-column side | applied with skeptic-17 |
| diff | quality | quality-12 | NIT | confirmed | The no-temp-file fallback emitted fewer fields than the normal path | applied — both shapes now match, asserted by a test comparing their key sets |

## Metrics

Round 1: three reviewers, 19 findings — 1 confirmed blocker, 11 confirmed major, 5 confirmed minor,
2 advisory. Cross-reviewer overlap 3 of 19.

Round 2: two reviewers on the revised plan, 10 new findings — 1 confirmed blocker, 8 confirmed
major, 1 confirmed minor. The blocker was raised independently by both, from opposite directions.
The last three findings reversed a decision made earlier in the same round: the reminder went from
always printing a target to printing only a breached limit.

Diff review: two reviewers on the implementation, 9 new findings — 1 confirmed blocker, 6 confirmed
major, 2 confirmed minor. The blocker exposed a latent trap in code that predates this change:
`case_flag()` returned `-e` through `echo`, which bash swallowed as its own flag, so the
case-sensitive branch worked only by accident. Rewriting the call surfaced it, and
`tests/unit/brevity-hooks.bats` now pins the helper's empty return.

Every confirmed finding in both rounds was applied. None was deferred or rejected, so no minority
flag arises. No previously confirmed finding was dropped between rounds. The loop stopped at the
round cap of 2 with no open blockers.

## Advisory test hints

Design reviewers proposed the sentence-counter parity test, the installer-loop test and the
contract-drift test. All three were reconciled into the plan's Test backlog as bt-6, bt-7 and bt-10.

## Rejected / deferred

- **A `PreToolUse` gate on the final message.** No tool call carries the assistant's prose, so no
  `PreToolUse` matcher can see it. Only `Stop` receives the reply text.
- **Truncating the reply mechanically.** A hook cannot edit text already streamed to the terminal,
  and cutting mid-answer would drop the warnings the contract exists to protect.
- **`bin/output-lint.sh --report`.** Its one reader is a review a week away; the `jq` line lives in
  that review instead.
- **Per-command line caps in this change.** Deferred to item 13, which sets them from logged data.
- **Research that did not survive.** GPT-5's `verbosity` API parameter and `max_tokens` control
  length at the API layer. Claude Code exposes neither to a hook or an output style, so neither is
  reachable from this framework.
