#!/usr/bin/env bash
# goal-check.sh — the check behind `bin/gate.sh goal`. Sourced by gate.sh, never run on its own.
#
# Contract: templates/master-plan.md owns `## Goal fit`, `## Goal cases` and the `goal_fit: required`
# opt-in. This file implements them and states none of them again.
#
# It uses these from gate.sh, lib/arch-check.sh and lib/master-check.sh: US, violations, notes, die,
# table_rows, table_header, col_index, cell, arch_fm_value, master_src, master_resolve, GATE_VAULT_ROOT.

goal_refuse() {
    printf 'REFUSED goal %s: %s%s\n' "$1" "$2" "${3:+ [$3]}" >&2
    violations=$((violations + 1))
}

# goal_field <file> <field> <column>: the value or evidence cell of one `## Goal fit` row.
goal_field() {
    local file=$1 want=$2 col=$3 h i_f i_c row
    h=$(table_header <(master_src "$file") '## Goal fit' || true)
    i_f=$(col_index "$h" field); i_c=$(col_index "$h" "$col")
    [ -n "$i_f" ] && [ -n "$i_c" ] || return 0
    while IFS= read -r row; do
        [ "$(cell "$row" "$i_f")" = "$want" ] && { cell "$row" "$i_c"; return 0; }
    done < <(table_rows <(master_src "$file") '## Goal fit')
    return 0
}

# goal_minutes <value>: `<number> min` or `<number> h` in minutes, unrounded; returns 1 otherwise.
goal_minutes() {
    local v=$1
    [[ $v =~ ^([0-9]+([.][0-9]+)?)[[:space:]]*(min|h)$ ]] || return 1
    awk -v n="${BASH_REMATCH[1]}" -v u="${BASH_REMATCH[3]}" 'BEGIN { printf "%.4f", (u == "h" ? n * 60 : n) }'
}

# goal_criterion_check <plan> <file> <id> <command>: the goal row names a criterion this command decides.
goal_criterion_check() {
    local plan=$1 file=$2 id=$3 cmd=$4 h i_id i_cr i_how i_kind row found="" first
    h=$(table_header <(master_src "$file") '## Success criteria' || true)
    i_id=$(col_index "$h" id); i_cr=$(col_index "$h" criterion)
    i_how=$(col_index "$h" how); i_kind=$(col_index "$h" kind)
    [ -n "$i_id" ] && [ -n "$i_cr" ] || { goal_refuse "$plan" "## Success criteria needs id and criterion columns to name the goal"; return 0; }
    while IFS= read -r row; do [ "$(cell "$row" "$i_id")" = "$id" ] && { found=$row; break; }; done \
        < <(table_rows <(master_src "$file") '## Success criteria')
    [ -n "$found" ] || { goal_refuse "$plan" "the goal row names $id, and ## Success criteria has no $id" "$id"; return 0; }
    if [ -z "$cmd" ]; then
        goal_refuse "$plan" "the goal row's evidence holds no command in backticks; write the command that decides $id" "$id"; return 0
    fi
    first=${cmd%%[[:space:]]*}
    [ -n "$first" ] || { goal_refuse "$plan" "the goal row's evidence holds an empty command; write the command that decides $id" "$id"; return 0; }
    case "${first,,}" in
        *.md|*.json|*.yaml|*.yml|*.csv|*.txt)
            goal_refuse "$plan" "the goal command \`$cmd\` starts with a document path; the goal is decided by a command that runs" "$id" ;;
    esac
    [[ $(cell "$found" "$i_cr") == *"\`$cmd\`"* ]] ||
        goal_refuse "$plan" "the goal command \`$cmd\` does not appear in the text of $id; the criterion must name the command that decides it" "$id"
    [ -z "$i_how" ] || [ "$(cell "$found" "$i_how")" = command ] || goal_refuse "$plan" "$id is the goal and its how is not command" "$id"
    [ -z "$i_kind" ] || [ "$(cell "$found" "$i_kind")" = delivery ] || goal_refuse "$plan" "$id is the goal and its kind is not delivery" "$id"
}

