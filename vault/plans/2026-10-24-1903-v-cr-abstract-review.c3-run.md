```text
Spawned: [change-impact → root-cause-analyst, test-gap → quality-engineer, architecture-fit → system-architect, pattern-conformance → refactoring-expert, intent-trace → requirements-analyst]

PERSONA: change-impact
VERDICT: BLOCK
FINDINGS:
  - id: change-impact-1
    severity: BLOCKER
    grounding: confirmed
    check: caller row bin/report.sh:6 `format_row "$name" "$count"` (git show HEAD:bin/report.sh) passes 2 args; changed lib/format.sh:5 `_need_args 3 $# || return 2` with lib/args.sh:4-6 (`[ "$2" -ge "$1" ] && return 0` ... `return 2`) makes every report.sh run print "need 3 args" to stderr, emit no row, and exit 2
    target: lib/format.sh:5
    issue: format_row now requires a third <unit> argument, and its only production caller bin/report.sh:6 still passes two, so the report script emits no row and exits 2.
    recommendation: Update bin/report.sh to read a unit (e.g. `unit=$3`) and call `format_row "$name" "$count" "$unit"`; proposed test: a bats case that runs bin/report.sh with name, count and unit and asserts output `n | c | u` and exit 0.
  - id: change-impact-2
    severity: BLOCKER
    grounding: confirmed
    check: caller row tests/format.bats:5 `run format_row a b` and :6 `[ "$output" = "a | b" ]` (git show HEAD:tests/format.bats) against changed lib/format.sh:5-6 (3-arg guard, 3-column printf); the call now returns 2 with stderr "need 3 args"; co-change row lib/format.sh <-> tests/format.bats 4/4, and this commit is the first that changes lib/format.sh without tests/format.bats (git log --name-only)
    target: lib/format.sh:6
    issue: tests/format.bats:5-6 still calls format_row with two arguments and asserts the two-column output "a | b", so the suite fails at head; the always-co-changed test file was left untouched.
    recommendation: Change tests/format.bats to `run format_row a b c` and assert `[ "$output" = "a | b | c" ]`, rename the test to "format_row prints three columns", and add a case asserting status 2 when only two arguments arrive.
FILES_EXAMINED:
  - read	L5:"_need_args 3 $# || return 2" — checked every caller and referrer row in the slice (bin/report.sh:6, tests/format.bats:3-5) plus git grep -n -w format_row HEAD (5 hits, all in slice); two callers broken	lib/format.sh
  - read	L3:"slug_make() {" — new function; git grep -n -w slug_make HEAD prints only lib/slug.sh:2-3, so no caller or referrer can be left wrong	lib/slug.sh
  - context	caller of format_row at L6, still two args	bin/report.sh
  - context	caller of format_row at L5, two args and two-column assertion; co-change partner 4/4	tests/format.bats
  - context	_need_args semantics: returns 2 when got < want	lib/args.sh

PERSONA: test-gap
VERDICT: REQUEST_CHANGES
FINDINGS:
  - id: test-gap-1
    severity: MAJOR
    grounding: confirmed
    check: test line tests/format.bats:5:"run format_row a b" and tests/format.bats:6:"[ \"$output\" = \"a | b\" ]" against subject line lib/format.sh:5:"_need_args 3 $# || return 2" (lib/args.sh:4-6 returns 2 and prints "need 3 args" when $2 < $1). `git grep -n -w format_row HEAD -- tests` prints only tests/format.bats:3 and :5; no test calls format_row with three arguments.
    target: lib/format.sh:5
    issue: The only format_row test still asserts the old two-argument, two-column contract, so it now fails against the changed code, and nothing tests the new three-column output or the rejection of a two-argument call.
    recommendation: Rewrite tests/format.bats in the same change. Test 1 (format_row, tests/format.bats): `run format_row a b kg` asserts status 0 and output "a | b | kg". Test 2 (format_row, tests/format.bats): `run format_row a b` asserts status 2 and output containing "need 3 args", which proves the new arity gate fires.
  - id: test-gap-2
    severity: MINOR
    grounding: confirmed
    check: slice rows `test lib/slug.sh slug_make none`; `git grep -n -w slug_make HEAD -- tests` printed nothing (exit 1).
    target: lib/slug.sh:3
    issue: The new helper slug_make has no test; it has no caller outside its own header comment yet, so the gap is internal rather than on a public path.
    recommendation: Add tests/slug.bats. Test 3 (slug_make, tests/slug.bats): `run slug_make "My Report"` asserts output "my-report"; add a case for a title containing "/" so the test records whether slug_make yields a safe file name, since `tr 'A-Z ' 'a-z-'` passes "/" through unchanged.
