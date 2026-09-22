#!/usr/bin/env bash
# SC-5 of vault/plans/2026-09-22-0900-stack-packs.md — vault-init.sh writes stack_packs on a Laravel+SQL fixture.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
grep -q 'T-43' "$root/tests/unit/probe.bats" 2>/dev/null || { echo "tests/unit/probe.bats has no T-43 yet"; exit 2; }
"$root/tests/run.sh" tests/unit/probe.bats -f 'T-43' >/tmp/stack-packs-sc5.log 2>&1
rc=$?
[ "$rc" -eq 0 ] || { cat /tmp/stack-packs-sc5.log; exit 1; }
exit 0
