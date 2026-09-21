#!/usr/bin/env bash
# master-check.sh — the check behind `bin/gate.sh master`. Sourced by gate.sh, never run on its own.
#
# Contract: templates/master-plan.md owns the Sessions and Cross-session contracts tables, the
# dependency rule and the ordering rule. This file implements them and states none of them again.
#
# It uses these from gate.sh and lib/arch-check.sh: US, violations, die, table_rows, table_header,
# col_index, arch_fm_value.

# master_refuse <plan> <problem> [row]
master_refuse() {
    printf 'REFUSED master %s: %s%s\n' "$1" "$2" "${3:+ [$3]}" >&2
    violations=$((violations + 1))
}

# master_src <file>: the file without carriage returns. Each helper call reads a fresh copy, since a
# process substitution can be read once.
master_src() { tr -d '\r' < "$1"; }

# master_cols <header> <name>...: the 1-based positions of the named columns, one per line, `0` for a
# column the header lacks.
master_cols() {
    local header=$1 name idx; shift
    for name in "$@"; do idx=$(col_index "$header" "$name"); printf '%s\n' "${idx:-0}"; done
}

# master_problems <mode> <master> <session id>: run the awk program over the Sessions and contracts
# rows of <master>. Prints `problem US row` lines. Mode `table` checks the tables; mode `order`
# checks that every producer of a contract the session consumes is `done`.
master_problems() {
    local mode=$1 file=$2 me=${3:-} sh ch sr cr idx
    sh=$(table_header <(master_src "$file") '## Sessions' || true)
    ch=$(table_header <(master_src "$file") '## Cross-session contracts' || true)
    sr=$(table_rows <(master_src "$file") '## Sessions' || true)
    cr=$(table_rows <(master_src "$file") '## Cross-session contracts' || true)
    local -a s c
    while IFS= read -r idx; do s+=("$idx"); done < <(master_cols "$sh" id status depends)
    while IFS= read -r idx; do c+=("$idx"); done < <(master_cols "$ch" id contract 'produced by' 'consumed by' shape)
    awk -F "$US" -v US="$US" -v mode="$mode" -v me="$me" \
        -v si="${s[0]}" -v st="${s[1]}" -v sd="${s[2]}" -v sw="$(awk -F "$US" '{print NF}' <<<"$sh")" \
        -v ci="${c[0]}" -v cn="${c[1]}" -v cp="${c[2]}" -v cu="${c[3]}" -v csh="${c[4]}" \
        -v cw="$(awk -F "$US" '{print NF}' <<<"$ch")" '
        function e(msg, key) { if (mode == "table") print msg US key }
        function words(s, arr,   n) { gsub(/[,;]/, " ", s); return split(s, arr, " ") }
        $0 == "S" US || $0 == "C" US { next }
        $1 == "S" {
            id = $(si + 1)
            if (NF - 1 != sw) e("a Sessions row has " NF - 1 " cells and the header has " sw, id != "" ? id : "row " FNR)
            if (id == "") next
            if (id ~ /^[-: ]+$/) { e("a second table or a stray row sits under ## Sessions", id); next }
            if (id in seen) { e("session id " id " appears twice", id); next }
            seen[id] = 1; order[++n] = id; status[id] = $(st + 1); dep[id] = $(sd + 1)
            next
        }
        {
            id = $(ci + 1)
            if (NF - 1 != cw) e("a contract row has " NF - 1 " cells and the header has " cw, id != "" ? id : "row " FNR)
            if (id == "") next
            if (id ~ /^[-: ]+$/) { e("a second table or a stray row sits under ## Cross-session contracts", id); next }
            if (id in cseen) e("contract id " id " appears twice", id)
            cseen[id] = 1
            np = words($(cp + 1), P); nu = words($(cu + 1), U)
            if ($(cn + 1) == "") e(id " has an empty contract cell", id)
            if ($(csh + 1) == "") e(id " has an empty shape cell", id)
            if (np == 0) e(id " has an empty produced by cell", id)
            if (nu == 0) e(id " has an empty consumed by cell", id)
            for (i = 1; i <= np; i++) {
                if (!(P[i] in seen)) e(id " names session " P[i] " in produced by, and the Sessions table has no " P[i], id)
                for (j = 1; j <= nu; j++) pair[P[i] SUBSEP U[j]] = 1
                if (mode == "order") for (j = 1; j <= nu; j++) if (U[j] == me && P[i] != me) need[++m] = id SUBSEP P[i]
            }
            for (j = 1; j <= nu; j++) if (!(U[j] in seen)) e(id " names session " U[j] " in consumed by, and the Sessions table has no " U[j], id)
        }
        END {
            if (mode == "table") {
                for (k = 1; k <= n; k++) {
                    s = order[k]; nd = words(dep[s], D)
                    for (i = 1; i <= nd; i++) {
                        if (D[i] == s) e(s " depends on itself; drop " s " from its own depends", s)
                        else if (!(D[i] in seen)) e(s " depends on " D[i] ", and the Sessions table has no " D[i] "; write ids separated by commas or spaces, empty when none", s)
                        else if (!((D[i] SUBSEP s) in pair))
                            e(s " depends on " D[i] " and no contract row is produced by " D[i] " and consumed by " s "; add a row naming what " D[i] " hands " s " and its shape, or drop " D[i] " from depends if " s " needs nothing from " D[i], s)
                    }
                }
                exit
            }
            if (!(me in seen)) { print "the master plan has no session " me US me; exit }
            for (k = 1; k <= m; k++) {
                split(need[k], t, SUBSEP)
                if (status[t[2]] != "done")
                    print me " consumes " t[1] ", and its producer " t[2] " has status " (status[t[2]] == "" ? "empty" : status[t[2]]) ", so " t[1] " is not produced yet; mark " t[2] " done in the master plan if it shipped" US t[1]
            }
        }' <({ printf '%s\n' "$sr" | sed "s/^/S${US}/"; printf '%s\n' "$cr" | sed "s/^/C${US}/"; })
}

