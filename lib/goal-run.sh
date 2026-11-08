#!/usr/bin/env bash
# goal-run.sh — the goal runs behind `gate.sh goal baseline|close|last|failing`. Sourced by gate.sh
# after lib/goal-check.sh, never run on its own.
#
# Contract: templates/master-plan.md owns the `## Goal fit` rows, the `## Goal cases` columns, the gap
# row shape and `gap_rounds`. This file implements the runs and states none of those rules again.
#
# It uses these from gate.sh and the libraries it sources: US, violations, note, die, table_rows,
# table_header, col_index, cell, table_set, table_append, checks_root, arch_fm_value, master_src,
# master_resolve, master_is_table, goal_refuse, goal_field, goal_minutes, cmd_goal.

# goal_master <plan>: print the opted-in master plan, or return 1 after one note.
goal_master() {
    local plan=$1 file=$1 so
    { [ -f "$plan" ] && [ -r "$plan" ]; } || die "cannot read: $plan"
    so=$(arch_fm_value <(master_src "$plan") session_of)
    if [ -n "$so" ]; then
        file=$(master_resolve "$plan" "$so") || die "session_of of $plan names no readable master: $so"
    fi
    master_is_table "$(table_header <(master_src "$file") '## Sessions' || true)" || { note "$file is no master plan, so no goal runs"; return 1; }
    [ "$(arch_fm_value <(master_src "$file") goal_fit)" = required ] || { note "$file has no goal_fit: required, so no goal runs"; return 1; }
    printf '%s\n' "$file"
}

# goal_lf <master>: refuse a master with CRLF line endings, which the writers cannot edit; returns 1 then.
goal_lf() {
    ! grep -q $'\r' "$1" && return 0
    goal_refuse "$1" "the plan has CRLF line endings, which the goal writers cannot edit; convert it with sed -i 's/\\r\$//' $1" CRLF
    return 1
}

# goal_script <master>: set GOAL_SCRIPT to the `goal script` path, relative to the checks root; refuse
# and return 1 when it names no committed executable. Never call it in a subshell: the refusal count
# would be lost.
goal_script() {
    goal_script_ok "$1" && return 0
    goal_refuse "$1" "the goal script '$(goal_field "$1" 'goal script' value)' is no executable file under $(checks_root "$1"); write it and name it in the goal script row" 'goal script'
    return 1
}

# goal_script_ok <master>: like goal_script, without the refusal.
goal_script_ok() {
    local v; v=$(goal_field "$1" 'goal script' value); v=${v//\`/}
    [ -n "$v" ] && [ -x "$(checks_root "$1")/$v" ] && [ ! -d "$(checks_root "$1")/$v" ] || return 1
    GOAL_SCRIPT=$v
}

# goal_exec <master> <script> <log>: run the goal script under the runtime limit; sets GOAL_RC.
goal_exec() {
    local m=$1 script=$2 log=$3 min
    min=$(goal_minutes "$(goal_field "$m" 'runtime limit' value)") || min=""
    set +e
    if [ -n "$min" ] && command -v timeout >/dev/null 2>&1; then
        (exec 8>&- 9<&-; cd "$(checks_root "$m")" && timeout -k 10 "${min}m" "./$script") >"$log" 2>&1
    else
        [ -n "$min" ] || note "runtime limit is unreadable, so the goal runs without a time limit"
        (exec 8>&- 9<&-; cd "$(checks_root "$m")" && "./$script") >"$log" 2>&1
    fi
    GOAL_RC=$?
    set -e
}

# goal_log <master>: the machine-local path of the master's last-run log.
goal_log() {
    local m d
    m=$(realpath -m -- "$1"); d=$(basename "$(dirname "$m")")
    printf '%s/vault/goal-run/%s-%s-%s.log\n' "${XDG_STATE_HOME:-$HOME/.local/state}" "$d" "$(basename "$m" .md)" "$(printf '%s' "$m" | cksum | cut -c1-8 | tr -d ' ')"
}

# goal_put_row <master> <field> <value> <evidence>: write one `## Goal fit` row, adding it when absent.
goal_put_row() {
    table_set "$1" '## Goal fit' field "$2" "value=$3" "evidence=$4" ||
        table_append "$1" '## Goal fit' "field=$2" "value=$3" "evidence=$4" ||
        goal_refuse "$1" "could not write the $2 row of ## Goal fit" "$2"
}

cmd_goal_baseline() {
    [ $# -eq 1 ] || die "goal baseline takes one plan"
    local m script tmp day
    m=$(goal_master "$1") || { [ $? -ne 2 ] || exit 2; return 0; }
    goal_lf "$m" || return 0
    local before=$violations
    if [ -n "$(goal_field "$m" baseline value)" ]; then note "the baseline of $m is already recorded"; return 0; fi
    if ! goal_script_ok "$m"; then
        note "the goal script is not written yet; no baseline is written, and the next pickup runs it again"; return 0
    fi
    script=$GOAL_SCRIPT
    tmp=$(mktemp); goal_exec "$m" "$script" "$tmp"; rm -f "$tmp"
    day=$(date +%F)
    case "$GOAL_RC" in
        0) goal_refuse "$m" "the goal script passes before the open sessions' work exists, so it cannot tell whether they reach the goal; make $script test the goal cases" baseline; return 0 ;;
        2) note "the goal script exited 2 (cannot run); no baseline is written, and the next pickup runs it again"; return 0 ;;
    esac
    exec 9<"$m"; flock 9
    [ -n "$(goal_field "$m" baseline value)" ] || goal_put_row "$m" baseline "$day exit $GOAL_RC" "\`$script\`"
    exec 9<&-
    [ "$violations" -ne "$before" ] || printf 'goal: baseline %s exit %s %s\n' "$day" "$GOAL_RC" "$m"
}

