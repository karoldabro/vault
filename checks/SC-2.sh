#!/usr/bin/env bash
# SC-2: a criterion's check must be a committed script, not a command typed into the plan.
set -uo pipefail
out=$(./tests/run.sh tests/unit/gate.bats 2>&1)
rc=$?
fails=$(printf '%s' "$out" | grep -c '^not ok')
if [ "$rc" -ne 0 ] || [ "$fails" -ne 0 ]; then
    printf 'gate.bats: %s failing\n' "$fails"; exit 1
fi
printf 'gate.bats: %s cases, 0 failing\n' "$(printf '%s' "$out" | grep -c '^ok')"