# master_header_check <plan> <file>: refuse a missing column in the Sessions or contracts table of
# <file>. Returns 1 when it refused.
master_header_check() {
    local plan=$1 file=$2 sh ch name
    sh=$(table_header <(master_src "$file") '## Sessions' || true)
    ch=$(table_header <(master_src "$file") '## Cross-session contracts' || true)
    for name in id status depends; do
        [ -n "$(col_index "$sh" "$name")" ] || { master_refuse "$plan" "the ## Sessions table has no $name column; a master plan records its dependencies there" "$name"; return 1; }
    done
    [ -n "$ch" ] || { master_refuse "$plan" "a master plan needs a ## Cross-session contracts table; copy it from templates/master-plan.md"; return 1; }
    for name in id contract 'produced by' 'consumed by' shape; do
        [ -n "$(col_index "$ch" "$name")" ] || { master_refuse "$plan" "the ## Cross-session contracts table has no $name column" "$name"; return 1; }
    done
}

# master_table_check <plan>: the dependency check of a master plan.
master_table_check() {
    local plan=$1 msg key
    master_header_check "$plan" "$plan" || return 0
    while IFS="$US" read -r msg key; do
        [ -n "$msg" ] && master_refuse "$plan" "$msg" "$key"
    done < <(master_problems table "$plan")
    return 0
}

# master_order_check <plan> <session_of value>: every contract the session consumes has a producer
# whose Sessions row is `done` in the master plan the value names.
master_order_check() {
    local plan=$1 so=$2 file id master msg key
    file=${so%#*}; id=${so##*#}
    if [ "$file" = "$so" ] || [ -z "$file" ] || [ -z "$id" ]; then
        master_refuse "$plan" "session_of needs the form <master plan file>#<session id>" "$so"; return 0
    fi
    if [[ $file == /* ]]; then master=$file; else master="$(dirname "$plan")/$file"; fi
    if [ ! -f "$master" ]; then master_refuse "$plan" "session_of names a master plan that does not exist" "$file"; return 0; fi
    [ -r "$master" ] || die "cannot read: $master"
    if ! master_is_table "$(table_header <(master_src "$master") '## Sessions' || true)"; then
        master_refuse "$plan" "session_of names a plan with no ## Sessions table" "$file"; return 0
    fi
    master_header_check "$plan" "$master" || return 0
    while IFS="$US" read -r msg key; do
        [ -n "$msg" ] && master_refuse "$plan" "$msg" "$key"
    done < <(master_problems order "$master" "$id")
    return 0
}

# master_is_table <header>: true when the section holds a table, which a bullet list does not.
master_is_table() { [ -n "$1" ]; }

# cmd_master <plan>
cmd_master() {
    local plan=${1:-} before=$violations ran=0 so
    [ -n "$plan" ] || die "no plan given"
    [ $# -le 1 ] || die "master takes one plan"
    { [ -f "$plan" ] && [ -r "$plan" ]; } || die "cannot read: $plan"
    if master_is_table "$(table_header <(master_src "$plan") '## Sessions' || true)"; then
        ran=1; master_table_check "$plan"
    fi
    so=$(arch_fm_value <(master_src "$plan") session_of)
    if [ -n "$so" ]; then ran=1; master_order_check "$plan" "$so"; fi
    [ "$ran" -eq 1 ] || return 0
    if [ "$violations" -eq "$before" ]; then printf 'master: ok %s\n' "$plan"; fi
    return 0
}
