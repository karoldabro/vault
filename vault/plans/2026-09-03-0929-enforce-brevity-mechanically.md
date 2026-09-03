---
type: plan
project: vault
slug: 2026-09-03-0929-enforce-brevity-mechanically
repos: [vault]
status: executed
process_record: 2026-09-03-0929-enforce-brevity-mechanically.trail.md
session:
tags: [plan]
---

# 2026-09-03-0929-enforce-brevity-mechanically — plan

## Task

Give the brevity contract the one thing it lacks: a measurement. Measure every reply, hand the model
its own previous length as a number at the next turn, and add worked short/long examples to the two
prose contracts.
Keywords: `communication`, `brevity`, `hook`, `output-style`, `enforcement`.

## Open & deferred

- **open — the hooks are installed but not switched on.** `install.sh --enable-brevity` registers
  them; until it runs, nothing measures anything. Nobody has run it yet.
- **open — three assumptions are untested.** What Claude Code actually puts in a `Stop` hook's
  `last_assistant_message`; what the per-turn reminder costs in tokens; and whether a measured number
  shortens the next reply at all. No experiment in this repo tests the third. The 2026-09-10 review
  in `vault/decisions/ADR-025-mechanical-brevity-enforcement.md` answers all three from the log.
- **open — four unit tests fail, all of them present at HEAD before this change.** An unrecognised
  document type gets the loosest cap; `bin/doc-lint.sh --compare` misses a dropped constraint;
  `commands/v-reconcile.md` has no frontmatter description; a v-team PROPOSE output probe fails.
  Verified by running the suite against `git archive HEAD` in a clean tree, 2026-09-03.
- **open — the caps already load twice and are already ignored.** `~/.claude/CLAUDE.md` carries an
  `## Output rules` section and `~/.claude/settings.json` sets `"outputStyle": "director"`, so the
  25-word ceiling and the 15-line cap are in context before any hook runs. This is why
  `scripts/brevity-reminder-hook.sh` speaks only about a limit that was actually broken, rather than
  restating the rules. Whether that is enough is the experiment; ADR-025's stop condition ends it on
  2026-09-10 if the median does not move.
- **open — a reminder that never fires proves nothing either way.** If the log shows the reminder
  firing on almost no turns, the caps are being met and the operator's complaint is about something
  the line count does not measure. ADR-025 treats that outcome as a stop condition too.
- **open — a padded paragraph of short sentences measures clean.** That is closest to the actual
  complaint, and none of the three triggers catches it: no banned filler, no over-long sentence, no
  decision fields. No cheap measure of redundancy exists, and an invented word-count threshold would
  fire on legitimate long answers. ADR-025's review decides whether to keep looking.
- **open — a reply the operator asked to be long trips the same measure.** "Give me the full
  reasoning" legitimately runs to 60 lines. Nothing here reads intent. Both hooks only log and print;
  neither blocks, so a false positive costs one wrong number, not a wrong action.
- **deferred — no per-command caps.** Every surface keeps the same 15-line decision cap and 25-word
  sentence ceiling until that review has real numbers.
- **deferred — subagent prose stays governed by prose only.** No hook sees a subagent's report.
  `commands/v-team/steps/03-propose-loop.md` §(e).7 remains the only control there.

## Verified current state

- `tests/unit/communication-contract.bats:22` requires twelve exact headings in
  `commands/_shared/communication.md`, and `:47` requires the phrases `never controlled-tested` and
  `decision-communication` inside it. Any rewrite that deletes them turns the suite red · read
  2026-09-03.
- `tests/unit/communication-contract.bats:197` already guards style-versus-contract parity with
  twelve phrase probes, and `:180` fails the style if it names a repository path · read 2026-09-03.
- `output-styles/director.md` is not a copy of the contract: it drops `## Evidence note`, adds
  `## Files you write`, and renames four headings · `grep -n '^## '` on both files, 2026-09-03.
- `install.sh` never edits `~/.claude/settings.json` without an explicit flag. Its comment at
  :150–152 says so, `--enable-doc-lint` gates the only hook registration at :185, and
  `tests/unit/install.bats:150` pins the rule · read 2026-09-03.