# goal_sessions <file>: print `<id><US><status>` per `## Sessions` row, read like bin/pm-plan.sh does.
goal_sessions() {
    local h i_id i_st row
    h=$(table_header <(master_src "$1") '## Sessions' || true)
    i_id=$(col_index "$h" id); i_st=$(col_index "$h" status)
    [ -n "$i_id" ] && [ -n "$i_st" ] || { goal_refuse "$1" "## Sessions needs id and status columns" Sessions; return 0; }
    while IFS= read -r row; do
        printf '%s%s%s\n' "$(cell "$row" "$i_id")" "$US" "$(cell "$row" "$i_st")"
    done < <(table_rows <(master_src "$1") '## Sessions')
}

# goal_statuses <file>: print `<id><US><owner><US><status>` per `## Goal cases` row.
goal_statuses() {
    local h i_id i_own i_st row
    h=$(table_header <(master_src "$1") '## Goal cases' || true)
    i_id=$(col_index "$h" id); i_own=$(col_index "$h" owner); i_st=$(col_index "$h" status)
    [ -n "$i_id" ] && [ -n "$i_own" ] && [ -n "$i_st" ] || { goal_refuse "$1" "## Goal cases needs id, owner and status columns" 'Goal cases'; return 0; }
    while IFS= read -r row; do
        printf '%s%s%s%s%s\n' "$(cell "$row" "$i_id")" "$US" "$(cell "$row" "$i_own")" "$US" "$(cell "$row" "$i_st")"
    done < <(table_rows <(master_src "$1") '## Goal cases')
}

