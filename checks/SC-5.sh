#!/usr/bin/env bash
# SC-5: a check firing wrongly more than one time in ten is reported as over budget.
# Fails until E-01 builds the budget subcommand and its tests. Red now, green when it lands.
set -uo pipefail
[ -f tests/unit/gate-budget.bats ] || { printf 'tests/unit/gate-budget.bats does not exist yet (E-01)\n'; exit 1; }
out=$(./tests/run.sh tests/unit/gate-budget.bats 2>&1); rc=$?
fails=$(printf '%s' "$out" | grep -c '^not ok')
[ "$rc" -eq 0 ] && [ "$fails" -eq 0 ] || { printf 'gate-budget.bats: %s failing\n' "$fails"; exit 1; }
printf 'gate-budget.bats: %s cases, 0 failing\n' "$(printf '%s' "$out" | grep -c '^ok')"