- The settings merge is already safe and idempotent — `if not any("doc-lint-hook" in json.dumps(e)
  for e in post)` appends without touching the operator's existing `Stop` entries · `install.sh:187`.
- `bin/doc-lint.sh:469` `check_sentences()` already counts over-long sentences, and its own comment
  names the 25-word figure for replies versus 30 for documents · read 2026-09-03.
- `lib/doc-lint-patterns.tsv` rows `REF2`, `REF3` and `PROC7` already match the filler phrases the
  contract bans at `commands/_shared/communication.md:37` · read 2026-09-03.
- `bin/doc-lint.sh:385` reads its pattern table from a file path, so a second consumer needs no new
  mechanism · read 2026-09-03.
- Three `claude` processes run concurrently on this machine · `ps -eo pid,args | grep -i '[c]laude'`,
  2026-09-03.
- A `Stop` hook receives the reply as `last_assistant_message`; `UserPromptSubmit` stdout is added to
  the prompt context · https://code.claude.com/docs/en/hooks, fetched 2026-09-03.
- Claude Code memory files are documented as context rather than enforced configuration, and
  `anthropics/claude-code#6450` (output styles ignored) is closed `not planned` · fetched 2026-09-03.
- Numeric per-artifact length targets cut output 40–60%; the phrase "be concise" does not ·
  https://neuraltrust.ai/blog/output-length-control, fetched 2026-09-03.

## Decisions

- The reminder speaks **only when the previous reply broke a limit**, and names the limit beside the
  number. The rules already load twice and are ignored, so a third copy adds nothing; a number with
  no limit beside it states no problem; and a limit printed on a turn that met it becomes a target to
  fill rather than a ceiling to respect.
- Silence is the normal case — the framework's own report-exceptions-not-normality rule, applied to
  itself. Text before a prompt therefore always means something went over.
- The `Stop` hook logs and never exits 2 — blocking the stop forces a continuation, which makes the
  model emit **more** text.
- Correction lands at the **next** turn — the reply is already on screen before any hook sees it.
- `output-styles/director.md` stays hand-written — it deliberately differs from the contract, so a
  generator would carry the divergence inside itself rather than remove it.
- `commands/_shared/communication.md` keeps all twelve headings and its 120-line cap — the file gains
  worked examples and loses rationale prose, and no existing assertion is rewritten.
- Every new script reuses `lib/`: the sentence counter, the hook bootstrap and the phrase table each
  get one implementation.
- Installation is gated behind `--enable-brevity` — the installer's standing rule is that linking and
  switching on are separate steps.

## Scope & non-goals

Covers: the two prose contracts, three extracted `lib/` files, one measurement script, two hooks,
their install wiring, tests, one decision record, one indication update, one INSTALL.md section.

