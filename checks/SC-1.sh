#!/usr/bin/env bash
# SC-1: a session that ends on an unproven completion claim is blocked.
set -uo pipefail
out=$(./tests/run.sh tests/unit/completion-hook.bats 2>&1)
rc=$?
fails=$(printf '%s' "$out" | grep -c '^not ok')
if [ "$rc" -ne 0 ] || [ "$fails" -ne 0 ]; then
    printf 'completion-hook.bats: %s failing\n' "$fails"; exit 1
fi
printf 'completion-hook.bats: %s cases, 0 failing\n' "$(printf '%s' "$out" | grep -c '^ok')"
