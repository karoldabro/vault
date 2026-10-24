```text
Spawned: [change-impact → root-cause-analyst, test-gap → quality-engineer, architecture-fit → system-architect, pattern-conformance → refactoring-expert, intent-trace → requirements-analyst]

PERSONA: change-impact
VERDICT: APPROVE
FINDINGS: []
  # No caller or referrer at HEAD is left wrong. format_row moved from 2 to 3 required arguments (lib/format.sh:5); `git grep -n -w format_row HEAD` prints 6 rows, and the only non-test, non-comment caller (bin/report.sh:8) now passes 3 arguments. The 2 test callers (tests/format.bats:4,10) match the new contract. bin/report.sh gained a required 3rd argument; its only referrer is tests/report.bats:3,8, which passes 3 and 2 arguments to match. `git grep -n -i revision HEAD` prints nothing, so no file cites the deleted "revision 4" comment. History pairs lib/format.sh with tests/format.bats in 4 of 4 commits (`git log --name-only`); both changed in this commit. slug_make is new with no callers outside its test, so nothing upstream can break. Map status is complete with no withheld rows.
FILES_EXAMINED:
  - read	L3:"_need_args 3 $# || exit 2" — caller of format_row passes 3 args at L8; the argument guard resolves through lib/format.sh -> lib/args.sh	bin/report.sh
  - read	L5:"_need_args 3 $# || return 2" — new arity checked against all 6 git grep -w format_row rows at HEAD	lib/format.sh
  - read	L5:"_need_args 1 $# || return 2" — new file; slug_make has no callers outside tests/slug.bats	lib/slug.sh
  - read	L4:"run format_row a b c" — test callers match the 3-argument contract; co-change partner of lib/format.sh, updated in this commit	tests/format.bats
  - read	L3:"run bin/report.sh apples 3 kg" — only referrer of bin/report.sh; matches the new 3rd argument	tests/report.bats
  - read	L4:"run slug_make \"Monthly Report\"" — only caller of slug_make	tests/slug.bats
  - context	sources _need_args; its semantics (returns 2 when $2 < $1) confirm both new guards refuse 2 arguments	lib/args.sh

PERSONA: test-gap
VERDICT: APPROVE_WITH_NITS
FINDINGS:
  - id: test-gap-1
    severity: MINOR
    grounding: advisory
    check: git grep -n 'slug_make *$\|run slug_make$' HEAD -- tests  -> empty (rc=1); tests/slug.bats:4 calls slug_make with one argument only
    target: lib/slug.sh:5
    issue: The new refusal branch `_need_args 1 $# || return 2` in slug_make has no test, so deleting it would leave every test green.
    recommendation: Add to tests/slug.bats a test `slug_make refuses no title` that runs `slug_make` with no arguments and asserts `[ "$status" -eq 2 ]`.
  - id: test-gap-2
    severity: MINOR
    grounding: advisory
    check: tests/slug.bats:4-5 is the only slug_make assertion and uses "Monthly Report" (letters and one space); lib/slug.sh:6 `tr 'A-Z ' 'a-z-'` passes every other character through unchanged
    target: lib/slug.sh:6
    issue: slug_make is documented as "a file name for a report" (lib/slug.sh:2), but no test covers a title with punctuation or repeated spaces, so an input such as "Q3/Report" yielding "q3/report" (a path separator in a file name) or "a  b" yielding "a--b" goes unchecked.
    recommendation: Add to tests/slug.bats a test that pins the intended output for a title containing `/` and a double space; if the current pass-through is not intended, the test drives the fix in lib/slug.sh:6.
FILES_EXAMINED:
  - read	L3:"_need_args 3 $# || exit 2" — guard checked against tests/report.bats:8-9: without L3, format_row receives an empty third argument and returns 0, so the refusal test exercises L3 itself, not format_row	bin/report.sh
  - read	L6:"_need_args 3 $# || return 2" — tests/format.bats:8-11 fails on the old 2-argument guard (old code printed "a | b", status 0); L7 printf covered by tests/format.bats:2-5; git grep -w format_row HEAD shows bin/report.sh:8 as the only production caller	lib/format.sh
  - read	L6:"printf '%s\n' "$1" | tr 'A-Z ' 'a-z-'" — happy path covered by tests/slug.bats:2-6; refusal branch L5 and non-letter input untested (test-gap-1, test-gap-2); no production caller (git grep -w slug_make HEAD hits only lib/slug.sh and tests/slug.bats)	lib/slug.sh
  - read	L9:"run format_row a b" — both assertions fail on the pre-change code (old output "a | b"; old status 0); no fixture bypasses _need_args since the test sources the real lib/format.sh, which sources the real lib/args.sh	tests/format.bats
  - read	L3:"run bin/report.sh apples 3 kg" — both tests fail on the pre-change code (old output "apples | 3"; old status 0); runs the real script, no stubbing	tests/report.bats
  - read	L4:"run slug_make "Monthly Report"" — assertion derived from the input by hand, not by reimplementing tr; covers the happy path only	tests/slug.bats
  - context	subject-of-test helper: _need_args returns 2 when $2 < $1; no test names it (git grep -n -w _need_args HEAD -- tests -> empty) but every caller's refusal test covers it indirectly	lib/args.sh

