#!/usr/bin/env bash
# SC-5 of vault/plans/2026-10-18-1257-quality-loops.md — six test-design generators, each decorrelated, selected by trigger.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
fail() { printf '%s\n' "$*"; exit 1; }
d=personas/_shared/testing/design
for g in fault-relation-prospector business-logic-cartographer boundary-property-explorer api-contract-mapper abuse-case-designer performance-budget-designer; do
    f="$d/$g.md"; [ -r "$f" ] || fail "$f is missing"
    n=$(grep -c 'NOT →' "$f"); [ "$n" -ge 2 ] || fail "$f carries $n NOT → lines, needs a critic line and a generator line"
    grep -q "$g" "$d/README.md" || fail "$d/README.md does not list $g"
done
for g in api-contract-mapper abuse-case-designer performance-budget-designer; do
    grep "$g" "$d/README.md" | grep -qi 'trigger\|when' || fail "$d/README.md gives $g no trigger"
done
grep -q 'testing loop' "$d/README.md" || fail "$d/README.md does not route confirmation to the testing loop"
exit 0