FILES_EXAMINED:
  - read	L5:"_need_args 3 $# || return 2"; checked that tests/format.bats exercises the new arity and third column (it does not — test-gap-1)	lib/format.sh
  - read	L4:"printf '%s\n' \"$1\" | tr 'A-Z ' 'a-z-'"; checked for any test naming slug_make (none — test-gap-2)	lib/slug.sh
  - context	subject-under-test test for format_row; unchanged in this diff; L6 asserts the old two-column output	tests/format.bats
  - context	_need_args behaviour that decides format_row's failure path	lib/args.sh
  - context	caller row from slice; passes two arguments to format_row (caller breakage belongs to change-impact)	bin/report.sh

PERSONA: architecture-fit
VERDICT: BLOCK
FINDINGS:
  - id: architecture-fit-1
    severity: BLOCKER
    grounding: confirmed
    check: relation-map rows `referenced-by lib/format.sh -> bin/report.sh:2` and `referenced-by lib/format.sh -> tests/format.bats:4`; `git grep -n format_row HEAD` shows both consumers still pass two arguments at head: bin/report.sh:6 `format_row "$name" "$count"` and tests/format.bats:5 `run format_row a b` (assertion at tests/format.bats:6 expects `a | b`). lib/args.sh:4 `_need_args` returns 2 when fewer than the wanted count arrive, so both calls now print `need 3 args` and return 2.
    target: lib/format.sh:6
    issue: The diff changes the public contract of format_row from two arguments to three (`_need_args 3 $# || return 2`) and updates neither of its two consumers, so bin/report.sh emits no row and tests/format.bats fails.
    recommendation: Either update both consumers in this change (bin/report.sh takes a unit argument and passes it as the third argument; tests/format.bats asserts three columns, e.g. `run format_row a b c` / `[ "$output" = "a | b | c" ]`), or keep the contract compatible by defaulting the unit (`_need_args 2 $#` and print the third column only when `$3` is set). Proposed contract tests: (1) bats test that bin/report.sh with name, count and unit prints one `name | count | unit` row and exits 0; (2) bats test that format_row with two arguments behaves as the chosen contract states (returns 2 with `need 3 args`, or prints two columns if the unit is optional).
FILES_EXAMINED:
  - read	L6:"_need_args 3 $# || return 2" — contract changed from 2 to 3 args; consumers traced via referenced-by rows; dependency on lib/args.sh unchanged and points lib->lib	lib/format.sh
  - read	L4:"printf '%s\n' "$1" | tr 'A-Z ' 'a-z-'" — new helper sits in lib/ beside other single-function helpers (args, pad, trim, format); no references rows and no referenced-by rows, so no layering or contract issue	lib/slug.sh
  - context	consumer of format_row; L6 still passes two arguments	bin/report.sh
  - context	consumer of format_row; L5-L6 still assert the two-column output	tests/format.bats
  - context	_need_args semantics: returns 2 when got < want	lib/args.sh
RULES_CHECKED:

PERSONA: pattern-conformance
VERDICT: BLOCK
PATTERN (from siblings, before judging the change): every lib/*.sh function file sources args.sh on line 2-3 and opens its function with `_need_args <n> $# || return 2` — lib/pad.sh:2,4; lib/trim.sh:2,4; lib/format.sh:3,5 (head).
FINDINGS:
  - id: pattern-conformance-1
    severity: BLOCKER
    grounding: confirmed
    check: lib/pad.sh:2 `. "$(dirname "${BASH_SOURCE[0]}")/args.sh"` + lib/pad.sh:4 `_need_args 2 $# || return 2`; lib/trim.sh:2 same source line + lib/trim.sh:4 `_need_args 1 $# || return 2` (git show HEAD:<path>). lib/slug.sh has neither (git show HEAD:lib/slug.sh, 5 lines).
    target: lib/slug.sh:3
    issue: slug_make skips the input guard every sibling lib function applies, so a call with no title prints an empty slug and returns 0 instead of `need 1 args` on stderr and status 2.
    recommendation: Add `. "$(dirname "${BASH_SOURCE[0]}")/args.sh"` after the header comment and make `_need_args 1 $# || return 2` the first line of slug_make.
PROPOSED_TESTS:
  - tests/slug.bats: `. lib/slug.sh; run slug_make; [ "$status" -eq 2 ]; [ "$output" = "need 1 args" ]` — pins the guard pattern shared with pad_left and trim_space.
FILES_EXAMINED:
  - read	L5:"_need_args 3 $# || return 2" — conforms: sources args.sh (L3) and guards first (L5), same as pad.sh/trim.sh	lib/format.sh
  - read	L3:"slug_make() {" — departs: no args.sh source, no _need_args guard (pattern-conformance-1)	lib/slug.sh
  - context	sibling pattern source: L2 source args.sh, L4 _need_args 2	lib/pad.sh
  - context	sibling pattern source: L2 source args.sh, L4 _need_args 1	lib/trim.sh
  - context	guard definition: L3 "_need_args() {", returns 2 with stderr message	lib/args.sh
OUT_OF_LANE (not scored here): bin/report.sh:6 still calls format_row with 2 args and tests/format.bats:5-6 expects two columns; both now fail against the 3-arg guard — change-impact / test-gap own these.

PERSONA: intent-trace
VERDICT: BLOCK
FINDINGS:
  - id: intent-trace-1
    severity: BLOCKER
    grounding: confirmed
    check: requirement "Add slug_make for report file names, with tests." — `git grep -nw slug_make HEAD -- tests` prints nothing (rc=1); `git diff --stat HEAD~1 HEAD` lists only lib/format.sh and lib/slug.sh, no file under tests/
    target: lib/slug.sh:3
    issue: The task asks for slug_make "with tests" and the diff adds slug_make with no test at all.
    recommendation: Add tests/slug.bats that sources lib/slug.sh and asserts `slug_make "Monthly Report"` prints `monthly-report`.
  - id: intent-trace-2
    severity: MAJOR
    grounding: confirmed
    check: requirement "Add a unit column to report rows." — the only report-row producer, bin/report.sh:6 at HEAD, still calls `format_row "$name" "$count"` with two arguments; lib/format.sh:6 now demands three (`_need_args 3 $# || return 2`), so the report prints no row instead of a row with a unit. tests/format.bats:5-6 still runs `format_row a b` and expects `a | b`.
    target: lib/format.sh:7
    issue: The diff adds the unit column to format_row only; report rows never gain it, because bin/report.sh supplies no unit and its call now fails.
    recommendation: Have bin/report.sh read a unit (for example `unit=$3`) and call `format_row "$name" "$count" "$unit"`; update tests/format.bats to call `format_row a b kg` and expect `a | b | kg`.
FILES_EXAMINED:
  - read	R1 unit column delivered at the format layer; checked against the task text L7:"printf '%s | %s | %s\n' "$1" "$2" "$3""	lib/format.sh
  - read	R2 slug_make added; no caller and no test at HEAD L3:"slug_make() {"	lib/slug.sh
  - context	only report-row caller of format_row; still passes two arguments (L6)	bin/report.sh
  - context	existing format_row test still asserts the two-column output (L5-6)	tests/format.bats

REQUIREMENTS (summary-only advisory set):
  - R1 "Add a unit column to report rows." — not compliant (partial): lib/format.sh:2,6,7 add the third column; bin/report.sh:6 never passes a unit, so report rows do not carry it. See intent-trace-2.
  - R2 "Add slug_make" — compliant: lib/slug.sh:1-5.
  - R2a "for report file names" — needs a human: `git grep -n slug_make HEAD` finds only the definition in lib/slug.sh; bin/report.sh writes to stdout and names no file, so the task does not say whether wiring slug_make into a caller was in scope.
  - R3 "with tests" — not compliant: no test for slug_make, and the existing format_row test was not updated for the unit column. See intent-trace-1.
UNREQUESTED BEHAVIOUR: none. The only other change is dropping "— revision 4" from the lib/format.sh:2 comment, which changes no behaviour.
PROPOSED TESTS:
  - tests/slug.bats: `slug_make "Monthly Report"` prints `monthly-report` (R3).
  - tests/format.bats: `format_row a b kg` prints `a | b | kg` (R1).
  - tests/report.bats: `bin/report.sh apples 3 kg` prints `apples | 3 | kg` (R1, report rows).
```