PERSONA: architecture-fit
VERDICT: APPROVE_WITH_NITS
FINDINGS:
  - id: architecture-fit-1
    severity: MINOR
    grounding: advisory
    check: git grep -n 'args.sh' HEAD -> sourced only by lib/format.sh:3, lib/pad.sh:2, lib/slug.sh:3, lib/trim.sh:2 (4 of the 4 _need_args callers outside bin/); the slice's references rows to lib/args.sh come only from lib/format.sh and lib/slug.sh, and no row bin/report.sh -> lib/args.sh exists (map-status complete). No architecture record exists, so this stays advisory.
    target: bin/report.sh:3
    issue: bin/report.sh:3 now calls the underscore-private helper _need_args from lib/args.sh without sourcing lib/args.sh, so the entry script reaches a library-internal helper only through lib/format.sh's own include at lib/format.sh:3, and it breaks when lib/format.sh stops sourcing args.sh.
    recommendation: Source lib/args.sh explicitly in bin/report.sh (`. "$(dirname "$0")/../lib/args.sh"`) so the dependency appears as its own references row, or move the argument-count check behind a public entry point in lib/ that bin/ is meant to call.
FILES_EXAMINED:
  - read	L3:"_need_args 3 $# || exit 2" new dependency on lib/args.sh checked against the references rows; finding architecture-fit-1	bin/report.sh
  - read	L5:"_need_args 3 $# || return 2" format_row arity 2->3 is a contract change; the repo has no architecture records or versioning rule, and its only caller (bin/report.sh:8) is updated in the same diff; references row to lib/args.sh unchanged; no finding	lib/format.sh
  - read	L4:"slug_make() {" new file placed in lib/ beside generic string helpers (pad.sh, trim.sh); it sources args.sh like its siblings; no reverse dependency on bin/; placement fits; no finding	lib/slug.sh
  - read	L2:"@test \"format_row prints three columns\" {" tests/ sources lib/ only; dependency direction fits; no finding	tests/format.bats
  - read	L3:"run bin/report.sh apples 3 kg" tests/ calls bin/ only; dependency direction fits; no finding	tests/report.bats
  - read	L3:". lib/slug.sh" tests/ sources lib/ only; placement fits; no finding	tests/slug.bats
  - context	_need_args definition, the target of the new bin/report.sh dependency	lib/args.sh
RULES_CHECKED:

PERSONA: pattern-conformance
VERDICT: APPROVE
FINDINGS: []
PATTERN (written from siblings at HEAD before judging the change):
  - lib function file: L1 shebang; source args.sh via `. "$(dirname "${BASH_SOURCE[0]}")/args.sh"` (lib/pad.sh:2, lib/trim.sh:2); one function whose first line is `_need_args <n> $# || return 2` (lib/pad.sh:4, lib/trim.sh:4); output via printf, piping `printf '%s\n' "$1" | <filter>` for text transforms (lib/trim.sh:5).
  - optional usage comment shape `# <fn> <args> — <description>` (lib/args.sh:2).
  - test file: L1 `#!/usr/bin/env bats`; each @test sources `lib/<file>.sh`, `run <fn> ...`, asserts `[ "$output" = ... ]` (tests/pad.bats:1-5).
  - the only bin script (bin/report.sh) has no bin sibling, so its argument guard is judged against the lib guard pattern.
