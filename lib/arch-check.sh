#!/usr/bin/env bash
# arch-check.sh — the checks behind `bin/gate.sh arch`. Sourced by gate.sh, never run on its own.
#
# Contract: commands/_shared/architecture-spec.md owns the profile file format, the validator and
# rule library, the order of checks and the message text. This file implements the engine and states
# none of it again. The sections and columns of a profile live in arch-profiles/<name>.tsv, loaded by
# name when a spec names it, so a new project type is a new file and no code change.
#
# It uses these from gate.sh: GATE_VAULT_ROOT, US, violations, die, frontmatter_get, table_rows,
# table_header, col_index.

ARCH_TMP=""
# Set by arch_check_table and read by the helpers it calls: the header of the table being checked,
# the profile's column names, validators and positions (0 when an optional column is absent), and the
# cells of the current row.
ARCH_HDR=""
ARCH_CN=()
ARCH_CV=()
ARCH_CX=()
ARCH_C=()
ARCH_TABLES=""
ARCH_PKS=""

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
    [ -f "$file" ] && [ -r "$file" ] || return 1
    line=$(awk -v k="$key" 'index($0, k ":") == 1 { print; exit }' "$file")
    [ -n "$line" ] || return 1
    line=${line#*:}
    line=${line%$'\r'}
    printf '%s' "$(arch_trim "$line")"
}

# arch_profile_file <name> <repo>: the profile file for <name>, the repo's own first, then the
# framework's. Returns 1 when the name is malformed or no file exists.
arch_profile_file() {
    local n=$1 repo=$2 f
    [[ $n =~ ^[a-z][a-z0-9-]*$ ]] || return 1
    for f in "$repo/arch-profiles/$n.tsv" "${GATE_VAULT_ROOT}/arch-profiles/$n.tsv"; do
        if [ -f "$f" ]; then printf '%s' "$f"; return 0; fi
    done
    return 1
}

