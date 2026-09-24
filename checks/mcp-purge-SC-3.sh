#!/usr/bin/env bash
# SC-3 of vault/plans/2026-09-24-1651-remove-mcp-tools.md — the uninstall guide exists and carries
# the exact command for each removal step.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
doc="$root/docs/uninstall-removed-tools.md"
[ -r "$doc" ] || { echo "no guide at $doc"; exit 1; }
fail=0
for needle in 'claude plugin uninstall claude-mem@thedotmack' 'claude plugin marketplace remove thedotmack' \
              'claude mcp remove' '~/.claude-mem' 'claude mcp list' 'bun' 'pipx uninstall graphifyy' 'graphify hook uninstall' 'graphify-out' '~/.claude/skills/graphify'; do
    grep -qF -- "$needle" "$doc" || { echo "guide lacks: $needle"; fail=1; }
done
exit "$fail"
