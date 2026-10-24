#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C1 of vault/plans/2026-10-24-1903-v-cr-abstract-review.md.
# Met when tests/unit/change-map.bats has a test titled with each Test-backlog id T1-T12 and the file passes.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/tests/unit/change-map.bats"
[ -f "$f" ] || { printf 'tests/unit/change-map.bats not written yet\n'; exit 1; }
for n in $(seq 1 12); do
    grep -Eq "^@test \"T$n[:[:space:]]" "$f" || { printf 'no test titled T%s in %s\n' "$n" "$f"; exit 1; }
done
cd "$root" || exit 2
./tests/run.sh tests/unit/change-map.bats
rc=$?
[ "$rc" -eq 0 ] && exit 0
[ "$rc" -eq 2 ] && exit 2
exit 1
