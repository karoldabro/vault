#!/usr/bin/env bash
# SC-6 of vault/plans/2026-09-24-1651-remove-mcp-tools.md — this plan passes doc-lint and the approve gate.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
plan="$root/vault/plans/2026-09-24-1651-remove-mcp-tools.md"
[ -r "$plan" ] || { echo "plan file is missing"; exit 2; }
cd "$root" || exit 2
"$root/bin/doc-lint.sh" "$plan" >/tmp/mcp-purge-sc6.log 2>&1 || { cat /tmp/mcp-purge-sc6.log; exit 1; }
"$root/bin/gate.sh" all "$plan" --phase approve >>/tmp/mcp-purge-sc6.log 2>&1 || { cat /tmp/mcp-purge-sc6.log; exit 1; }
exit 0