Does not cover: `bin/doc-lint.sh`'s own findings or caps, subagent report length, per-command caps,
or any change to what a command computes.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `~/.claude/brevity-state.<session_id>.json` | `scripts/brevity-reminder-hook.sh` needs the previous reply's numbers to print anything at all | `scripts/output-lint-hook.sh` after each turn, using the `session_id` field it receives | `scripts/brevity-reminder-hook.sh` at the next turn of that same session | Absent on a session's first turn, and after every `BREVITY=off` turn: the reminder prints nothing and the turn proceeds. Malformed is treated as absent — a `jq` failure falls to the same branch. Per-session naming is what stops one window quoting another window's length. |
| `~/.claude/brevity-log.jsonl` | the 2026-09-10 review in ADR-025, which sets per-command caps from real numbers | `scripts/output-lint-hook.sh`, one JSON line per turn | the operator, via the `jq` line in ADR-025 | Never read during a run. Absent means that review has no data and per-command caps stay deferred; no turn behaves differently. |
| the breach clause inside the reminder that `scripts/brevity-reminder-hook.sh` prints | the model has to know what 41 lines broke; a bare count states no problem and changes nothing | this plan, item 7 | the model, only on a turn following an over-limit reply | Two failures, opposite directions: a number with no limit beside it changes nothing, and a limit printed after a compliant reply becomes a figure to fill. bt-4 guards the first, bt-4b the second. |
| reminder text on stdout of `scripts/brevity-reminder-hook.sh` | Claude Code adds `UserPromptSubmit` stdout to the prompt context — this is the only new information the model gets | `scripts/brevity-reminder-hook.sh` | the model, only after an over-limit reply | Empty stdout is the normal case, not a failure: on turn one, after a compliant reply, and under `BREVITY=off`. Over-long stdout taxes the turn; `tests/unit/brevity-hooks.bats` caps it at 4 lines. |
| `lib/sentence-count.sh` | `bin/doc-lint.sh` `check_sentences()` and `bin/output-lint.sh` both need it, at 30 and 25 words | this plan, item 1 | both linters, which pass the word limit as an argument | Missing: each caller skips its sentence check and exits normally. Unguarded, `set -euo pipefail` would abort `bin/doc-lint.sh`, and `scripts/doc-lint-hook.sh:37` would present the shell's error to the model as lint findings on every write. bt-12 removes the file and asserts the normal exit. |
| `lib/hook-common.sh` | all three hook wrappers need the framework-root resolution that handles both the plugin and the symlink install | this plan, item 2 | `scripts/doc-lint-hook.sh`, `scripts/output-lint-hook.sh`, `scripts/brevity-reminder-hook.sh` | A hook that cannot source it exits 0 and does nothing, matching `scripts/doc-lint-hook.sh`'s existing behaviour when its linter is absent. No turn is ever blocked. |
| `prose` rows in `lib/doc-lint-patterns.tsv` | `bin/output-lint.sh` reads the table through the same path mechanism as `bin/doc-lint.sh:385` | this plan, item 4 | both linters, each filtering to its own groups | A `prose` row that `bin/doc-lint.sh` also matches would start firing on documents. Item 4's test asserts the document linter's finding set is unchanged after the rows are added. |
| `--enable-brevity` flag on `install.sh` | the operator has no other way to switch the two hooks on; without it they are linked and inert | this plan, item 10 | the operator, and `INSTALL.md` | Without the flag nothing is registered and the feature silently does not exist. `tests/unit/install.bats` asserts zero settings entries without it and exactly one per hook with it. |