cmd_goal_close() {
    [ $# -ge 2 ] || die "goal close takes <plan> <session> [<case id>...]"
    local m session=$2 before=$violations id own st dir name old o_st cur sh so ledger
    m=$(goal_master "$1") || { [ $? -ne 2 ] || exit 2; return 0; }
    goal_lf "$m" || return 0
    so=$(arch_fm_value <(master_src "$1") session_of)
    [ -z "$so" ] || [ "${so##*#}" = "$session" ] || { goal_refuse "$m" "$1 is session ${so##*#}, so it may not close $session" "$session"; return 0; }
    ledger="$(goal_log "$m")"; ledger="${ledger%.log}.flips"; mkdir -p "$(dirname "$ledger")"
    shift 2
    sh=$(goal_sessions "$m" | awk -F "$US" -v s="$session" '$1 == s {f=1} END {exit !f}' && echo y || true)
    [ -n "$sh" ] || { goal_refuse "$m" "## Sessions has no row $session" "$session"; return 0; }
    exec 9<"$m"; flock 9
    declare -A owner=() status=() was=()
    while IFS="$US" read -r id own st; do if [ -n "$id" ]; then owner[$id]=$own; status[$id]=$st; fi; done < <(goal_statuses "$m")
    for id in "$@"; do
        if [ -z "${owner[$id]+x}" ]; then goal_refuse "$m" "## Goal cases has no row $id" "$id"
        elif [ "${owner[$id]}" != "$session" ]; then goal_refuse "$m" "$id is owned by ${owner[$id]:-nobody}, so $session may not mark it pass" "$id"; fi
    done
    dir=$(dirname "$m"); name=$(basename "$m")
    old=$(mktemp)
    if git -C "$dir" show "HEAD:./$name" >"$old" 2>/dev/null; then
        while IFS="$US" read -r id own o_st; do if [ -n "$id" ]; then was[$id]=$o_st; fi; done < <(goal_statuses "$old")
        for id in "${!status[@]}"; do
            cur=${status[$id]}
            if [ "$cur" = pass ] && [ "${was[$id]:-todo}" = todo ] && [ "${owner[$id]}" != "$session" ] &&
                ! grep -qxF -- "$id ${owner[$id]}" "$ledger" 2>/dev/null; then
                goal_refuse "$m" "$id reads pass, the committed copy reads todo, and ${owner[$id]:-nobody} owns it; only its owner's close marks it pass" "$id"
            fi
        done
    else
        note "$m has no committed copy, so hand edits to goal-case status cannot be checked"
    fi
    rm -f "$old"
    if [ "$violations" -eq "$before" ]; then
        cmd_goal "$m" >/dev/null
    fi
    if [ "$violations" -eq "$before" ]; then
        for id in "$@"; do
            if table_set "$m" '## Goal cases' id "$id" status=pass; then printf '%s %s\n' "$id" "$session" >>"$ledger"
            else goal_refuse "$m" "could not write $id" "$id"; fi
        done
    fi
    exec 9<&-
    if [ "$violations" -eq "$before" ]; then printf 'goal: close %s %s%s\n' "$session" "$m" "${1:+ pass: $*}"; fi
    return 0
}

cmd_goal_last() {
    [ $# -eq 1 ] || die "goal last takes one plan"
    local m script open log day val word
    m=$(goal_master "$1") || { [ $? -ne 2 ] || exit 2; return 0; }
    goal_lf "$m" || return 0
    local before=$violations
    open=$(goal_sessions "$m" | awk -F "$US" '$1 != "" && $2 != "done" && $2 != "dropped" { printf "%s ", $1 }')
    goal_sessions "$m" >/dev/null; [ "$violations" -eq "$before" ] || return 0
    if [ -n "$open" ]; then printf 'goal: last run waits; open rows: %s\n' "${open% }"; return 0; fi
    goal_script "$m" || return 0; script=$GOAL_SCRIPT
    log=$(goal_log "$m"); mkdir -p "$(dirname "$log")"
    exec 8>"${log%.log}.lock"
    if ! flock -n 8; then printf 'goal: last run already running %s\n' "$m"; return 0; fi
    goal_exec "$m" "$script" "$log"
    day=$(date +%F)
    case "$GOAL_RC" in 0) val="$day exit 0"; word=passed ;; 2) val="$day not run"; word="not run" ;; *) val="$day exit $GOAL_RC"; word=failed ;; esac
    exec 9<"$m"; flock 9
    goal_put_row "$m" 'last run' "$val" "\`$log\`"
    exec 9<&- 8>&-
    [ "$violations" -ne "$before" ] || printf 'goal: last run %s %s (exit %s, log %s)\n' "$word" "$m" "$GOAL_RC" "$log"
}

# The passing-group rule: templates/master-plan.md `## Goal cases`, the `case` column.
cmd_goal_failing() {
    [ $# -eq 1 ] || die "goal failing takes one plan"
    local m log h i_id i_case i_n i_own row id what n own nf np any=0
    m=$(goal_master "$1") || { [ $? -ne 2 ] || exit 2; return 0; }
    log=$(goal_log "$m")
    [ -r "$log" ] || { goal_refuse "$m" "no saved goal log at $log; run gate.sh goal last $m first" 'last run'; return 0; }
    h=$(table_header <(master_src "$m") '## Goal cases' || true)
    i_id=$(col_index "$h" id); i_case=$(col_index "$h" case); i_n=$(col_index "$h" count); i_own=$(col_index "$h" owner)
    [ -n "$i_id" ] && [ -n "$i_case" ] && [ -n "$i_n" ] && [ -n "$i_own" ] || { goal_refuse "$m" "## Goal cases needs id, case, count and owner columns" 'Goal cases'; return 0; }
    while IFS= read -r row; do
        id=$(cell "$row" "$i_id"); [ -n "$id" ] || continue
        what=$(cell "$row" "$i_case"); n=$(cell "$row" "$i_n"); own=$(cell "$row" "$i_own")
        nf=$(grep -iF -- "$what" "$log" | grep -icE '(^|[^[:alnum:]])(fail|failed|error|not ok)([^[:alnum:]]|$)' || true)
        np=$(grep -iF -- "$what" "$log" | grep -viE '(^|[^[:alnum:]])(fail|failed|error|not ok)([^[:alnum:]]|$)' | grep -icE '(^|[^[:alnum:]])(pass|passed|ok)([^[:alnum:]]|$)' || true)
        [[ $n =~ ^[0-9]+$ ]] || n=1
        if [ "$nf" -eq 0 ] && [ "$np" -ge "$n" ]; then continue; fi
        any=1
        if [ "$own" = operator ]; then printf 'operator %s\n' "$id"; else printf '%s\n' "$id"; fi
    done < <(table_rows <(master_src "$m") '## Goal cases')
    if [ "$any" -eq 0 ]; then
        note "the saved log shows every goal case passing; if the last run failed, show the operator this tail:"
        tail -n 20 "$log" >&2
    fi
    return 0
}
