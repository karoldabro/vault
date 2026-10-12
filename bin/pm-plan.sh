#!/usr/bin/env bash
# pm-plan.sh — validate a /v-pm feature plan and read or write its Sessions rows.
#
# Usage:  bin/pm-plan.sh check <plan>
#         bin/pm-plan.sh order <plan>
#         bin/pm-plan.sh set   <plan> <id> <column>=<value>...
#
# check  refuses a plan that is not normalized: a Sessions row without exactly one brief, a brief whose
#        `## Next command` run line names another repo, command, plan or id than its row, an empty
#        success-criteria table, a criterion no session reaches, a missing default done line, a
#        contract whose consumer does not list its producer in `depends`, or a `depends` cycle. It then
#        runs `bin/gate.sh master`. Success prints `pm: ok <plan>`.
# order  prints one tab-separated line per session: wave, id, status, readiness, repo, brief. Readiness
#        is `runnable` (todo, every dependency done), `waits:<ids>`, `blocked:<ids>` (a dependency was
#        dropped), `running` (doing), `done` or `dropped`. Sessions of one wave may run in parallel.
# set    rewrites cells of one Sessions row under an exclusive lock, so two sessions closing at once
#        both land.
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
load_sessions() {
    local header row id
    header=$(table_header "$PLAN" '## Sessions' || true)
    [ -n "$header" ] || { pm_refuse "the plan has no ## Sessions table"; return 1; }
    local c_id c_repo c_cmd c_st c_dep
    c_id=$(col_index "$header" id); c_repo=$(col_index "$header" repo)
    c_cmd=$(col_index "$header" command); c_st=$(col_index "$header" status)
    c_dep=$(col_index "$header" depends)
    local name missing=0
    for name in id repo command status depends; do
        [ -n "$(col_index "$header" "$name")" ] || { pm_refuse "the ## Sessions table has no $name column" "$name"; missing=1; }
    done
    [ "$missing" -eq 0 ] || return 1
    while IFS= read -r row; do
        id=$(cell "$row" "$c_id"); [ -n "$id" ] || continue
        if [ -n "${STATUS[$id]+x}" ]; then pm_refuse "session id $id appears twice" "$id"; continue; fi
        IDS+=("$id")
        REPO[$id]=$(cell "$row" "$c_repo"); CMD[$id]=$(cell "$row" "$c_cmd")
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

    if ! "$ROOT/bin/gate.sh" master "$PLAN" >/dev/null 2>"$TMPERR"; then
        while IFS= read -r line; do case "$line" in REFUSED*) pm_refuse "gate.sh master: ${line#REFUSED master * }" ;; esac; done <"$TMPERR"
    fi
    [ "$violations" -gt 0 ] || printf 'pm: ok %s\n' "$PLAN"
}

cmd_order() {
    load_sessions || return 0
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
    exec 9<"$PLAN"; flock 9
    local header assign col val idx args=()
    header=$(table_header "$PLAN" '## Sessions' || true)
    [ -n "$header" ] || { pm_refuse "the plan has no ## Sessions table"; return 0; }
    for assign in "$@"; do
        col=${assign%%=*}; val=${assign#*=}
        [ "$col" != "$assign" ] || die "set takes <column>=<value>, got '$assign'"
        idx=$(col_index "$header" "$col"); [ -n "$idx" ] || { pm_refuse "the ## Sessions table has no $col column" "$col"; return 0; }
        [ "$col" != id ] || die "set cannot change a row's id"
        args+=("$idx=${val//|/\\|}")
    done
    local tmp; tmp=$(mktemp)
    PM_SPECS="$(printf '%s\n' "${args[@]}")" awk -v want="$id" '
        function unprotect(s,   out, i) { out = ""; while ((i = index(s, "\001")) > 0) { out = out substr(s, 1, i - 1) "\\|"; s = substr(s, i + 1) } return out s }
        BEGIN { specs = ENVIRON["PM_SPECS"]; n = split(specs, sp, "\n"); for (i = 1; i <= n; i++) { k = sp[i]; sub(/=.*/, "", k); v = sp[i]; sub(/^[^=]*=/, "", v); set[k + 0] = v } }
        $0 == "## Sessions" { s = 1; print; next }
        s && /^## / { s = 0 }
        s && /^\|/ && !/^\|[- |:]*\|$/ {
            line = $0; gsub(/\\\|/, "\001", line)
            m = split(line, c, "|"); id = c[2]; gsub(/^[ \t]+|[ \t]+$/, "", id)
            if (id == want) {
                out = ""
                for (i = 2; i < m; i++) { v = (i - 1) in set ? " " set[i - 1] " " : unprotect(c[i]); out = out "|" v }
                print out "|"; hit = 1; next
            }
        }
        { print }
        END { exit !hit }' "$PLAN" >"$tmp" || { rm -f "$tmp"; pm_refuse "the ## Sessions table has no row $id" "$id"; return 0; }
    cat "$tmp" >"$PLAN"; rm -f "$tmp"
    printf 'pm: set %s %s\n' "$id" "$*"
}

sub=${1:-}; PLAN=${2:-}
case "$sub" in
    -h|--help|"") sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; [ -n "$sub" ]; exit $? ;;
esac
[ -n "$PLAN" ] || die "$sub needs a plan"
{ [ -f "$PLAN" ] && [ -r "$PLAN" ]; } || die "cannot read: $PLAN"
PLAN_ABS=$(realp "$PLAN")
TMPERR=$(mktemp); trap 'rm -f "$TMPERR"' EXIT
shift 2
case "$sub" in
    check) [ $# -eq 0 ] || die "check takes one plan"; cmd_check ;;
    order) [ $# -eq 0 ] || die "order takes one plan"; cmd_order ;;
    set)   cmd_set "$@" ;;
    *) die "unknown subcommand: $sub" ;;
esac
if [ "$violations" -gt 0 ]; then
    [ "$sub" != check ] || printf 'pm: %d refusal(s)\n' "$violations" >&2
    exit 1
fi
exit 0
