#!/usr/bin/env bash
# rule-compliance SC-3: a rule mentioned in prose is not scored as an invocation.
set -uo pipefail
out=$(./tests/run.sh tests/unit/rule-audit.bats 2>&1)
rc=$?
fails=$(printf '%s' "$out" | grep -c '^not ok')
if [ "$rc" -ne 0 ] || [ "$fails" -ne 0 ]; then
    printf 'rule-audit.bats: %s failing\n' "$fails"; exit 1
fi
printf 'rule-audit.bats: %s cases, 0 failing\n' "$(printf '%s' "$out" | grep -c '^ok')"
