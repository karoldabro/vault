#!/usr/bin/env bash
# SC-6 of vault/plans/2026-10-12-0944-v-pm-planning-loop.md — the unit tests this plan touches.
# tests/run.sh takes one bats file per call. Exit 0 met, 1 not met.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
rc=0
for t in v-pm pm-plan planning-personas v-team research-clarify; do
    ./tests/run.sh "tests/unit/$t.bats" || { echo "tests/unit/$t.bats failed"; rc=1; }
done
exit "$rc"
