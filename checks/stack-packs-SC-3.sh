#!/usr/bin/env bash
# SC-3 of vault/plans/2026-09-22-0900-stack-packs.md — stack_packs gates rows for a stack not listed.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
grep -q '"T-40:' "$root/tests/unit/probe.bats" 2>/dev/null || grep -q 'T-40' "$root/tests/unit/probe.bats" 2>/dev/null || { echo "tests/unit/probe.bats has no T-40 yet"; exit 2; }
"$root/tests/run.sh" tests/unit/probe.bats -f 'T-40' >/tmp/stack-packs-sc3.log 2>&1
rc=$?
[ "$rc" -eq 0 ] || { cat /tmp/stack-packs-sc3.log; exit 1; }
exit 0
