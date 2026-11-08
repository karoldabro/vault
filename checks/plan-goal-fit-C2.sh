#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C2 of vault/plans/2026-11-08-1337-plan-goal-fit.md.
# Met when T10-T11 title tests in tests/unit/gate.bats, T12 in tests/unit/pm-plan.bats, and both pass.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
u="$root/tests/unit"
want() { grep -Eq "^@test \"T$2[:[:space:]]" "$u/$1" || { printf 'no test titled T%s in tests/unit/%s\n' "$2" "$1"; exit 1; }; }
want gate.bats 10
want gate.bats 11
want pm-plan.bats 12
cd "$root" || exit 2
worst=0
for t in gate pm-plan; do
    ./tests/run.sh "tests/unit/$t.bats"
    rc=$?
    [ "$rc" -eq 2 ] && exit 2
    [ "$rc" -eq 0 ] || worst=1
done
exit "$worst"
