#!/usr/bin/env bash
# arch-check.sh — the checks behind `bin/gate.sh arch`. Sourced by gate.sh, never run on its own.
#
# Contract: commands/_shared/architecture-spec.md owns the sections, columns, order of checks and
# message text. This file implements it and states none of it again.
#
# It uses these from gate.sh: US, violations, die, frontmatter_get, table_rows, table_header, col_index.

ARCH_TMP=""
# Set by arch_table and arch_cells and read by the code that called them, so a check must call
# arch_table before it reads a row. Every check below does.
ARCH_HDR=""
ARCH_IDX=()
ARCH_C=()

arch_cleanup() { [ -z "$ARCH_TMP" ] || rm -rf "$ARCH_TMP"; }

# arch_refuse <spec> <problem> [row]
arch_refuse() {
    printf 'REFUSED arch %s: %s%s\n' "$1" "$2" "${3:+ [$3]}" >&2
    violations=$((violations + 1))
}

arch_trim() {
    local v=$1
    v=${v#"${v%%[![:space:]]*}"}
    v=${v%"${v##*[![:space:]]}"}
    printf '%s' "$v"
}

# vault_key <VAULT.md> <key>: the raw value of the first `key:` line, CR and padding removed.
# Returns 1 when the file or the key is absent, so a caller can tell absent from empty.
vault_key() {
    local file=$1 key=$2 line
    [ -r "$file" ] || return 1
    line=$(awk -v k="$key" 'index($0, k ":") == 1 { print; exit }' "$file")
    [ -n "$line" ] || return 1
    line=${line#*:}
    line=${line%$'\r'}
    printf '%s' "$(arch_trim "$line")"
}

# The repo's profile: code, harness or none. An invalid value prints `!<value>`.
arch_repo_profile() {
    local v
    if ! v=$(vault_key "$1" arch_profile); then printf 'none'; return 0; fi
    v=${v%%[[:space:]]\#*}
    v=$(arch_trim "$v")
    case "$v" in
        code|harness|none) printf '%s' "$v" ;;
        *)                 printf '!%s' "$v" ;;
    esac
}

arch_fm_has() {
    awk -v k="$2" 'NR == 1 && $0 == "---" { i = 1; next } i && $0 == "---" { exit }
                   i && index($0, k ":") == 1 { f = 1 } END { exit f ? 0 : 1 }' "$1"
}

# arch_fence_check <raw> <section> <mermaid|nonblank>
arch_fence_check() {
    awk -v want="$2" -v mode="$3" '
        /^```/ {
            if (!inf) { inf = 1; lang = substr($0, 4)
                        if (sec == want && mode == "mermaid" && lang ~ /^mermaid/) found = 1 }
            else inf = 0
            next
        }
        !inf && /^## / { s = substr($0, 4); sub(/[ \t]+$/, "", s); sec = s; next }
        inf && sec == want && mode == "nonblank" && $0 ~ /[^ \t]/ { found = 1 }
        END { exit found ? 0 : 1 }' "$1"
}

# arch_params <cell>: one param per line, split at bracket depth 0. A param with a default value
# is prefixed with `=`.
arch_params() {
    awk -v s="$1" 'BEGIN {
        n = length(s); d = 0; cur = ""; eq = 0
        for (i = 1; i <= n; i++) {
            c = substr(s, i, 1); p = (i > 1) ? substr(s, i - 1, 1) : ""
            if (c ~ /[<[(]/) d++
            else if (c ~ /[]>)]/ && !(c == ">" && (p == "-" || p == "="))) d--
            if (c == "," && d == 0) { print (eq ? "=" : "") cur; cur = ""; eq = 0; continue }
            if (c == "=" && d == 0 && substr(s, i + 1, 1) != ">") eq = 1
            cur = cur c
        }
        print (eq ? "=" : "") cur
        if (d != 0) print "!unbalanced"
    }'
}

arch_check_params() {
    local spec=$1 row=$2 p item name typ dflt
    p=$(arch_trim "$3")
    [ "$p" = "-" ] && return 0
    if [ -z "$p" ]; then arch_refuse "$spec" "params is empty, write - for none" "$row"; return 0; fi
    while IFS= read -r item; do
        if [ "$item" = "!unbalanced" ]; then arch_refuse "$spec" "params has unbalanced brackets" "$row"; continue; fi
        dflt=0
        if [ "${item#=}" != "$item" ]; then dflt=1; item=${item#=}; fi
        item=$(arch_trim "$item")
        if [ -z "$item" ]; then arch_refuse "$spec" "params holds an empty param" "$row"; continue; fi
        if [[ $item == *:* ]]; then
            name=$(arch_trim "${item%%:*}"); typ=$(arch_trim "${item#*:}")
        else
            name=$item; typ=""
        fi
        if [ "$dflt" = 1 ]; then arch_refuse "$spec" "param $name has a default value" "$row"; continue; fi
        if [ -z "$typ" ]; then arch_refuse "$spec" "param $name has no type" "$row"; continue; fi
        [[ $name =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || arch_refuse "$spec" "param name $name is not an identifier" "$row"
    done < <(arch_params "$p")
}

# arch_table <clean> <heading> <spec> <column>...: sets ARCH_HDR and ARCH_IDX (1-based column
# positions, 0 for a missing one). Returns 1 when the table or a column is missing.
arch_table() {
    local clean=$1 heading=$2 spec=$3 c i ok=0
    shift 3
    ARCH_HDR=$(table_header "$clean" "## $heading")
    if [ -z "$ARCH_HDR" ]; then arch_refuse "$spec" "section $heading has no table"; return 1; fi
    ARCH_IDX=()
    for c in "$@"; do
        i=$(col_index "$ARCH_HDR" "$c")
        if [ -z "$i" ]; then
            arch_refuse "$spec" "section $heading lacks column $c"; ok=1; ARCH_IDX+=(0)
        else
            ARCH_IDX+=("$i")
        fi
    done
    return "$ok"
}

# arch_cells <row> <spec> <heading>: fills ARCH_C (1-based). Returns 1 on a row of the wrong width.
arch_cells() {
    local row=$1 spec=$2 heading=$3 t nrow nhdr raw=()
    t=${row//[!$US]/};  nrow=$(( ${#t} + 1 ))
    t=${ARCH_HDR//[!$US]/}; nhdr=$(( ${#t} + 1 ))
    IFS=$US read -r -a raw <<< "$row" || true
    ARCH_C=("" ${raw[@]+"${raw[@]}"})
    if [ "$nrow" -ne "$nhdr" ]; then
        arch_refuse "$spec" "section $heading row has $nrow cells, header has $nhdr" "${ARCH_C[1]:-}"
        return 1
    fi
    return 0
}

arch_c() { printf '%s' "${ARCH_C[$1]:-}"; }

# arch_need <spec> <row> <what> <value>: refuse an empty value.
arch_need() {
    [ -n "$(arch_trim "$4")" ] || arch_refuse "$1" "$3 is empty" "$2"
}

arch_na_line() {
    awk -v h="## $2" '$0 == h { s = 1; next } s && /^## / { exit } s && /^n\/a/ { print; exit }' "$1"
}

arch_check_data_model() {
    local clean=$1 spec=$2 na hdr row tbl col nul key idx ref name tables="" pks="" t
    na=$(arch_na_line "$clean" "Data model")
    hdr=$(table_header "$clean" "## Data model")
    if [ -n "$na" ]; then
        if [ -n "$hdr" ]; then arch_refuse "$spec" "section Data model holds n/a and a table"; return 0; fi
        [[ $na =~ ^n/a:[[:space:]]*[^[:space:]] ]] || arch_refuse "$spec" "n/a needs a reason: n/a: <reason>" "Data model"
        return 0
    fi
    arch_table "$clean" "Data model" "$spec" table column type null key index references || return 0
    local i_t=${ARCH_IDX[0]} i_c=${ARCH_IDX[1]} i_n=${ARCH_IDX[3]} i_k=${ARCH_IDX[4]} i_i=${ARCH_IDX[5]} i_r=${ARCH_IDX[6]}
    local any=0
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "Data model" || continue
        tbl=$(arch_trim "$(arch_c "$i_t")"); col=$(arch_trim "$(arch_c "$i_c")")
        nul=$(arch_trim "$(arch_c "$i_n")"); key=$(arch_trim "$(arch_c "$i_k")")
        idx=$(arch_trim "$(arch_c "$i_i")"); ref=$(arch_trim "$(arch_c "$i_r")")
        name="$tbl.$col"
        for t in "$tbl" "$col"; do
            [[ $t =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || arch_refuse "$spec" "name '$t' is not an identifier" "$name"
        done
        case "$key" in PK|FK|UQ|'') ;; *) arch_refuse "$spec" "key must be PK, FK, UQ or empty" "$name" ;; esac
        case "$nul" in yes|no) ;; *) arch_refuse "$spec" "null must be yes or no" "$name" ;; esac
        if [ -n "$ref" ]; then
            [[ $ref =~ ^[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*$ ]] || arch_refuse "$spec" "references must be table.column" "$name"
            if [ -z "$idx" ] || [ "$idx" = "-" ]; then arch_refuse "$spec" "foreign key has no index" "$name"; fi
        elif [ "$key" = "FK" ]; then
            arch_refuse "$spec" "foreign key names no references" "$name"
        fi
        case $'\n'"$tables" in *$'\n'"$tbl"$'\n'*) ;; *) tables="$tables$tbl"$'\n' ;; esac
        if [ "$key" = "PK" ]; then pks="$pks$tbl"$'\n'; fi
    done < <(table_rows "$clean" "## Data model")
    [ "$any" = 1 ] || { arch_refuse "$spec" "section Data model has no rows"; return 0; }
    while IFS= read -r t; do
        [ -n "$t" ] || continue
        case $'\n'"$pks" in *$'\n'"$t"$'\n'*) ;; *) arch_refuse "$spec" "table has no primary key" "$t" ;; esac
    done <<< "$tables"
}

arch_check_interfaces() {
    local clean=$1 spec=$2 row name any=0
    arch_table "$clean" "Interfaces" "$spec" interface method params returns throws layer || return 0
    local i_i=${ARCH_IDX[0]} i_m=${ARCH_IDX[1]} i_p=${ARCH_IDX[2]} i_r=${ARCH_IDX[3]} i_l=${ARCH_IDX[5]}
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "Interfaces" || continue
        name="$(arch_trim "$(arch_c "$i_i")").$(arch_trim "$(arch_c "$i_m")")"
        arch_need "$spec" "$name" "returns" "$(arch_c "$i_r")"
        arch_need "$spec" "$name" "layer" "$(arch_c "$i_l")"
        arch_check_params "$spec" "$name" "$(arch_c "$i_p")"
    done < <(table_rows "$clean" "## Interfaces")
    [ "$any" = 1 ] || arch_refuse "$spec" "section Interfaces has no rows"
}

# arch_check_plain <clean> <spec> <heading> <column>...: a table whose rows need every cell filled.
arch_check_plain() {
    local clean=$1 spec=$2 heading=$3 row k any=0
    shift 3
    arch_table "$clean" "$heading" "$spec" "$@" || return 0
    local idxs=("${ARCH_IDX[@]}") names=("$@")
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "$heading" || continue
        for k in "${!idxs[@]}"; do
            arch_need "$spec" "$(arch_trim "$(arch_c 1)")" "${names[$k]}" "$(arch_c "${idxs[$k]}")"
        done
    done < <(table_rows "$clean" "## $heading")
    [ "$any" = 1 ] || arch_refuse "$spec" "section $heading has no rows"
}

arch_check_reuse() {
    local clean=$1 spec=$2 row need sym dec reason any=0
    arch_table "$clean" "Reuse map" "$spec" need "existing symbol" decision reason || return 0
    local i_n=${ARCH_IDX[0]} i_s=${ARCH_IDX[1]} i_d=${ARCH_IDX[2]} i_r=${ARCH_IDX[3]}
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "Reuse map" || continue
        need=$(arch_trim "$(arch_c "$i_n")"); sym=$(arch_trim "$(arch_c "$i_s")")
        dec=$(arch_trim "$(arch_c "$i_d")");  reason=$(arch_trim "$(arch_c "$i_r")")
        case "$dec" in
            reuse|extend) if [ -z "$sym" ] || [ "$sym" = "-" ]; then arch_refuse "$spec" "$dec row names no symbol" "$need"; fi ;;
            new)          [ -n "$reason" ] || arch_refuse "$spec" "new reuse row has no reason" "$need" ;;
            *)            arch_refuse "$spec" "decision must be reuse, extend or new" "$need" ;;
        esac
    done < <(table_rows "$clean" "## Reuse map")
    [ "$any" = 1 ] || arch_refuse "$spec" "section Reuse map has no rows"
}

# arch_int <spec> <row> <what> <value> <min> <max>
arch_int() {
    local v
    v=$(arch_trim "$4")
    if [[ ! $v =~ ^[0-9]{1,7}$ ]] || [ $((10#$v)) -lt "$5" ] || [ $((10#$v)) -gt "$6" ]; then
        arch_refuse "$1" "$3 must be an integer from $5 to $6" "$2"
    fi
}

arch_check_size() {
    local clean=$1 spec=$2 row path any=0 i_m
    arch_table "$clean" "Size budgets" "$spec" path "max lines" || return 0
    local i_p=${ARCH_IDX[0]} i_l=${ARCH_IDX[1]}
    i_m=$(col_index "$ARCH_HDR" "max method lines")
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "Size budgets" || continue
        path=$(arch_trim "$(arch_c "$i_p")")
        arch_need "$spec" "$path" "path" "$path"
        arch_int "$spec" "$path" "max lines" "$(arch_c "$i_l")" 1 100000
        if [ -n "$i_m" ]; then arch_int "$spec" "$path" "max method lines" "$(arch_c "$i_m")" 1 100000; fi
    done < <(table_rows "$clean" "## Size budgets")
    [ "$any" = 1 ] || arch_refuse "$spec" "section Size budgets has no rows"
}

arch_check_files() {
    local clean=$1 spec=$2 repo=$3 row path new loaded any=0
    arch_table "$clean" "Files" "$spec" path new purpose loaded || return 0
    local i_p=${ARCH_IDX[0]} i_n=${ARCH_IDX[1]} i_u=${ARCH_IDX[2]} i_l=${ARCH_IDX[3]}
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "Files" || continue
        path=$(arch_trim "$(arch_c "$i_p")"); new=$(arch_trim "$(arch_c "$i_n")"); loaded=$(arch_trim "$(arch_c "$i_l")")
        arch_need "$spec" "$path" "path" "$path"
        arch_need "$spec" "$path" "purpose" "$(arch_c "$i_u")"
        case "$loaded" in always|on-demand|never-by-agent) ;; *) arch_refuse "$spec" "loaded must be always, on-demand or never-by-agent" "$path" ;; esac
        case "$new" in
            yes) ;;
            no)
                if [[ $path == /* ]] || [[ $path =~ (^|/)\.\.(/|$) ]]; then
                    arch_refuse "$spec" "path must be relative to the repo and hold no .." "$path"
                elif [ ! -e "$repo/$path" ]; then
                    arch_refuse "$spec" "path does not exist" "$path"
                fi ;;
            *) arch_refuse "$spec" "new must be yes or no" "$path" ;;
        esac
    done < <(table_rows "$clean" "## Files")
    [ "$any" = 1 ] || arch_refuse "$spec" "section Files has no rows"
}

arch_check_load_order() {
    local clean=$1 spec=$2 row trig any=0
    arch_table "$clean" "Load order" "$spec" trigger loads tokens-max || return 0
    local i_t=${ARCH_IDX[0]} i_l=${ARCH_IDX[1]} i_k=${ARCH_IDX[2]}
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "Load order" || continue
        trig=$(arch_trim "$(arch_c "$i_t")")
        arch_need "$spec" "$trig" "trigger" "$trig"
        arch_need "$spec" "$trig" "loads" "$(arch_c "$i_l")"
        arch_int "$spec" "$trig" "tokens-max" "$(arch_c "$i_k")" 0 10000000
    done < <(table_rows "$clean" "## Load order")
    [ "$any" = 1 ] || arch_refuse "$spec" "section Load order has no rows"
}

arch_check_config() {
    local clean=$1 spec=$2 na hdr
    na=$(arch_na_line "$clean" "Config points")
    hdr=$(table_header "$clean" "## Config points")
    if [ -n "$na" ]; then
        if [ -n "$hdr" ]; then arch_refuse "$spec" "section Config points holds n/a and a table"; return 0; fi
        [[ $na =~ ^n/a:[[:space:]]*[^[:space:]] ]] || arch_refuse "$spec" "n/a needs a reason: n/a: <reason>" "Config points"
        return 0
    fi
    arch_check_plain "$clean" "$spec" "Config points" key file default
}

# arch_check_spec <spec> <repo> <repo profile>
arch_check_spec() {
    local spec=$1 repo=$2 rprofile=$3 raw clean type prof s h
    raw="$ARCH_TMP/spec.raw"; clean="$ARCH_TMP/spec.clean"
    tr -d '\r' < "$spec" > "$raw"
    type=$(arch_trim "$(frontmatter_get "$raw" type)")
    if [ "$type" != "arch-spec" ]; then arch_refuse "$spec" "frontmatter needs type: arch-spec"; return 0; fi
    if ! awk 'NR == 1 && $0 == "---" { o = 1; next } o && $0 == "---" { c = 1; exit } END { exit c ? 0 : 1 }' "$raw"; then
        arch_refuse "$spec" "frontmatter is not closed"; return 0
    fi
    prof=$(arch_trim "$(frontmatter_get "$raw" profile)")
    case "$prof" in code|harness) ;; *) prof="" ;; esac
    if [ -z "$prof" ] || { [ "$rprofile" != none ] && [ "$prof" != "$rprofile" ]; }; then
        arch_refuse "$spec" "profile differs from repo profile, or is missing or invalid"
    fi
    if [ -z "$(arch_trim "$(frontmatter_get "$raw" plan)")" ]; then arch_refuse "$spec" "frontmatter needs a non-empty plan"; fi
    if arch_fm_has "$raw" status; then arch_refuse "$spec" "frontmatter must not carry status"; fi
    [ -n "$prof" ] || return 0
    if grep -qE '\{\{|path/to/' "$raw"; then arch_refuse "$spec" "spec still holds a template placeholder"; fi

    if ! awk '/^```/ { f = !f; next } !f { if ($0 ~ /^## /) sub(/[ \t]+$/, ""); print } END { exit f }' "$raw" > "$clean"; then
        arch_refuse "$spec" "unclosed code fence"
    fi
    while IFS= read -r h; do
        [ -n "$h" ] || continue
        arch_refuse "$spec" "duplicate section ${h#\#\# }"
    done < <(grep '^## ' "$clean" | sort | uniq -d)

    local sections
    if [ "$prof" = code ]; then
        sections=("Data model" "Data flow" "Interfaces" "Layers & placement" "Reuse map" "Size budgets")
    else
        sections=("File tree" "Files" "Data flow" "Interfaces" "Load order" "Reuse map" "Size budgets" "Config points")
    fi
    for s in "${sections[@]}"; do
        if ! grep -qxF "## $s" "$clean"; then arch_refuse "$spec" "missing section $s"; continue; fi
        case "$s" in
            "Data model")         arch_check_data_model "$clean" "$spec" ;;
            "Data flow")          arch_fence_check "$raw" "Data flow" mermaid || arch_refuse "$spec" "section Data flow has no mermaid block" ;;
            "Interfaces")         arch_check_interfaces "$clean" "$spec" ;;
            "Layers & placement") arch_check_plain "$clean" "$spec" "Layers & placement" logic layer file ;;
            "Reuse map")          arch_check_reuse "$clean" "$spec" ;;
            "Size budgets")       arch_check_size "$clean" "$spec" ;;
            "File tree")          arch_fence_check "$raw" "File tree" nonblank || arch_refuse "$spec" "section File tree has no fenced block" ;;
            "Files")              arch_check_files "$clean" "$spec" "$repo" ;;
            "Load order")         arch_check_load_order "$clean" "$spec" ;;
            "Config points")      arch_check_config "$clean" "$spec" ;;
        esac
    done
}

