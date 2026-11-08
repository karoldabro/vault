#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C1 of vault/plans/2026-11-08-1337-plan-goal-fit.md.
# Met when tests T1-T9 title tests in tests/unit/gate.bats and that file passes.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/tests/unit/gate.bats"
[ -f "$f" ] || exit 2
for n in 1 2 3 4 5 6 7 8 9; do
    grep -Eq "^@test \"T$n[:[:space:]]" "$f" || { printf 'no test titled T%s in tests/unit/gate.bats\n' "$n"; exit 1; }
done
cd "$root" || exit 2
./tests/run.sh tests/unit/gate.bats
rc=$?
[ "$rc" -eq 2 ] && exit 2
[ "$rc" -eq 0 ] || exit 1
