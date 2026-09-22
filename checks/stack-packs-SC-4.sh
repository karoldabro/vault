#!/usr/bin/env bash
# SC-4 of vault/plans/2026-09-22-0900-stack-packs.md — no VAULT.md stack_packs key changes nothing.
# Regression guard: must pass before this plan's work starts and after every item lands.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[ -x "$root/tests/run.sh" ] || { echo "tests/run.sh is not executable"; exit 2; }
"$root/tests/run.sh" tests/unit/probe.bats >/tmp/stack-packs-sc4.log 2>&1
rc=$?
[ "$rc" -eq 0 ] || { cat /tmp/stack-packs-sc4.log; exit 1; }
exit 0
