#!/usr/bin/env bash
# goal-trace.sh — count how much of the operator's goal the sessions of a master plan own.
#
# Usage:  bin/goal-trace.sh <plan>
#
# Reads `## Goal cases` and `## Sessions` of <plan>. Prints `owned N/M`, where M is the sum of the
# `count` cells and N the sum over rows whose owner is a session that is not `dropped`, or
# `operator`. Then prints one `unowned <id>: <case> (<count>)` line per row that no session owns, and
# one `bad <id>: <problem>` line per row whose count or owner cannot be read.
#
# Contract: templates/master-plan.md `## Goal cases`, which owns the column rules.
#
# Exit: 0 every case owned · 1 a case is unowned or a row is bad · 2 no table, or unreadable

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=gate.sh
. "$ROOT/bin/gate.sh"

trace_die() { printf 'goal-trace: %s\n' "$*" >&2; exit 2; }

plan=${1:-}
[ -n "$plan" ] || trace_die "usage: bin/goal-trace.sh <plan>"
{ [ -f "$plan" ] && [ -r "$plan" ]; } || trace_die "cannot read: $plan"

gh=$(table_header <(master_src "$plan") '## Goal cases' || true)
[ -n "$gh" ] || trace_die "$plan has no ## Goal cases table"
g_id=$(col_index "$gh" id); g_case=$(col_index "$gh" case)
g_n=$(col_index "$gh" count); g_own=$(col_index "$gh" owner); g_st=$(col_index "$gh" status)
for c in g_id g_case g_n g_own; do [ -n "${!c}" ] || trace_die "## Goal cases lacks the ${c#g_} column"; done

# Sessions that may own a case: every row that is not dropped.
declare -A live=()
sh=$(table_header <(master_src "$plan") '## Sessions' || true)
if [ -n "$sh" ]; then
    s_id=$(col_index "$sh" id); s_st=$(col_index "$sh" status)
    while IFS= read -r row; do
        id=$(cell "$row" "$s_id"); [ -n "$id" ] || continue
        [ "$(cell "$row" "$s_st")" = dropped ] || live[$id]=1
    done < <(table_rows <(master_src "$plan") '## Sessions')
fi

open_text=$(awk '$0 == "## Open & deferred" { s = 1; next } s && /^## / { exit } s' <(master_src "$plan"))
declare -A seen=()
total=0 owned=0 rows=0 bad=0 lines=""
while IFS= read -r row; do
    id=$(cell "$row" "$g_id"); [ -n "$id" ] || continue
    rows=$((rows + 1))
    what=$(cell "$row" "$g_case"); n=$(cell "$row" "$g_n"); own=$(cell "$row" "$g_own")
    st=""; [ -n "$g_st" ] && st=$(cell "$row" "$g_st")
    if [ -n "${seen[$id]+x}" ]; then lines+="bad $id: the id appears twice"$'\n'; bad=1; continue; fi
    seen[$id]=1
    case "$st" in todo|pass) ;; *) lines+="bad $id: status '$st' is not todo or pass"$'\n'; bad=1 ;; esac
    if ! [[ $n =~ ^[1-9][0-9]{0,8}$ ]]; then
        lines+="bad $id: count '$n' is not a positive whole number"$'\n'; bad=1; continue
    fi
    total=$((total + n))
    if [ -z "$own" ]; then
        lines+="unowned $id: $what ($n)"$'\n'; bad=1
    elif [ "$own" = operator ] && ! grep -qw -- "$id" <<<"$open_text"; then
        lines+="bad $id: owned by operator, and ## Open & deferred does not name $id"$'\n'; bad=1
    elif [ "$own" = operator ] || [ -n "${live[$own]+x}" ]; then
        owned=$((owned + n))
    else
        lines+="bad $id: owner '$own' is no live row of ## Sessions"$'\n'; bad=1
    fi
done < <(table_rows <(master_src "$plan") '## Goal cases')

[ "$rows" -gt 0 ] || trace_die "## Goal cases has no rows"
printf 'owned %d/%d\n' "$owned" "$total"
printf '%s' "$lines"
[ "$bad" -eq 0 ] && exit 0
exit 1
