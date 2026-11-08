#!/usr/bin/env bash
# pm-plan.sh — validate a /v-pm feature plan and read or write its Sessions rows.
#
# Usage:  bin/pm-plan.sh check <plan>
#         bin/pm-plan.sh order <plan>
#         bin/pm-plan.sh set   <plan> <id> <column>=<value>...
#         bin/pm-plan.sh gap   <plan> <case id>...
#
# check  refuses a plan that is not normalized: a Sessions row without exactly one brief, a brief whose
#        `## Next command` run line names another repo, command, plan or id than its row, an empty
#        success-criteria table, a criterion no session reaches, a missing default done line, a
#        contract whose consumer does not list its producer in `depends`, or a `depends` cycle. It then
#        runs `bin/gate.sh master` and `bin/gate.sh goal`. Success prints `pm: ok <plan>`.
# order  prints one tab-separated line per session: wave, id, status, readiness, repo, brief. Readiness
#        is `runnable` (todo, every dependency done), `waits:<ids>`, `blocked:<ids>` (a dependency was
#        dropped), `running` (doing), `done` or `dropped`. Sessions of one wave may run in parallel.
# set    rewrites cells of one Sessions row under an exclusive lock, so two sessions closing at once
#        both land.
# gap    appends the gap sessions of one round for failing goal cases; the row shape and the cap are
#        templates/master-plan.md `## Goal fit` (Gap loop). Refuses an unknown case id and an `operator`
#        case. `order` and `gap` read a table without `repo`; `check` does not.
#
# Contract: templates/feature-plan.md (the plan), templates/handoff.md (the brief),
# templates/master-plan.md (the Sessions and contracts columns).
#
# Exit: 0 clean · 1 refused, or no such row or column · 2 unreadable plan or bad usage

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=gate.sh
. "$ROOT/bin/gate.sh"

