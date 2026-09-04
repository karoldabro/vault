#!/usr/bin/env bash
# SC-3 — every check bin/gate.sh implements has a row in vault/check-budget.md.
#
# The budget table is where a check's wrong-fire rate is counted. A check absent from it is a check
# whose noise nobody can measure, and an unmeasured check is the one that gets the whole gate
# switched off. Rows for things that are not subcommands (the hooks) are legal and ignored.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(dirname "$here")
gate="$root/bin/gate.sh"
budget="$root/vault/check-budget.md"

implemented=$(sed -n '/case "\$sub" in/,/^    esac/p' "$gate" |
              sed -n 's/^        \([a-z][a-z-]*\)).*/\1/p' | grep -vxE 'all' | sort -u)

listed=$(awk '/^## Check budget/{s=1;next} s&&/^## /{exit} s&&/^\|/{print}' "$budget" |
         cut -d'|' -f2 | tr -d '`*' | awk '{print $1}' |
         grep -xE '[a-z][a-z-]*' | grep -vxE 'check' | sort -u)

missing=$(comm -23 <(printf '%s\n' "$implemented") <(printf '%s\n' "$listed"))
if [ -n "$missing" ]; then
    printf 'implemented but absent from the check budget: %s\n' "$(echo $missing)" >&2
    exit 1
fi
exit 0
