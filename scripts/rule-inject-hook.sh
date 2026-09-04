#!/usr/bin/env bash
# SessionStart hook: put the rules that nothing enforces back in front of the model.
#
# Re-injecting a constraint restores compliance that decayed, with no retraining — measured across
# 4,416 trials, where a prohibition given once fell from 73% at turn 5 to 33% by turn 16.
#
# It injects ONLY the prose list from vault/check-budget.md: rules kept with no check behind them.
# Everything else is enforced by bin/gate.sh, and a gate refuses whether or not the model remembers
# it, so restating an enforced rule would add to the instruction count and buy nothing.
#
# That coupling is the point. This hook cannot grow beyond the prose list, and the prose list
# shrinks as rules get checks. Nothing here is a place to add a new rule.
#
# Always exits 0. This one advises; scripts/completion-hook.sh is the one that blocks.
#
# Off: GATE=off

set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
COMMON="$(dirname "$SELF")/../lib/hook-common.sh"
[ -r "$COMMON" ] || exit 0
# shellcheck source=../lib/hook-common.sh
. "$COMMON"

hook_off GATE && exit 0

VAULT_ROOT="$(hook_vault_root "${BASH_SOURCE[0]}")"
BUDGET="${VAULT_ROOT}/vault/check-budget.md"
[ -r "$BUDGET" ] || exit 0

# Rows of the prose table: | rule | where | why no check |
rules="$(awk '
    $0 == "## Rules kept as prose" { in_sec = 1; next }
    in_sec && /^## /                { exit }
    !in_sec                         { next }
    /^\|[- |:]*\|$/                 { seen = 1; next }
    !seen                           { next }
    /^\|/ {
        line = $0
        sub(/^\|[ \t]*/, "", line)
        split(line, c, "|")
        gsub(/^[ \t]+|[ \t]+$/, "", c[1])
        gsub(/^[ \t]+|[ \t]+$/, "", c[2])
        if (c[1] != "") printf "  - %s (%s)\n", c[1], c[2]
    }
' "$BUDGET" 2>/dev/null)"

[ -n "$rules" ] || exit 0

printf 'Rules nothing checks, so they need you to hold them:\n%s\n' "$rules"
printf 'Everything else this framework asks for is refused by bin/gate.sh if you skip it.\n'
exit 0
