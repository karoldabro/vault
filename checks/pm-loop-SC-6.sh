#!/usr/bin/env bash
# SC-6 of vault/plans/2026-10-12-0944-v-pm-planning-loop.md — the unit tests this plan touches.
# tests/run.sh takes one bats file per call. One failure predates this plan and is tolerated by name:
# research-clarify "v-team PROPOSE output contract is two-layer…" fails on e292f48 too.
# Exit 0 met, 1 not met.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
known='v-team PROPOSE output contract is two-layer and translates panel vocabulary'
rc=0
for t in v-pm pm-plan planning-personas v-team research-clarify; do
    out=$(./tests/run.sh "tests/unit/$t.bats" 2>&1)
    bad=$(grep '^not ok' <<<"$out" | grep -vF "$known" || true)
    grep -q '^1\.\.' <<<"$out" || { echo "tests/unit/$t.bats did not run"; rc=1; continue; }
    [ -z "$bad" ] || { echo "tests/unit/$t.bats: $bad"; rc=1; }
done
exit "$rc"