FILES_EXAMINED:
  - read	argument guard `_need_args 3 $# || exit 2` matches lib/pad.sh:4 and lib/trim.sh:4, using exit for a script in place of return; source line unchanged; checked guard, error exit code 2, positional reads; L3:"_need_args 3 $# || exit 2"	bin/report.sh
  - read	guard and printf shape unchanged in form (lib/pad.sh:4-5); usage comment now matches lib/args.sh:2 shape; the stale `revision 4` marker is gone; L2:"# format_row <name> <count> <unit>"	lib/format.sh
  - read	new file layout matches lib/pad.sh and lib/trim.sh: shebang, args.sh source line, `_need_args 1 $# || return 2`, `printf '%s\n' "$1" | tr` like lib/trim.sh:5; usage comment matches lib/args.sh:2; L5:"_need_args 1 $# || return 2"	lib/slug.sh
  - read	@test layout matches tests/pad.bats:2-5 (source, run, assert); the status-2 refusal test matches the return code of lib/args.sh:6; L8:"@test \"format_row refuses two arguments\" {"	tests/format.bats
  - read	shebang and run/assert layout match tests/pad.bats; runs the script directly because it is a bin entry point, not a sourced lib; L3:"run bin/report.sh apples 3 kg"	tests/report.bats
  - read	layout matches tests/pad.bats:2-5 line for line; L3:"    . lib/slug.sh"	tests/slug.bats
  - context	sibling: guard helper and its exit code 2	lib/args.sh
  - context	sibling: lib function pattern	lib/pad.sh
  - context	sibling: lib function pattern, printf-pipe transform	lib/trim.sh
  - context	sibling: bats test layout	tests/pad.bats

PERSONA: intent-trace
VERDICT: APPROVE_WITH_NITS
REQUIREMENTS (summary-only advisory set; task = PR body, quoted verbatim):
  - R1 "Add a unit column to report rows" — compliant. lib/format.sh:5-6 (`_need_args 3`, `printf '%s | %s | %s\n'`), bin/report.sh:6,8 (`unit=$3`, `format_row "$name" "$count" "$unit"`).
  - R2 "Add slug_make for report file names" — needs a human. lib/slug.sh:4 defines slug_make. `git grep -n slug_make HEAD` prints only lib/slug.sh:2,4 and tests/slug.bats:2,4; nothing names a report file with it, and bin/report.sh writes only to stdout. The diff delivers the function; whether "for report file names" also required wiring it into report output is a question for the task author.
  - R3 "with tests" — compliant. tests/slug.bats:2-6 (slug_make); tests/format.bats:2-12 and tests/report.bats:2-10 (unit column).
UNREQUESTED BEHAVIOUR:
  - The unit is mandatory: bin/report.sh and format_row exit 2 on two arguments (finding intent-trace-1).
  - Comment edits dropping "revision 4" in lib/format.sh:2 and tests/format.bats:1 — no behaviour change; excluded as style.
FINDINGS:
  - id: intent-trace-1
    severity: MINOR
    grounding: confirmed
    check: task says "Add a unit column to report rows" and states no argument check; bin/report.sh:3 `_need_args 3 $# || exit 2` (new line; report.sh had no argument check at HEAD~1) and lib/format.sh:5 `_need_args 3 $# || return 2` (was `_need_args 2`) turn every two-argument call into exit 2; tests/report.bats:7-10 and tests/format.bats:8-12 lock that refusal in.
    target: bin/report.sh:3
    issue: The diff makes the unit a required argument and refuses old two-argument calls, which the task did not ask for; it asked only for the column.
    recommendation: Confirm with the task author that refusing a missing unit is intended; if not, default the unit (for example `unit=${3:-}`) and keep `_need_args 2`, and drop the two refusal tests.
  - id: intent-trace-2
    severity: MINOR
    grounding: advisory
    check: `git grep -n slug_make HEAD` → lib/slug.sh:2, lib/slug.sh:4, tests/slug.bats:2, tests/slug.bats:4 only; no caller produces a report file name.
    target: lib/slug.sh:4
    issue: slug_make is added "for report file names" but no code path names a report file with it, so the stated purpose is delivered only if the task meant the helper alone.
    recommendation: Ask the task author whether R2 requires a caller; if it does, wire slug_make into the code that names report files and test that path.
FILES_EXAMINED:
  - read	R1 delivery; new arg guard checked against task scope L3:"_need_args 3 $# || exit 2"	bin/report.sh
  - read	R1 delivery; arity change from 2 to 3 L6:"printf '%s | %s | %s\n'"	lib/format.sh
  - read	R2 delivery; grep for callers empty beyond tests L4:"slug_make() {"	lib/slug.sh
  - read	R3 for R1; refusal test is unrequested behaviour L8:"format_row refuses two arguments"	tests/format.bats
  - read	R3 for R1; refusal test is unrequested behaviour L7:"report.sh refuses a missing unit"	tests/report.bats
  - read	R3 for R2; one test covers slug_make L2:"slug_make lowercases and dashes a title"	tests/slug.bats
  - context	_need_args returns 2 when fewer args than wanted; confirms the refusal path	lib/args.sh
```

