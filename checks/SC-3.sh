#!/usr/bin/env bash
# SC-3: a plan with no criterion that runs the real system is refused.
set -uo pipefail
out=$(./tests/run.sh tests/unit/gate.bats 2>&1)
rc=$?
fails=$(printf '%s' "$out" | grep -c '^not ok')
if [ "$rc" -ne 0 ] || [ "$fails" -ne 0 ]; then
    printf 'gate.bats: %s failing\n' "$fails"; exit 1
fi
printf 'gate.bats: %s cases, 0 failing\n' "$(printf '%s' "$out" | grep -c '^ok')"