pm_refuse() { printf 'REFUSED pm %s: %s%s\n' "$PLAN" "$1" "${2:+ [$2]}" >&2; violations=$((violations + 1)); }
expand() { case "$1" in "~"/*) printf '%s' "${HOME}/${1#\~/}" ;; *) printf '%s' "$1" ;; esac; }
realp() { realpath -m -- "$(expand "$1")"; }

# Load the Sessions table into arrays keyed by id, in table order.
declare -a IDS=()
declare -A REPO=() CMD=() STATUS=() DEPS=()
# load_sessions [<required column>...]: default id repo command status depends.
load_sessions() {
    local header row id req=("$@")
    [ ${#req[@]} -gt 0 ] || req=(id repo command status depends)
    header=$(table_header "$PLAN" '## Sessions' || true)
    [ -n "$header" ] || { pm_refuse "the plan has no ## Sessions table"; return 1; }
    local c_id c_repo c_cmd c_st c_dep
    c_id=$(col_index "$header" id); c_repo=$(col_index "$header" repo)
    c_cmd=$(col_index "$header" command); c_st=$(col_index "$header" status)
    c_dep=$(col_index "$header" depends)
    local name missing=0
    for name in "${req[@]}"; do
        [ -n "$(col_index "$header" "$name")" ] || { pm_refuse "the ## Sessions table has no $name column" "$name"; missing=1; }
    done
    [ "$missing" -eq 0 ] || return 1
    while IFS= read -r row; do
        id=$(cell "$row" "$c_id"); [ -n "$id" ] || continue
        if [ -n "${STATUS[$id]+x}" ]; then pm_refuse "session id $id appears twice" "$id"; continue; fi
        IDS+=("$id")
        REPO[$id]=-; [ -z "$c_repo" ] || REPO[$id]=$(cell "$row" "$c_repo")
        CMD[$id]=$(cell "$row" "$c_cmd")
        STATUS[$id]=$(cell "$row" "$c_st"); DEPS[$id]=$(cell "$row" "$c_dep" | tr ',;' '  ')
    done < <(table_rows "$PLAN" '## Sessions')
}

# Compute WAVE[id]; refuse a dependency on a missing id and a cycle.
declare -A WAVE=()
waves() {
    local id d changed pass=0 w max
    for id in "${IDS[@]}"; do
        for d in ${DEPS[$id]}; do
            [ -n "${STATUS[$d]+x}" ] || { pm_refuse "$id depends on $d, and the Sessions table has no $d" "$id"; return 1; }
        done
    done
    while :; do
        changed=0; pass=$((pass + 1))
        for id in "${IDS[@]}"; do
            [ -z "${WAVE[$id]+x}" ] || continue
            max=0
            for d in ${DEPS[$id]}; do
                [ -n "${WAVE[$d]+x}" ] || continue 2
                [ "${WAVE[$d]}" -gt "$max" ] && max=${WAVE[$d]}
            done
            WAVE[$id]=$((max + 1)); changed=1
        done
        [ "$changed" -eq 1 ] || break
    done
    for id in "${IDS[@]}"; do
        [ -n "${WAVE[$id]+x}" ] || { pm_refuse "$id sits on a depends cycle" "$id"; return 1; }
    done
}

brief_of() { compgen -G "$(dirname "$PLAN")/briefs/$1-*.md" || true; }

readiness() {
    local id=$1 d waits="" blocked=""
    case "${STATUS[$id]}" in doing) echo running; return ;; done) echo done; return ;; dropped) echo dropped; return ;; esac
    for d in ${DEPS[$id]}; do
        case "${STATUS[$d]}" in done) ;; dropped) blocked+="${blocked:+,}$d" ;; *) waits+="${waits:+,}$d" ;; esac
    done
    if [ -n "$blocked" ]; then echo "blocked:$blocked"; elif [ -n "$waits" ]; then echo "waits:$waits"; else echo runnable; fi
}

check_brief() {
    local id=$1 briefs n brief line fm_id fm_plan
    briefs=$(brief_of "$id"); n=$(grep -c . <<<"$briefs" || true)
    if [ "$n" -eq 0 ]; then pm_refuse "$id has no brief under briefs/$id-<slug>.md" "$id"; return; fi
    if [ "$n" -gt 1 ]; then pm_refuse "$id has $n briefs; keep one" "$id"; return; fi
    brief=$briefs
    fm_id=$(frontmatter_get "$brief" id); fm_plan=$(frontmatter_get "$brief" plan)
    [ "$fm_id" = "$id" ] || pm_refuse "$(basename "$brief") names id '$fm_id', its row is $id" "$id"
    [ "$(realp "$fm_plan")" = "$PLAN_ABS" ] || pm_refuse "$(basename "$brief") names plan '$fm_plan', not this plan" "$id"
    line=$(awk '/^## Next command/{s=1;next} /^## /{s=0} s && /^cd /{print; exit}' "$brief")
    if [ -z "$line" ]; then pm_refuse "$(basename "$brief") has no run line starting with cd under ## Next command" "$id"; return; fi
    local re='^cd ([^ ]+) && claude --add-dir ([^ ]+) "(/v-[a-z-]+) ([^"#]+)#([^"]+)"$'
    if ! [[ $line =~ $re ]]; then
        pm_refuse "$(basename "$brief") run line is not: cd <repo> && claude --add-dir <plan folder> \"<command> <plan>#<id>\"" "$id"; return
    fi
    [ "$(realp "${BASH_REMATCH[1]}")" = "$(realp "${REPO[$id]}")" ] || pm_refuse "$id run line runs in ${BASH_REMATCH[1]}, its row names ${REPO[$id]}" "$id"
    [ "$(realp "${BASH_REMATCH[2]}")" = "$(dirname "$PLAN_ABS")" ] || pm_refuse "$id run line adds ${BASH_REMATCH[2]}, not the plan folder" "$id"
    [ "${BASH_REMATCH[3]}" = "${CMD[$id]}" ] || pm_refuse "$id run line runs ${BASH_REMATCH[3]}, its row names ${CMD[$id]}" "$id"
    [ "$(realp "${BASH_REMATCH[4]}")" = "$PLAN_ABS" ] || pm_refuse "$id run line names plan ${BASH_REMATCH[4]}, not this plan" "$id"
    [ "${BASH_REMATCH[5]}" = "$id" ] || pm_refuse "$id run line names session ${BASH_REMATCH[5]}" "$id"
}

cmd_check() {
    load_sessions || return 0
    [ "${#IDS[@]}" -gt 0 ] || pm_refuse "the ## Sessions table has no rows"
    local id
    for id in "${IDS[@]}"; do
        case "${STATUS[$id]}" in todo|doing|done|dropped) ;; *) pm_refuse "$id has status '${STATUS[$id]}'; use todo, doing, done or dropped" "$id" ;; esac
        case "${CMD[$id]}" in /v-do|/v-work|/v-team) ;; *) pm_refuse "$id has command '${CMD[$id]}'; use /v-do, /v-work or /v-team" "$id" ;; esac
        case "$(expand "${REPO[$id]}")" in /*) ;; *) pm_refuse "$id repo '${REPO[$id]}' is not an absolute path" "$id" ;; esac
        check_brief "$id"
    done
    waves || true

    # Success criteria: at least one, each reached by a session that exists.
    local header row c_id c_s sc s n=0
    header=$(table_header "$PLAN" '## Success criteria' || true)
    c_id=$(col_index "$header" id); c_s=$(col_index "$header" sessions)
    if [ -z "$c_id" ] || [ -z "$c_s" ]; then
        pm_refuse "## Success criteria needs a table with id and sessions columns; /v-pm does not plan without one"
    else
        while IFS= read -r row; do
            sc=$(cell "$row" "$c_id"); [ -n "$sc" ] || continue; n=$((n + 1))
            s=$(cell "$row" "$c_s" | tr ',;' '  ')
            [ -n "${s// /}" ] || pm_refuse "$sc names no session that reaches it" "$sc"
            for id in $s; do [ -n "${STATUS[$id]+x}" ] || pm_refuse "$sc names session $id, and the Sessions table has no $id" "$sc"; done
        done < <(table_rows "$PLAN" '## Success criteria')
        [ "$n" -gt 0 ] || pm_refuse "## Success criteria is empty; /v-pm does not plan without an operator criterion"
    fi

    # Definition of done: the four default lines are present. States may be blank until close.
    local dd
    for dd in DD-1 DD-2 DD-3 DD-4; do
        table_rows "$PLAN" '## Definition of done' | awk -F "$US" -v d="$dd" '$1 == d {f=1} END {exit !f}' \
            || pm_refuse "## Definition of done lacks default line $dd" "$dd"
    done

    # Every contract pair is also a depends pair, so order and gate.sh master agree.
    local ch cp cu p u
    ch=$(table_header "$PLAN" '## Cross-session contracts' || true)
    if [ -n "$ch" ]; then
        cp=$(col_index "$ch" 'produced by'); cu=$(col_index "$ch" 'consumed by'); c_id=$(col_index "$ch" id)
        while IFS= read -r row; do
            [ -n "$(cell "$row" "$c_id")" ] || continue
            for p in $(cell "$row" "$cp" | tr ',;' '  '); do for u in $(cell "$row" "$cu" | tr ',;' '  '); do
                [ "$p" = "$u" ] && continue
                [ -n "${STATUS[$u]+x}" ] || continue
                [[ " ${DEPS[$u]} " == *" $p "* ]] || pm_refuse "$(cell "$row" "$c_id") is produced by $p and consumed by $u, and $u does not list $p in depends" "$u"
            done; done
        done < <(table_rows "$PLAN" '## Cross-session contracts')
    fi

    local sub
    for sub in master goal; do
        local rc=0 any=0
        "$ROOT/bin/gate.sh" "$sub" "$PLAN" >/dev/null 2>"$TMPERR" || rc=$?
        [ "$rc" -eq 0 ] && continue
        while IFS= read -r line; do
            case "$line" in "REFUSED $sub "*) any=1; line=${line#"REFUSED $sub "}; pm_refuse "gate.sh $sub: ${line#*: }" ;; esac
        done <"$TMPERR"
        [ "$any" -eq 1 ] || pm_refuse "gate.sh $sub exited $rc and named no refusal: $(head -n 3 "$TMPERR" | tr '\n' ' ')"
    done
    [ "$violations" -gt 0 ] || printf 'pm: ok %s\n' "$PLAN"
}

cmd_order() {
    load_sessions id command status depends || return 0
    waves || return 0
    local id brief
    for id in "${IDS[@]}"; do
        brief=$(brief_of "$id" | head -1)
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${WAVE[$id]}" "$id" "${STATUS[$id]}" "$(readiness "$id")" "${REPO[$id]}" "${brief:--}"
    done | sort -s -n -k1,1
}

cmd_set() {
    local id=${1:-}; shift || true
    [ -n "$id" ] && [ $# -gt 0 ] || die "set needs <plan> <id> <column>=<value>..."
    local header assign col
    for assign in "$@"; do
        col=${assign%%=*}
        [ "$col" != "$assign" ] || die "set takes <column>=<value>, got '$assign'"
        [ "$col" != id ] || die "set cannot change a row's id"
    done
    exec 9<"$PLAN"; flock 9
    header=$(table_header "$PLAN" '## Sessions' || true)
    [ -n "$header" ] || { pm_refuse "the plan has no ## Sessions table"; return 0; }
    for assign in "$@"; do
        col=${assign%%=*}
        [ -n "$(col_index "$header" "$col")" ] || { pm_refuse "the ## Sessions table has no $col column" "$col"; return 0; }
    done
    table_set "$PLAN" '## Sessions' id "$id" "$@" || { pm_refuse "the ## Sessions table has no row $id" "$id"; return 0; }
    printf 'pm: set %s %s\n' "$id" "$*"
}

# cmd_gap <case id>...: the gap rows of one round; the rules are in the header above.
cmd_gap() {
    [ $# -gt 0 ] || die "gap needs <plan> <case id>..."
    [ "$(arch_fm_value "$PLAN" goal_fit)" = required ] || { pm_refuse "the plan has no goal_fit: required, so it has no gap loop"; return 0; }
    exec 9<"$PLAN"; flock 9
    load_sessions id command status depends || return 0
    local rounds gh g_id g_own row cid own r n=0 id new
    rounds=$(arch_fm_value "$PLAN" gap_rounds); rounds=${rounds:-0}
    [[ $rounds =~ ^[0-9]+$ ]] || { pm_refuse "gap_rounds '$rounds' is not a whole number" gap_rounds; return 0; }
    [ "$rounds" -lt 3 ] || { pm_refuse "gap_rounds is $rounds; the loop stops at 3, so show the operator the failing cases" gap_rounds; return 0; }
    gh=$(table_header "$PLAN" '## Goal cases' || true)
    g_id=$(col_index "$gh" id); g_own=$(col_index "$gh" owner)
    [ -n "$g_id" ] && [ -n "$g_own" ] || { pm_refuse "## Goal cases needs id and owner columns"; return 0; }
    declare -A owner=() group=() seen=()
    while IFS= read -r row; do cid=$(cell "$row" "$g_id"); [ -n "$cid" ] && owner[$cid]=$(cell "$row" "$g_own"); done < <(table_rows "$PLAN" '## Goal cases')
    local -a order=()
    for cid in "$@"; do
        [ -z "${seen[$cid]+x}" ] || continue; seen[$cid]=1
        if [ -z "${owner[$cid]+x}" ]; then pm_refuse "## Goal cases has no row $cid" "$cid"; continue; fi
        own=${owner[$cid]}
        if [ -z "$own" ]; then pm_refuse "$cid has no owner; give it one in ## Goal cases before a gap round" "$cid"; continue; fi
        if [ "$own" = operator ]; then pm_refuse "$cid is the operator's case; list it to the operator instead of a gap session" "$cid"; continue; fi
        r=${REPO[$own]:--}
        [ -n "${group[$r]+x}" ] || order+=("$r")
        group[$r]+="${group[$r]:+, }$cid"
    done
    [ "$violations" -eq 0 ] || return 0
    for id in "${IDS[@]}"; do [[ $id =~ ^S([0-9]+)$ ]] && [ "$((10#${BASH_REMATCH[1]}))" -gt "$n" ] && n=$((10#${BASH_REMATCH[1]})); done
    rounds=$((rounds + 1))
    local hdr cmdcol; hdr=$(table_header "$PLAN" '## Sessions')
    for r in "${order[@]}"; do
        n=$((n + 1)); new="S$n"
        cid=${group[$r]%%,*}; cmdcol=${CMD[${owner[$cid]}]:-/v-team}
        local -a cells=("id=$new" "scope=gap round $rounds: ${group[$r]}; split: gap round" "command=$cmdcol" "status=todo")
        [ "$r" = - ] || [ -z "$(col_index "$hdr" repo)" ] || cells+=("repo=$r")
        table_append "$PLAN" '## Sessions' "${cells[@]}" || { pm_refuse "could not append a row to ## Sessions"; return 0; }
        for cid in ${group[$r]//,/ }; do
            table_set "$PLAN" '## Goal cases' id "$cid" "owner=$new" status=todo || pm_refuse "could not re-own $cid" "$cid"
        done
        printf 'pm: gap round %s: %s owns %s\n' "$rounds" "$new" "${group[$r]}"
    done
    frontmatter_put "$PLAN" gap_rounds "$rounds" || pm_refuse "could not write gap_rounds; the plan has no frontmatter"
}

sub=${1:-}; PLAN=${2:-}
case "$sub" in
    -h|--help|"") sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; [ -n "$sub" ]; exit $? ;;
esac
[ -n "$PLAN" ] || die "$sub needs a plan"
{ [ -f "$PLAN" ] && [ -r "$PLAN" ]; } || die "cannot read: $PLAN"
PLAN_ABS=$(realp "$PLAN")
TMPERR=$(mktemp); trap 'rm -f "$TMPERR"' EXIT
shift 2
case "$sub" in
    check) [ $# -eq 0 ] || die "check takes one plan"; cmd_check ;;
    order) [ $# -eq 0 ] || die "order takes one plan"; cmd_order ;;
    set|gap)
        if grep -q $'\r' "$PLAN"; then pm_refuse "the plan has CRLF line endings, which set and gap cannot edit; convert it with sed -i 's/\\r\$//' $PLAN"
        elif [ "$sub" = set ]; then cmd_set "$@"; else cmd_gap "$@"; fi ;;
    *) die "unknown subcommand: $sub" ;;
esac
if [ "$violations" -gt 0 ]; then
    [ "$sub" != check ] || printf 'pm: %d refusal(s)\n' "$violations" >&2
    exit 1
fi
exit 0