# goal_paths_check <plan> <file> <evidence>: at least two `;`-separated paths, each citing a session
# id, a criterion id or a path:line.
goal_paths_check() {
    local plan=$1 file=$2 ev=$3 ids p tok good=0 h i row sec
    ids=" "
    for sec in '## Sessions' '## Success criteria'; do
        h=$(table_header <(master_src "$file") "$sec" || true); i=$(col_index "$h" id)
        [ -n "$i" ] || continue
        while IFS= read -r row; do ids+="$(cell "$row" "$i") "; done < <(table_rows <(master_src "$file") "$sec")
    done
    while IFS= read -r p; do
        [ -n "${p//[[:space:]]/}" ] || continue
        for tok in $(tr -c 'A-Za-z0-9_./:-' ' ' <<<"$p"); do
            tok=${tok%%[.:]}; tok=${tok%%[.:]}
            if [[ $ids == *" $tok "* ]] || [[ $tok =~ ^[A-Za-z0-9_.-]*[/.][A-Za-z0-9_./-]*:[0-9]+(-[0-9]+)?$ ]]; then good=$((good + 1)); break; fi
        done
    done < <(tr ';' '\n' <<<"$ev")
    [ "$good" -ge 2 ] || goal_refuse "$plan" "failure paths names $good path(s) citing a session id, criterion id or path:line; write at least two, separated by ;" "failure paths"
}

# cmd_goal <plan>
cmd_goal() {
    local plan=${1:-} file before=$violations so rc=0 cmd lim est ml me out
    [ -n "$plan" ] || die "no plan given"
    [ $# -le 1 ] || die "goal takes one plan"
    { [ -f "$plan" ] && [ -r "$plan" ]; } || die "cannot read: $plan"
    file=$plan
    so=$(arch_fm_value <(master_src "$plan") session_of)
    if [ -n "$so" ]; then
        file=$(master_resolve "$plan" "$so") || return 0     # gate.sh master refuses a bad session_of
        [ -r "$file" ] || die "cannot read: $file"
    fi
    master_is_table "$(table_header <(master_src "$file") '## Sessions' || true)" || return 0
    if [ "$(arch_fm_value <(master_src "$file") goal_fit)" != required ]; then
        note "$file has no goal_fit: required, so nothing checks that its sessions meet the goal"
        return 0
    fi
    if [ -z "$(table_header <(master_src "$file") '## Goal fit' || true)" ]; then
        goal_refuse "$file" "the plan has goal_fit: required and no ## Goal fit table; copy it from templates/master-plan.md"; return 0
    fi

    local goal; goal=$(goal_field "$file" goal value)
    if [ -z "$goal" ]; then goal_refuse "$file" "the goal row is empty; name the success criterion that is the operator's goal" goal
    else
        cmd=$(goal_field "$file" goal evidence)
        if [[ $cmd == *\`*\`* ]]; then
            cmd=${cmd#*\`}; cmd=${cmd%%\`*}
            cmd=${cmd#"${cmd%%[![:space:]]*}"}; cmd=${cmd%"${cmd##*[![:space:]]}"}
            [ -n "$cmd" ] || cmd=" "
        else cmd=""; fi
        goal_criterion_check "$file" "$file" "$goal" "$cmd"
    fi

    lim=$(goal_field "$file" 'runtime limit' value); est=$(goal_field "$file" 'runtime estimate' value)
    if ! ml=$(goal_minutes "$lim"); then goal_refuse "$file" "runtime limit '$lim' is not <number> min or <number> h; ask the operator for it" 'runtime limit'
    elif ! me=$(goal_minutes "$est"); then goal_refuse "$file" "runtime estimate '$est' is not <number> min or <number> h" 'runtime estimate'
    elif awk -v e="$me" -v l="$ml" 'BEGIN { exit !(e + 0 > l + 0) }'; then goal_refuse "$file" "runtime estimate $est is over the limit $lim; cut the goal or have the operator raise the limit" 'runtime estimate'
    fi
    [ -n "$(goal_field "$file" 'runtime estimate' evidence)" ] || goal_refuse "$file" "runtime estimate names no source" 'runtime estimate'

    goal_paths_check "$file" "$file" "$(goal_field "$file" 'failure paths' evidence)"

    if [ -z "$(table_header <(master_src "$file") '## Goal cases' || true)" ]; then
        goal_refuse "$file" "the plan has goal_fit: required and no ## Goal cases table; list every case the goal command needs, with its owning session"
    else
        out=$("$GATE_VAULT_ROOT/bin/goal-trace.sh" "$file" 2>&1) || rc=$?
        case "$rc" in
            0) ;;
            1) goal_refuse "$file" "not every goal case has an owning session: $(tr '\n' ';' <<<"$out" | sed 's/;$//; s/;/; /g')" 'Goal cases' ;;
            *) goal_refuse "$file" "bin/goal-trace.sh could not read the goal cases: $out" 'Goal cases' ;;
        esac
    fi
    [ "$violations" -eq "$before" ] && printf 'goal: ok %s\n' "$file"
    return 0
}
