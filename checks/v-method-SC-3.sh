#!/usr/bin/env bash
# SC-3 — every routing row is complete, and every task property is one a session can decide.
#
# No validated instrument turns a task description into a process, so this routing table is a
# heuristic. A heuristic with a blank cell is worse than none: the session picks a method and cannot
# say what would end it. The property column is the load-bearing one — a row keyed on a judgement
# ("the task is complex") routes on nothing, so each property must read as a checkable fact.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ref="$root/commands/v-method/routing.md"
fail=0

[ -f "$ref" ] || { printf '  MISSING  %s does not exist yet\n' "$ref"; exit 1; }

# The routing table: four columns, no blanks, at least eight rows to be worth consulting.
rows=$(awk -F'|' '
    /^\| *[Tt]ask property/ { intbl = 1; next }
    intbl && /^\|[-: ]+\|/  { next }
    intbl && !/^\|/         { intbl = 0 }
    intbl && /^\|/ {
        n = NF - 2
        blank = 0
        for (i = 2; i <= NF - 1; i++) { c = $i; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == "") blank = 1 }
        printf "%d\t%d\n", n, blank
    }
' "$ref")

[ -n "$rows" ] || { printf '  FAIL  %s has no table whose first column is the task property\n' "$ref"; exit 1; }

count=$(printf '%s\n' "$rows" | grep -c .)
blanks=$(printf '%s\n' "$rows" | awk -F'\t' '$2 == 1' | grep -c . || true)
widths=$(printf '%s\n' "$rows" | awk -F'\t' '{print $1}' | sort -u | tr '\n' ' ')

[ "$count" -ge 8 ] || { printf '  FAIL  the routing table has %s rows; under eight it is not worth a read\n' "$count"; fail=1; }
[ "$blanks" -eq 0 ] || { printf '  FAIL  %s routing row(s) carry a blank cell — a method with no stopping rule never ends\n' "$blanks"; fail=1; }
[ "$(printf '%s' "$widths" | tr -d ' ')" = "4" ] || { printf '  FAIL  routing rows have differing widths (%s); a shifted row reads one column under another\n' "$widths"; fail=1; }

# A property the session cannot decide routes on nothing. These are the words that make one
# undecidable, and a row containing any of them is a judgement wearing a property's clothes.
vague=$(awk -F'|' '
    /^\| *[Tt]ask property/ { intbl = 1; next }
    intbl && /^\|[-: ]+\|/  { next }
    intbl && !/^\|/         { intbl = 0 }
    intbl && /^\|/ { p = $2; if (p ~ /complex|complicated|hard|difficult|large|important|tricky/) print $2 }
' "$ref")
if [ -n "$vague" ]; then
    printf '  FAIL  routing propert(ies) are a judgement, not a checkable fact:%s\n' "$(printf '%s' "$vague" | tr '\n' ';')"
    fail=1
fi

# The honesty line. Claiming a validated router would be the one unsupportable claim in the file.
grep -qiE 'no validated|heuristic' "$ref" || {
    printf '  FAIL  %s does not record that the routing is a heuristic with no validated instrument behind it\n' "$ref"; fail=1; }

[ "$fail" -eq 0 ] || exit 1
printf '  OK  %s routing rows, four columns each, no blanks, no judgement-shaped property\n' "$count"
