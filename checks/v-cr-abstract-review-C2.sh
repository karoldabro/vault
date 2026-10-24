#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C2 of vault/plans/2026-10-24-1903-v-cr-abstract-review.md.
# Met when each Test-backlog id T13-T22 titles a test in its planned file and the four files pass.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
u="$root/tests/unit"
want() { # <file> <first id> <last id>
    local f="$u/$1" n
    [ -f "$f" ] || { printf 'tests/unit/%s not written yet\n' "$1"; exit 1; }
    for n in $(seq "$2" "$3"); do
        grep -Eq "^@test \"T$n[:[:space:]]" "$f" || { printf 'no test titled T%s in tests/unit/%s\n' "$n" "$1"; exit 1; }
    done
}
want review-personas.bats 13 16
want v-cr.bats 17 21
want v-cr-abstract-review-c3.bats 22 22
cd "$root" || exit 2
# tests/run.sh takes one target, so each file runs on its own.
worst=0
for t in review-personas v-cr cr-coverage v-cr-abstract-review-c3; do
    ./tests/run.sh "tests/unit/$t.bats"
    rc=$?
    [ "$rc" -eq 2 ] && exit 2
    [ "$rc" -eq 0 ] || worst=1
done
exit "$worst"