# cmd_arch <file> [--repo <root>]
cmd_arch() {
    local file="" repo="" raw type rprofile as spec before
    while [ $# -gt 0 ]; do
        case "$1" in
            --repo) [ -z "$repo" ] || die "--repo given twice"
                    repo=${2:-}; [ -n "$repo" ] || die "--repo needs a directory"; shift 2 ;;
            -*)     die "unknown option: $1" ;;
            *)      [ -z "$file" ] || die "arch takes one file"; file=$1; shift ;;
        esac
    done
    [ -n "$file" ] || die "no file given"
    repo=${repo:-$PWD}
    [ -d "$repo" ] || die "not a directory: $repo"
    { [ -f "$file" ] && [ -r "$file" ]; } || die "cannot read: $file"
    if [ -e "$repo/VAULT.md" ] && { [ ! -f "$repo/VAULT.md" ] || [ ! -r "$repo/VAULT.md" ]; }; then
        die "cannot read: $repo/VAULT.md"
    fi

    arch_cleanup
    ARCH_TMP=$(mktemp -d)
    trap arch_cleanup EXIT
    before=$violations
    raw="$ARCH_TMP/in.raw"
    tr -d '\r' < "$file" > "$raw"
    type=$(arch_trim "$(frontmatter_get "$raw" type)")
    case "$type" in
        arch-spec|plan) ;;
        *) arch_refuse "$file" "frontmatter needs type: arch-spec"; return 0 ;;
    esac
    rprofile=$(arch_repo_profile "$repo/VAULT.md")
    if [ "${rprofile#!}" != "$rprofile" ]; then
        arch_refuse "$file" "arch_profile has an invalid value" "${rprofile#!}"; return 0
    fi

    spec=$file
    if [ "$type" = plan ]; then
        as=$(frontmatter_get "$raw" arch_spec)
        as=${as%%[[:space:]]\#*}
        as=$(arch_trim "$as")
        case "$as" in \#*) as="" ;; esac
        if [ -z "$as" ]; then
            [ "$rprofile" = none ] && return 0
            arch_refuse "$file" "plan names no arch_spec while repo declares arch_profile $rprofile"; return 0
        fi
        if [[ $as == /* ]]; then spec=$as; else spec="$(dirname "$file")/$as"; fi
        if [ ! -f "$spec" ]; then arch_refuse "$file" "arch_spec names a file that does not exist" "$as"; return 0; fi
        [ -r "$spec" ] || die "cannot read: $spec"
    fi

    arch_check_spec "$spec" "$repo" "$rprofile"
    if [ "$violations" -eq "$before" ]; then printf 'arch: ok %s\n' "$spec"; fi
    return 0
}