## Work items

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
| 1 | `lib/sentence-count.sh` | create: extract the awk block from `bin/doc-lint.sh:469-488`, taking the word limit as `$2`; change `bin/doc-lint.sh` to source it and pass 30 | Write, Edit | `bin/doc-lint.sh` runs `set -euo pipefail` and sources nothing today; the new source must be **guarded so an absent library skips the sentence check and the linter still exits normally** — otherwise `scripts/doc-lint-hook.sh:37` turns a shell error into lint findings on every write in every session | capture before: `find vault -name '*.md' -exec bin/doc-lint.sh {} \; > /tmp/doclint-before.txt 2>&1`; repeat after into `/tmp/doclint-after.txt`; `diff` must be empty; `make test` | DONE |
| 2 | `lib/hook-common.sh` | create: extract `scripts/doc-lint-hook.sh:21-28` — the off-switch, `SELF`, `VAULT_ROOT`, plugin-versus-symlink resolution; parameterise the env-var name | Write | sourcing it must not change `scripts/doc-lint-hook.sh` behaviour on either install shape | `tests/unit/document-standard.bats`; `bash -n` | DONE |
| 3 | `scripts/doc-lint-hook.sh` | edit: source `lib/hook-common.sh` instead of resolving the root itself | Edit | still exits 0 when `bin/doc-lint.sh` is absent | `tests/unit/brevity-hooks.bats` covers both install shapes | DONE |
| 4 | `lib/doc-lint-patterns.tsv` | edit: add a `prose` group holding the filler phrases banned at `commands/_shared/communication.md:37` | Edit | `prose` rows must not fire in `bin/doc-lint.sh`; existing `REF2`/`REF3`/`PROC7` rows unchanged | `tests/unit/document-standard.bats` finding set unchanged | DONE |
| 5 | `bin/output-lint.sh` | create: read a reply on stdin, print line count, word count, sentences over 25 words (via item 1) and `prose` phrase hits (via item 4) | Write | measures only; exits 0 always; no network; writes nothing. **Must count table rows.** `bin/doc-lint.sh:471` skips any line starting with `\|`, and an options table is most of a decision block — reusing that skip would measure least of what the contract cares about most, so item 1's library takes a skip-tables flag that this caller sets off | `tests/unit/brevity-hooks.bats` fixtures with known counts, including a fixture whose only over-long sentence is inside a table row | DONE |
| 6 | `scripts/output-lint-hook.sh` | create: `Stop` hook — pipe `last_assistant_message` through `bin/output-lint.sh`, append one line to `~/.claude/brevity-log.jsonl`, write `~/.claude/brevity-state.<session_id>.json` | Write | **never exit 2**; exit 0 when anything is missing; honour `BREVITY=off`; use the `session_id` field, never a fixed filename | `tests/unit/brevity-hooks.bats` asserts exit 0 on every path and a per-session filename | DONE |
| 7 | `scripts/brevity-reminder-hook.sh` | create: `UserPromptSubmit` hook that prints **only when the previous reply exceeded a stated limit**, in this shape — `Previous reply: N lines, K sentences over 25 words. The ceiling is 25 words a sentence; a decision block is capped at 15 lines.` / `Cut narrative, not warnings, blockers, or the impact line.` | Write | ≤4 lines of stdout; **silent unless a limit was exceeded**, so text before a prompt always means something went over; every number names the limit it broke; never a bare `Target: 15 lines` on a turn that met it, which would pull a two-line answer up toward fifteen; never the word "concise"; never a clause licensing longer output; honour `BREVITY=off`; never fail the turn | `tests/unit/brevity-hooks.bats` asserts silence on a compliant previous reply, the named limit beside every number, the warning-protection line, the 4-line bound, and exit 0 on a missing or corrupt state file | DONE |
| 8 | `commands/_shared/communication.md` | edit: add a numeric caps block and a worked before/after table in the shape of `commands/_shared/document-standard.md`'s "What the fix looks like"; cut rationale prose to stay in budget | Edit | ≤120 lines; **all twelve headings kept**; the `## Evidence note` phrases kept; the sentence at :91 about the cap yielding to a warning kept verbatim | `bats tests/unit/communication-contract.bats` with no assertion rewritten | DONE |
| 9 | `output-styles/director.md` | edit: add the same worked before/after table and numeric caps block | Edit | must name no repository path (`tests/unit/communication-contract.bats:180`); all twelve parity probes still match | `bats tests/unit/communication-contract.bats` | DONE |
| 10 | `install.sh` | edit: replace the per-hook blocks at `:17`, `:21`, `:58`, `:152`, `:185`, `:209` with one hook list (script, event, matcher, description) and a loop; add `--enable-brevity`; fold both new hooks into the list | Edit | default run still touches no settings file; idempotent; existing `Stop` entries preserved by the same `any(... in json.dumps(e))` guard | `tests/unit/install.bats`; run twice, `jq` the hook arrays | DONE |
| 11 | `hooks/hooks.json` | edit: add `Stop` → `scripts/output-lint-hook.sh` and `UserPromptSubmit` → `scripts/brevity-reminder-hook.sh` | Edit | `${CLAUDE_PLUGIN_ROOT}` form matching the existing `PostToolUse` entry; timeout 5 | `jq . hooks/hooks.json`; `tests/unit/plugin-install.bats` | DONE |
| 12 | `INSTALL.md` | edit: document `--enable-brevity` and `BREVITY=off` beside the existing `DOC_LINT=off` section at `:165` | Edit | states plainly that neither hook ever blocks a turn | `bin/doc-lint.sh INSTALL.md` | DONE |
| 13 | `vault/indications/user-facing-communication.md` | edit: replace the Guard section's "both are file contracts" note with the measurement path, and add the review — its date **2026-09-10**, its owner **the operator**, the exact command `jq -s 'map(.lines) \| add/length' ~/.claude/brevity-log.jsonl`, and its stop condition: if the median reply length on 2026-09-10 is not below the 2026-09-03 median, run `install.sh` without `--enable-brevity`, delete the two hook entries, and record the negative result | Edit | ≤80 lines; the four existing authoring rules unchanged; the review must carry a date, an owner, a command and a stop condition — an unread log ends the experiment rather than leaving it running | `bin/doc-lint.sh` on the file | DONE |
| 14 | `tests/unit/brevity-hooks.bats` | create: cover items 2, 3, 5, 6, 7 | Write | runs in the container harness, never on the host | `make test` | DONE |
| 15 | `tests/unit/communication-contract.bats` | edit: add assertions for the worked-example table in both files, the caps-yield sentence, and a fixed parity-probe count in the shape of the existing `:145` count lock | Edit | each new assertion proven to fail against the pre-change files | `make test` | DONE |
| 16 | `tests/unit/install.bats` | edit: zero settings entries without `--enable-brevity`, one per hook with it, other hooks' entries untouched | Edit | asserts the loop, not the old per-hook copies | `make test` | DONE |
| 17 | `vault/decisions/ADR-025-mechanical-brevity-enforcement.md` | create: the decision, the rejected generator and third-copy options, the accepted costs | Write | ≤120 lines per `bin/doc-lint.sh --list-caps` | `bin/doc-lint.sh` on the file | DONE |

