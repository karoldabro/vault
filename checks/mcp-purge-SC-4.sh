#!/usr/bin/env bash
# SC-4 of vault/plans/2026-09-24-1651-remove-mcp-tools.md — Serena stays documented, as optional.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pb="$root/tool-playbook.md"
[ -r "$pb" ] || exit 2
sec=$(awk '/^## [0-9]+\. Serena/{s=1;print;next} s&&/^## /{exit} s{print}' "$pb")
[ -n "$sec" ] || { echo "tool-playbook.md has no Serena section"; exit 1; }
grep -qi 'optional' <<<"$sec" || { echo "the Serena section does not say it is optional"; exit 1; }
grep -q 'check_serena' "$root/lib/installers.sh" || { echo "installer lost Serena"; exit 1; }
exit 0
