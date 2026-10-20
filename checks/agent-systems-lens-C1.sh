#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C1 of vault/plans/2026-10-20-1934-agent-systems-lens.md.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[ -f "$root/personas/_shared/planning/agent-systems.md" ] || { printf 'agent-systems lens not written yet\n'; exit 1; }
"$root/tests/run.sh" tests/unit/planning-personas.bats
rc=$?
[ "$rc" -eq 0 ] && exit 0
[ "$rc" -eq 2 ] && exit 2
exit 1
