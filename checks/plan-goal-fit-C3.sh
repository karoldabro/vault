#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C3 of vault/plans/2026-11-08-1337-plan-goal-fit.md.
# Met when T13-T16 title tests in their planned files and the three contract test files pass.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
u="$root/tests/unit"
want() { grep -Eq "^@test \"T$2[:[:space:]]" "$u/$1" || { printf 'no test titled T%s in tests/unit/%s\n' "$2" "$1"; exit 1; }; }
want planning-personas.bats 13
want v-pm.bats 14
want v-team.bats 15
want planning-personas.bats 16
cd "$root" || exit 2
worst=0
for t in planning-personas v-pm v-team; do
    ./tests/run.sh "tests/unit/$t.bats"
    rc=$?
    [ "$rc" -eq 2 ] && exit 2
    [ "$rc" -eq 0 ] || worst=1
done
exit "$worst"
