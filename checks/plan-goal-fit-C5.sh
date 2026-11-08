#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C5 of vault/plans/2026-11-08-1337-plan-goal-fit.md.
# Met when T21-T27 title tests in tests/unit/goal-run.bats and that file passes.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/tests/unit/goal-run.bats"
[ -f "$f" ] || { printf 'tests/unit/goal-run.bats not written yet\n'; exit 1; }
for n in 21 22 23 24 25 26 27; do
    grep -Eq "^@test \"T$n[:[:space:]]" "$f" || { printf 'no test titled T%s in tests/unit/goal-run.bats\n' "$n"; exit 1; }
done
cd "$root" || exit 2
./tests/run.sh tests/unit/goal-run.bats
rc=$?
[ "$rc" -eq 2 ] && exit 2
[ "$rc" -eq 0 ] || exit 1