## Sequencing & dependencies

Items 1 and 2 first — everything else sources them. Item 3 after item 2. Item 4 before item 5.
Items 6 and 7 after item 5. Items 10 and 11 after items 6 and 7 exist. Items 14–16 last.

**The measuring half lands before the prose half.** Items 1–7 and 10–12 give the log its first
numbers; items 8 and 9 rewrite the two prose files afterwards. Ordering it this way keeps the option
of stopping after item 12 and deciding the prose work from the log rather than from the assumption
that worked examples help.

## Rollback

`git revert` the commit, then `rm -f ~/.claude/hooks/output-lint-hook.sh
~/.claude/hooks/brevity-reminder-hook.sh` and delete the two hook entries from
`~/.claude/settings.json`. `~/.claude/brevity-log.jsonl` and the per-session state files are inert
once the hooks are gone. Nothing is irreversible, and no hook blocks a turn, so a broken hook
degrades to today's behaviour.

**The one path that is not merely additive** is item 1: `bin/doc-lint.sh` runs from a live
`PostToolUse` hook, so a bad extraction breaks document linting for every session on this machine.
Its verification captures the linter's findings on every vault document before the change and diffs
them after.

## Test plan

Harness: bats-core in the project container (`make test`). Level: unit only — shell scripts with
file inputs and no service dependency.

- `tests/unit/brevity-hooks.bats` — `bin/output-lint.sh` counts, both hook wrappers' exit codes and
  output bounds, the literal reminder text, `BREVITY=off`, missing and corrupt state files, and the
  per-session filename.
- `tests/unit/communication-contract.bats` — worked-example table present in both files, the
  caps-yield sentence, the parity-probe count lock.
- `tests/unit/document-standard.bats` — the document linter's findings are unchanged after items 1
  and 4.
- `tests/unit/install.bats` — flag gating and idempotent registration through the new loop.

## Test design dossier

**Decision table — `scripts/brevity-reminder-hook.sh` stdout.**

| `BREVITY` | state file for this session | stdout |
|---|---|---|
| `off` | any | empty, exit 0 |
| unset | absent | empty, exit 0 |
| unset | present, malformed | empty, exit 0 |
| unset | present, previous reply inside every limit | empty, exit 0 |
| unset | present, previous reply over a limit | the breached numbers with the limits they broke, plus one line protecting warnings; at most 4 lines |
| unset | present but from another session id | not reachable — the filename carries the session id |

**Fault hypotheses.** The `Stop` hook exits 2 and forces a continuation. Two sessions share a state
file and the reminder quotes the wrong window. `install.sh` registers a hook on a default run.
`install.sh` appends a duplicate on re-run, or drops the operator's existing `Stop` entries. A corrupt
state file makes `jq` fail under `set -e` and kills the turn. The `lib/sentence-count.sh` extraction
changes what `bin/doc-lint.sh` reports. A `prose` pattern row starts firing on documents.

