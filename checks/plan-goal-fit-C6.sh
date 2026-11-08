#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C6 of vault/plans/2026-11-08-1337-plan-goal-fit.md.
# Met when T28-T29 title tests in tests/unit/v-work.bats, T30 in tests/unit/v-pm.bats, and both pass.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
u="$root/tests/unit"
want() { grep -Eq "^@test \"T$2[:[:space:]]" "$u/$1" || { printf 'no test titled T%s in tests/unit/%s\n' "$2" "$1"; exit 1; }; }
want v-work.bats 28
want v-work.bats 29
want v-pm.bats 30
cd "$root" || exit 2
worst=0
for t in v-work v-pm; do
    ./tests/run.sh "tests/unit/$t.bats"
    rc=$?
    [ "$rc" -eq 2 ] && exit 2
    [ "$rc" -eq 0 ] || worst=1
done
exit "$worst"