# The repo's profile name, or none. A value that names no profile file prints `!<value>`.
arch_repo_profile() {
    local repo=$1 v
    if ! v=$(vault_key "$repo/VAULT.md" arch_profile); then printf 'none'; return 0; fi
    v=${v%%[[:space:]]\#*}
    v=$(arch_trim "$v")
    if [ "$v" = none ] || arch_profile_file "$v" "$repo" >/dev/null; then printf '%s' "$v"; else printf '!%s' "$v"; fi
}

# arch_fm_value <file> <key>: a frontmatter value with a trailing ` # comment` removed and padding
# trimmed. A value that is only a comment is empty.
arch_fm_value() {
    local v
    v=$(frontmatter_get "$1" "$2")
    v=${v%%[[:space:]]\#*}
    v=$(arch_trim "$v")
    case "$v" in \#*) v="" ;; esac
    printf '%s' "$v"
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
# is prefixed with `=`. A last line `!unbalanced` reports brackets that never close.
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

# arch_get <column>: the trimmed cell of the current row for a profile column. Underscores in the
# name stand for spaces. Prints nothing for a column the profile does not have or a row lacks.
arch_get() {
    local want=${1//_/ } k
    for k in "${!ARCH_CN[@]}"; do
        if [ "${ARCH_CN[$k]}" = "$want" ]; then
            if [ "${ARCH_CX[$k]}" -gt 0 ]; then arch_trim "$(arch_c "${ARCH_CX[$k]}")"; fi
            return 0
        fi
    done
    return 0
}

# The name a refusal quotes for the current row: interface.method, table.column, else the first cell.
arch_row_name() {
    local a b
    a=$(arch_get interface); b=$(arch_get method)
    if [ -n "$a" ] && [ -n "$b" ]; then printf '%s.%s' "$a" "$b"; return 0; fi
    a=$(arch_get table); b=$(arch_get column)
    if [ -n "$a" ] && [ -n "$b" ]; then printf '%s.%s' "$a" "$b"; return 0; fi
    arch_trim "$(arch_c 1)"
}

# arch_validate <spec> <row> <column> <validator> <value>
arch_validate() {
    local spec=$1 row=$2 col=$3 v=$4 val=$5 list r min max a i n ok shown alts=()
    case "$v" in
        any) ;;
        nonempty) [ -n "$val" ] || arch_refuse "$spec" "$col is empty" "$row" ;;
        ident)    [[ $val =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || arch_refuse "$spec" "$col '$val' is not an identifier" "$row" ;;
        enum\(*\))
            list=${v#enum\(}; list=${list%\)}
            IFS='|' read -r -a alts <<< "${list}|x"
            n=$(( ${#alts[@]} - 1 )); ok=0; shown=""
            for ((i = 0; i < n; i++)); do
                a=${alts[$i]}
                if [ "$a" = "$val" ]; then ok=1; fi
                if [ -z "$a" ]; then a=empty; fi
                if [ "$i" -eq 0 ]; then shown=$a
                elif [ "$i" -eq $((n - 1)) ]; then shown="$shown or $a"
                else shown="$shown, $a"; fi
            done
            if [ "$ok" != 1 ]; then arch_refuse "$spec" "$col must be $shown" "$row"; fi ;;
        int\(*\))
            r=${v#int\(}; r=${r%\)}; min=${r%-*}; max=${r#*-}
            if [[ ! $val =~ ^[0-9]{1,7}$ ]] || [ $((10#$val)) -lt "$min" ] || [ $((10#$val)) -gt "$max" ]; then
                arch_refuse "$spec" "$col must be an integer from $min to $max" "$row"
            fi ;;
        *) arch_refuse "$spec" "profile names an unknown validator $v" ;;
    esac
}

# arch_row_rules <spec> <repo> <row name> <rules>: the named rules of the profile that read several
# cells of one row. Table-wide state for pk-per-table is kept in ARCH_TABLES and ARCH_PKS.
arch_row_rules() {
    local spec=$1 repo=$2 name=$3 rules=" $4 " ref idx key dec sym reason path new tbl
    case "$rules" in *" params-typed "*) arch_check_params "$spec" "$name" "$(arch_get params)" ;; esac
    case "$rules" in *" fk-index "*)
        ref=$(arch_get references); idx=$(arch_get index); key=$(arch_get key)
        if [ -n "$ref" ]; then
            [[ $ref =~ ^[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*$ ]] || arch_refuse "$spec" "references must be table.column" "$name"
            if [ -z "$idx" ] || [ "$idx" = "-" ]; then arch_refuse "$spec" "foreign key has no index" "$name"; fi
        elif [ "$key" = "FK" ]; then
            arch_refuse "$spec" "foreign key names no references" "$name"
        fi ;;
    esac
    case "$rules" in *" pk-per-table "*)
        tbl=$(arch_get table); key=$(arch_get key)
        case $'\n'"$ARCH_TABLES" in *$'\n'"$tbl"$'\n'*) ;; *) ARCH_TABLES="$ARCH_TABLES$tbl"$'\n' ;; esac
        if [ "$key" = "PK" ]; then ARCH_PKS="$ARCH_PKS$tbl"$'\n'; fi ;;
    esac
    case "$rules" in *" reuse-decision "*)
        dec=$(arch_get decision); sym=$(arch_get existing_symbol); reason=$(arch_get reason)
        case "$dec" in
            reuse|extend) if [ -z "$sym" ] || [ "$sym" = "-" ]; then arch_refuse "$spec" "$dec row names no symbol" "$name"; fi ;;
            new)          [ -n "$reason" ] || arch_refuse "$spec" "new reuse row has no reason" "$name" ;;
        esac ;;
    esac
    case "$rules" in *" path-exists-unless-new "*)
        path=$(arch_get path); new=$(arch_get new)
        if [ "$new" = "no" ]; then
            if [[ $path == /* ]] || [[ $path =~ (^|/)\.\.(/|$) ]]; then
                arch_refuse "$spec" "path must be relative to the repo and hold no .." "$path"
            elif [ ! -e "$repo/$path" ]; then
                arch_refuse "$spec" "path does not exist" "$path"
            fi
        fi ;;
    esac
}

arch_na_line() {
    awk -v h="## $2" '$0 == h { s = 1; next } s && /^## / { exit } s && /^n\/a/ { print; exit }' "$1"
}

# arch_check_table <clean> <spec> <repo> <section> <kind> <columns> <rules>
arch_check_table() {
    local clean=$1 spec=$2 repo=$3 sec=$4 kind=$5 cols=$6 rules=$7
    local na hdr row token nm v opt req=() any=0 name k i t
    if [[ ,$kind, == *,na,* ]]; then
        na=$(arch_na_line "$clean" "$sec"); hdr=$(table_header "$clean" "## $sec")
        if [ -n "$na" ]; then
            if [ -n "$hdr" ]; then arch_refuse "$spec" "section $sec holds n/a and a table"; return 0; fi
            [[ $na =~ ^n/a:[[:space:]]*[^[:space:]] ]] || arch_refuse "$spec" "n/a needs a reason: n/a: <reason>" "$sec"
            return 0
        fi
    fi
    ARCH_CN=(); ARCH_CV=(); ARCH_CX=()
    for token in $cols; do
        nm=${token%%:*}; v=${token#*:}; opt=0
        case "$nm" in *\?) opt=1; nm=${nm%\?} ;; esac
        nm=${nm//_/ }
        ARCH_CN+=("$nm"); ARCH_CV+=("$v")
        if [ "$opt" = 0 ]; then req+=("$nm"); fi
    done
    ARCH_HDR=$(table_header "$clean" "## $sec")
    if [ -z "$ARCH_HDR" ]; then arch_refuse "$spec" "section $sec has no table"; return 0; fi
    k=0
    for nm in "${req[@]}"; do
        if [ -z "$(col_index "$ARCH_HDR" "$nm")" ]; then arch_refuse "$spec" "section $sec lacks column $nm"; k=1; fi
    done
    [ "$k" = 0 ] || return 0
    for i in "${!ARCH_CN[@]}"; do
        t=$(col_index "$ARCH_HDR" "${ARCH_CN[$i]}")
        ARCH_CX+=("${t:-0}")
    done
    ARCH_TABLES=""; ARCH_PKS=""
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        any=1
        arch_cells "$row" "$spec" "$sec" || continue
        name=$(arch_row_name)
        for i in "${!ARCH_CN[@]}"; do
            [ "${ARCH_CX[$i]}" -gt 0 ] || continue
            arch_validate "$spec" "$name" "${ARCH_CN[$i]}" "${ARCH_CV[$i]}" "$(arch_trim "$(arch_c "${ARCH_CX[$i]}")")"
        done
        arch_row_rules "$spec" "$repo" "$name" "$rules"
    done < <(table_rows "$clean" "## $sec")
    if [ "$any" != 1 ]; then arch_refuse "$spec" "section $sec has no rows"; return 0; fi
    if [[ " $rules " == *" pk-per-table "* ]]; then
        while IFS= read -r t; do
            [ -n "$t" ] || continue
            case $'\n'"$ARCH_PKS" in *$'\n'"$t"$'\n'*) ;; *) arch_refuse "$spec" "table has no primary key" "$t" ;; esac
        done <<< "$ARCH_TABLES"
    fi
}

# arch_check_spec <spec> <repo> <repo profile>
arch_check_spec() {
    local spec=$1 repo=$2 rprofile=$3 raw clean type prof pf sec kind cols rules h
    raw="$ARCH_TMP/spec.raw"; clean="$ARCH_TMP/spec.clean"
    tr -d '\r' < "$spec" > "$raw"
    type=$(arch_trim "$(frontmatter_get "$raw" type)")
    if [ "$type" != "arch-spec" ]; then arch_refuse "$spec" "frontmatter needs type: arch-spec"; return 0; fi
    if ! awk 'NR == 1 && $0 == "---" { o = 1; next } o && $0 == "---" { c = 1; exit } END { exit c ? 0 : 1 }' "$raw"; then
        arch_refuse "$spec" "frontmatter is not closed"; return 0
    fi
    prof=$(arch_trim "$(frontmatter_get "$raw" profile)")
    pf=""
    if [ -n "$prof" ] && ! pf=$(arch_profile_file "$prof" "$repo"); then pf=""; fi
    if [ -z "$pf" ] || { [ "$rprofile" != none ] && [ "$prof" != "$rprofile" ]; }; then
        arch_refuse "$spec" "profile differs from repo profile, or is missing or invalid"
    fi
    if [ -z "$(arch_trim "$(frontmatter_get "$raw" plan)")" ]; then arch_refuse "$spec" "frontmatter needs a non-empty plan"; fi
    if arch_fm_has "$raw" status; then arch_refuse "$spec" "frontmatter must not carry status"; fi
    [ -n "$pf" ] || return 0
    if grep -qE '\{\{|path/to/' "$raw"; then arch_refuse "$spec" "spec still holds a template placeholder"; fi

    if ! awk '/^```/ { f = !f; next } !f { if ($0 ~ /^## /) sub(/[ \t]+$/, ""); print } END { exit f }' "$raw" > "$clean"; then
        arch_refuse "$spec" "unclosed code fence"
    fi
    while IFS= read -r h; do
        [ -n "$h" ] || continue
        arch_refuse "$spec" "duplicate section ${h#\#\# }"
    done < <(grep '^## ' "$clean" | sort | uniq -d)

    while IFS=$'\t' read -r sec kind cols rules; do
        case "$sec" in ''|\#*) continue ;; esac
        if ! grep -qxF "## $sec" "$clean"; then arch_refuse "$spec" "missing section $sec"; continue; fi
        case "$kind" in
            fence:mermaid) arch_fence_check "$raw" "$sec" mermaid || arch_refuse "$spec" "section $sec has no mermaid block" ;;
            fence:any)     arch_fence_check "$raw" "$sec" nonblank || arch_refuse "$spec" "section $sec has no fenced block" ;;
            table|table,*) arch_check_table "$clean" "$spec" "$repo" "$sec" "$kind" "$cols" "${rules:-}" ;;
            *)             arch_refuse "$spec" "profile $prof names an unknown section kind $kind" ;;
        esac
    done < "$pf"
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
    # cmd_human replaces this trap and runs both cleanups, so each command runs the other's.
    trap 'arch_cleanup; if declare -F human_cleanup >/dev/null; then human_cleanup; fi' EXIT
    before=$violations
    raw="$ARCH_TMP/in.raw"
    tr -d '\r' < "$file" > "$raw"
    type=$(arch_trim "$(frontmatter_get "$raw" type)")
    case "$type" in
        arch-spec|plan) ;;
        *) arch_refuse "$file" "frontmatter needs type: arch-spec"; return 0 ;;
    esac
    rprofile=$(arch_repo_profile "$repo")
    if [ "${rprofile#!}" != "$rprofile" ]; then
        arch_refuse "$file" "arch_profile has an invalid value" "${rprofile#!}"; return 0
    fi

    spec=$file
    if [ "$type" = plan ]; then
        as=$(arch_fm_value "$raw" arch_spec)
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