**Metamorphic relations.** Doubling a fixture reply's lines doubles the reported line count. Running
`install.sh` twice leaves the same `settings.json` hook arrays as running it once. Linting every
vault document before and after item 1 produces identical findings.

**Boundary partitions.** Reply of 0, 1, 15 and 16 lines. Sentence of exactly 25 and of 26 words.
Document sentence of exactly 30 and of 31 words. Reminder stdout of exactly 4 lines and of 5. An
over-long sentence inside a table row, which a document skips and a reply counts.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| bt-1 | fault | unit | `tests/unit/brevity-hooks.bats` | `scripts/output-lint-hook.sh` exits 0 on every path, including a missing `bin/output-lint.sh` | must | |
| bt-2 | fault | unit | `tests/unit/brevity-hooks.bats` | the state filename carries the session id, so two sessions never share one | must | |
| bt-3 | decision table | unit | `tests/unit/brevity-hooks.bats` | all five rows of the reminder table, including the two that print nothing | must | |
| bt-4 | consumer | unit | `tests/unit/brevity-hooks.bats` | every measured number in the reminder names the limit it broke, the warning-protection line is present, and no clause licenses longer output | must | |
| bt-4b | fault | unit | `tests/unit/brevity-hooks.bats` | a previous reply inside every limit produces empty stdout, so no number is ever shown as an unmet target | must | |
| bt-5 | boundary | unit | `tests/unit/brevity-hooks.bats` | `bin/output-lint.sh` reports 0, 1, 15, 16 lines and a 25- versus 26-word sentence correctly | must | |
| bt-6 | metamorphic | unit | `tests/unit/document-standard.bats` | the document linter's findings are identical after items 1 and 4 | must | |
| bt-7 | fault | unit | `tests/unit/install.bats` | a default run leaves `settings.json` untouched; `--enable-brevity` adds one entry per hook and no more on a second run | must | |
| bt-8 | fault | unit | `tests/unit/install.bats` | registering the new hooks leaves an existing unrelated `Stop` entry in place | must | |
| bt-9 | fault | unit | `tests/unit/communication-contract.bats` | the caps-yield sentence and the worked-example table survive any future edit to both prose files | should | |
| bt-10 | quality | unit | `tests/unit/communication-contract.bats` | a new contract section fails the suite until a matching parity probe is added | should | |
| bt-11 | decision table | unit | `tests/unit/brevity-hooks.bats` | `BREVITY=off` silences both hooks | should | |
| bt-12 | fault | unit | `tests/unit/document-standard.bats` | with `lib/sentence-count.sh` removed, `bin/doc-lint.sh` skips the sentence check and still exits normally | must | |
| bt-13 | boundary | unit | `tests/unit/brevity-hooks.bats` | the extracted counter flags a 26-word sentence at the 25-word setting and not at the 30-word setting, from fixtures rather than from live documents | must | |
| bt-14 | fault | unit | `tests/unit/brevity-hooks.bats` | an over-long sentence inside a table row is counted for a reply and skipped for a document | must | |

## Refs

- `vault/decisions/ADR-018-decision-communication-contract.md` — the contract this makes measurable;
  its accepted cost was that prose is all there is.
- `vault/research/decision-communication.md` — the evidence base; §3 already records that a length
  linter is the only deterministic fix and was left out of scope, and R-16 records the accuracy floor
  below which terseness collapses correctness.
- `vault/indications/user-facing-communication.md` — the working rule item 13 updates.
- `vault/indications/enforced-not-just-stated.md` — a stated threshold must name the function
  computing it and ship a failing-without-it test; items 5, 14 and 15 satisfy it.
- `scripts/doc-lint-hook.sh` and `bin/doc-lint.sh` — the file-side machinery items 1–3 extract from
  rather than copy.
- `2026-09-03-0929-enforce-brevity-mechanically.trail.md` — rejected options and the review record.
