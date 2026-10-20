#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C2 of vault/plans/2026-10-20-1934-agent-systems-lens.md.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[ -f "$root/tests/unit/agent-skills.bats" ] || { printf 'agent-skills.bats not written yet\n'; exit 1; }
"$root/tests/run.sh" tests/unit/agent-skills.bats
rc=$?
[ "$rc" -eq 0 ] && exit 0
[ "$rc" -eq 2 ] && exit 2
exit 1
