#!/usr/bin/env bash
# change-map.sh — the relation map of a base..head change, for the /v-cr review seats
# (personas/_shared/review/README.md). It reads git objects only: no checkout, no repo code runs.
#
# Usage:  bin/change-map.sh build  --repo <git repo> --base <ref> --head <ref>
#         bin/change-map.sh slice  --map <file> --persona <persona file> [--paths <file>]
#         bin/change-map.sh status --map <file>
#
# Row contract. `build` prints six tab-separated fields per row:
#   relation  changed  symbol  target  line  excerpt
# `changed` is a path in the diff. `symbol` is `-` unless the relation names one. `line` is a 1-based line
# at the head ref, or `-`. `excerpt` is that line, trimmed, control bytes made spaces, secrets scrubbed by
# cr_redact_runtime, cut at 160 bytes. Relations, in output order per changed path:
#   referenced-by  a file at head mentions the changed path, its file name, or a Markdown stem as [[stem
#   references    the changed file mentions a path that exists at head; line is in the changed file
#   caller        a line at head uses a changed symbol as a whole word, outside its own definition line.
#                 A changed symbol is the enclosing definition of an added or removed line: the nearest
#                 definition at or above it, in head for an added line and in base for a removed one.
#                 A file deleted at head still yields the symbols of its removed lines.
#   test          a test file at head mentions the changed file name or a changed symbol; when nothing
#                 matches, target `none`, line `-`, excerpt `-`
#   co-change     a file outside the diff changed with the changed file in >= 3 commits reachable from
#                 base, confidence >= 0.5; line `-`; excerpt `<together>/<commits of changed>`
#   sibling       a file at head, outside the diff, in the same directory with the same extension, at
#                 most 5, most recently committed first; line of its first definition or heading
# A test file sits under tests/, test/, spec/ or __tests__/, or is named test_*, *_test.*, *.test.*,
# *Test.*, *_spec.*, *.spec.* or *.bats. Definitions, by extension: sh, bash and bats `name()` and
# `function name`; php, js, ts and vue `function name`; py `def name`; go `func name`. A binary file gets
# referenced-by rows only. The last line is
#   map-status <TAB> complete|capped|partial <TAB> <reason or -> <TAB> <relation>=<rows>/<withheld> ...
# `partial`: a git query failed after the refs resolved. `slice` prints map-status, the rows whose relation
# the persona's frontmatter `map:` key lists, then `withheld: <n> rows` when the byte cap cut any.
# `status` prints `map_status: <state> <reason>` and one `map_<relation>: <rows>/<withheld>` per relation.
#
# Env:  VCR_MAP_CAP (20 rows per relation per changed file, and per symbol for caller and test)
#       VCR_MAP_HISTORY (500 commits for co-change and sibling order)
#       VCR_MAP_MAX_COMMIT_FILES (30; a larger commit adds no co-change) · VCR_SLICE_BYTES (16000)
# Exit: 0 printed · 2 usage error, not a git repo, a ref that is not a commit, or an unreadable map

set -uo pipefail
export LC_ALL=C
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
    GIT_EXEC_PATH GIT_CONFIG_PARAMETERS GIT_COMMON_DIR GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
# Keep only absolute PATH entries, so a repo file named like a tool is never picked up through `.`.
clean=""; IFS=: read -ra parts <<< "$PATH"
for p in "${parts[@]}"; do case $p in /*) clean="${clean:+$clean:}$p" ;; esac; done
PATH=${clean:-/usr/bin:/bin}; unset clean parts p
IFS=$' \t\n'
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$root/lib/probe-emit.sh"
. "$root/lib/probe-scope.sh"
. "$root/lib/cr-sandbox.sh"

RELATIONS="referenced-by references caller test co-change sibling"
CAP=${VCR_MAP_CAP:-20}; HISTORY=${VCR_MAP_HISTORY:-500}
MAXF=${VCR_MAP_MAX_COMMIT_FILES:-30}; SLICE_BYTES=${VCR_SLICE_BYTES:-16000}
TOKEN_ERE='[A-Za-z0-9_./-]+\.(md|sh|bats|tsv|php|py|ts|js|json|yml|yaml|go|dart|vue)'

die() { printf 'change-map: %s\n' "$*" >&2; exit 2; }
# Every git call goes through probe_git: the reviewed repo's hooks, filters and fsmonitor never run.
g() { probe_git "$REPO" -c core.quotePath=false "$@"; }
# A failure is written to a file, because most queries run in a subshell where a variable would be lost.
fail() { printf '%s\n' "$*" >> "$TMP/failed"; }

def_ere() { # <path> — prints the definition ERE for the file's language, or nothing
    case $1 in
        *.sh|*.bash|*.bats) printf '%s' '^[[:space:]]*(function[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)|^[[:space:]]*function[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' ;;
        *.php|*.js|*.ts|*.vue) printf '%s' 'function[[:space:]]+&?[A-Za-z_][A-Za-z0-9_]*' ;;
        *.py) printf '%s' '^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' ;;
        *.go) printf '%s' '^func[[:space:]]+(\([^)]*\)[[:space:]]*)?[A-Za-z_][A-Za-z0-9_]*' ;;
    esac
}

# Emits one row into $ROWS unless the cap for its relation and changed path (and symbol, for caller and
# test) is spent; counts either way.
emit() { # <relation> <changed> <symbol> <target> <line> <excerpt>
    local key="$1|$2|$3" ex
    local n=${SEEN[$key]:-0}
    SEEN[$key]=$((n + 1))
    if [ "$n" -ge "$CAP" ]; then WITHHELD[$1]=$(( ${WITHHELD[$1]:-0} + 1 )); return; fi
    KEPT[$1]=$(( ${KEPT[$1]:-0} + 1 ))
    ex=$(probe_sanitize "$6"); ex=${ex#"${ex%%[! ]*}"}; ex=${ex%"${ex##*[! ]}"}
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$(probe_sanitize "$2")" "$(probe_sanitize "$3")" \
        "$(probe_sanitize "$4")" "$5" "${ex:--}" >> "$ROWS"
}

# git grep over the head tree; prints path<TAB>line<TAB>text. Exit 1 (no match) is not a failure.
# -z ends the path and the line number with NUL, so a colon in a path cannot shift the fields. tr turns
# each NUL into a tab, because some awk builds read NUL as the end of a record.
ggrep() { # <git grep args...>
    g grep -z -n -I "$@" "$HEAD" -- > "$TMP/gg" 2>/dev/null
    [ $? -le 1 ] || { fail "git grep $*"; return 0; }
    tr '\0' '\t' < "$TMP/gg" | PRE="$HEAD:" awk '{
        pre = ENVIRON["PRE"]; if (index($0, pre) == 1) $0 = substr($0, length(pre) + 1)
        p = index($0, "\t"); path = substr($0, 1, p - 1); rest = substr($0, p + 1)
        q = index(rest, "\t"); print path "\t" substr(rest, 1, q - 1) "\t" substr(rest, q + 1) }'
}

is_test() { case /$1 in */tests/*|*/test/*|*/spec/*|*/__tests__/*) return 0 ;; esac
            case ${1##*/} in test_*|*_test.*|*.test.*|*Test.*|*_spec.*|*.spec.*|*.bats) return 0 ;; esac; return 1; }
in_diff() { grep -qxF -- "$1" "$CHANGED"; }
at_head() { grep -qxF -- "$1" "$TREE"; }

# Prints the enclosing definition name for each line number on stdin, read against <rev>:<path>.
enclosing() { # <rev> <path>
    local want ere; want=$(tr '\n' ' '); ere=$(def_ere "$2")
    [ -n "$ere" ] && [ -n "${want// /}" ] || return 0
    g show "$1:$2" > "$TMP/blob" 2>/dev/null || { fail "git show $1:$2"; return 0; }
    ERE="$ere" awk -v want="$want" '
        BEGIN { ere = ENVIRON["ERE"]; n = split(want, w, " "); for (i = 1; i <= n; i++) need[w[i]] = 1 }
        { if (match($0, ere)) { d = substr($0, RSTART, RLENGTH)
              sub(/^[[:space:]]*(async[[:space:]]+)?(function[[:space:]]+&?|def[[:space:]]+|func[[:space:]]+(\([^)]*\)[[:space:]]*)?)?/, "", d)
              sub(/[^A-Za-z0-9_].*$/, "", d); cur = d }
          if ((NR in need) && cur != "") print cur }' "$TMP/blob" | sort -u
}

# Prints "<old line list>|<new line list>" of removed and added lines in the diff of one path.
hunk_lines() { # <path>
    g diff -U0 --no-renames --no-ext-diff --no-textconv "$BASE" "$HEAD" -- "$1" 2>/dev/null | awk '
        /^@@/ { split($2, o, ","); split($3, nw, ","); os = substr(o[1], 2) + 0; oc = (o[2] == "" ? 1 : o[2] + 0)
                ns = substr(nw[1], 2) + 0; nc = (nw[2] == "" ? 1 : nw[2] + 0)
                for (i = 0; i < oc; i++) old = old " " (os + i); for (i = 0; i < nc; i++) add = add " " (ns + i) }
        END { print old "|" add }'
}

map_file() { # <changed path>
    local c=$1 name=${1##*/} stem dir ext sym t l x rows old add partner tog tot head=1 ere te
    stem=${name%.md}
    at_head "$c" || head=0
    # referenced-by
    local pats=(-e "$c" -e "$name"); [ "$name" != "$stem" ] && pats+=(-e "[[$stem")
    while IFS=$'\t' read -r t l x; do [ "$t" = "$c" ] || emit referenced-by "$c" - "$t" "$l" "$x"
    done < <(ggrep -F "${pats[@]}")
    grep -qxF -- "$c" "$TMP/binary" && return 0
    # references, read from one copy of the changed file
    if [ "$head" -eq 1 ]; then
        g show "$HEAD:$c" > "$TMP/cur" 2>/dev/null || fail "git show $c"
        local d=${c%/*}; [ "$d" = "$c" ] && d=.
        grep -noE "$TOKEN_ERE" "$TMP/cur" | while IFS=: read -r l x; do
            x=${x#./}
            for t in "${x#/}" "$(probe_normalize "$d/${x#/}" 2>/dev/null)"; do
                [ -n "$t" ] && [ "$t" != "$c" ] && at_head "$t" && { printf '%s\t%s\n' "$t" "$l"; break; }
            done
        done | sort -u -t$'\t' -k1,1 | sort -t$'\t' -k2,2n > "$TMP/refs"
        while IFS=$'\t' read -r t l; do emit references "$c" - "$t" "$l" "$(sed -n "${l}p" "$TMP/cur")"; done < "$TMP/refs"
    fi
    # changed symbols, then callers
    : > "$TMP/syms"; ere=$(def_ere "$c")
    if [ -n "$ere" ]; then
        rows=$(hunk_lines "$c"); old=${rows%%|*}; add=${rows#*|}
        { [ "$head" -eq 0 ] || printf '%s\n' $add | enclosing "$HEAD" "$c"; printf '%s\n' $old | enclosing "$BASE" "$c"; } \
            | sort -u > "$TMP/syms"
    fi
    while read -r sym; do
        [ -n "$sym" ] || continue
        while IFS=$'\t' read -r t l x; do
            # A definition of the symbol in a changed file (the file itself, or where a move put it) is no caller.
            te=$(def_ere "$t")
            [ -n "$te" ] && in_diff "$t" && printf '%s' "$x" | grep -qE "$te" && printf '%s' "$x" | grep -qw -- "$sym" && continue
            emit caller "$c" "$sym" "$t" "$l" "$x"
        done < <(ggrep -w -e "$sym")
    done < "$TMP/syms"
    # tests
    if ! is_test "$c"; then
        rows=0
        while IFS=$'\t' read -r t l x; do is_test "$t" && [ "$t" != "$c" ] && { emit test "$c" - "$t" "$l" "$x"; rows=1; }
        done < <(ggrep -F -e "$name")
        [ "$rows" -eq 1 ] || emit test "$c" - none - -
        while read -r sym; do
            [ -n "$sym" ] || continue; rows=0
            while IFS=$'\t' read -r t l x; do is_test "$t" && { emit test "$c" "$sym" "$t" "$l" "$x"; rows=1; }
            done < <(ggrep -w -e "$sym")
            [ "$rows" -eq 1 ] || emit test "$c" "$sym" none - -
        done < "$TMP/syms"
    fi
    # co-change, from the commit log of base
    while IFS=$'\t' read -r _ partner tog tot; do
        in_diff "$partner" || ! at_head "$partner" || emit co-change "$c" - "$partner" - "$tog/$tot"
    done < <(C="$c" awk -F'\t' '$1 == ENVIRON["C"]' "$TMP/pairs")
    # siblings, newest first by the last commit that touched each
    [ "$head" -eq 1 ] || return 0
    dir=${c%/*}; [ "$dir" = "$c" ] && dir=""; ext=${name##*.}; [ "$ext" = "$name" ] && ext=""
    D="$dir" E="$ext" SELF="$c" awk -F'\t' '
        FILENAME == ARGV[1] { if (!($2 in t)) t[$2] = $1; next }
        { p = $0; s = p; sub(/\/[^\/]*$/, "", s); if (s == p) s = ""
          n = p; sub(/^.*\//, "", n); x = (index(n, ".") ? n : ""); sub(/^.*\./, "", x)
          if (s == ENVIRON["D"] && x == ENVIRON["E"] && p != ENVIRON["SELF"]) print (p in t ? t[p] : 0) "\t" p }
    ' "$TMP/lastmod" "$TREE" | sort -t$'\t' -k1,1nr -k2,2 > "$TMP/cand"
    rows=0
    while IFS=$'\t' read -r _ t && [ "$rows" -lt 5 ]; do
        in_diff "$t" && continue; rows=$((rows + 1))
        g show "$HEAD:$t" > "$TMP/sibblob" 2>/dev/null || fail "git show $t"
        ERE="$(def_ere "$t")" F="$t" awk '
            BEGIN { ere = ENVIRON["ERE"]; if (ENVIRON["F"] ~ /\.md$/) ere = "^#{1,6} " }
            ere != "" && $0 ~ ere { print ENVIRON["F"] "\t" NR "\t" $0; found = 1; exit }
            END { if (!found) print ENVIRON["F"] "\t-\t-" }' "$TMP/sibblob"
    done < "$TMP/cand" > "$TMP/sib"
    while IFS=$'\t' read -r t l x; do emit sibling "$c" - "$t" "$l" "$x"; done < "$TMP/sib"
}

cmd_build() {
    local a
    REPO="" BASE="" HEAD=""
    while [ $# -gt 0 ]; do
        [ $# -ge 2 ] || die "$1 needs a value"
        case $1 in --repo) REPO=$2 ;; --base) BASE=$2 ;; --head) HEAD=$2 ;; *) die "unknown option: $1" ;; esac
        shift 2
    done
    [ -n "$REPO" ] && [ -n "$BASE" ] && [ -n "$HEAD" ] || die "build needs --repo, --base and --head"
    g rev-parse --git-dir >/dev/null 2>&1 || die "$REPO is not a git repo"
    for a in "$BASE" "$HEAD"; do
        g rev-parse --verify -q "$a^{commit}" >/dev/null || die "$a is not a commit in $REPO"
    done
    BASE=$(g rev-parse "$BASE^{commit}"); HEAD=$(g rev-parse "$HEAD^{commit}")
    TMP=$(mktemp -d) || die "no temp dir"; trap 'rm -rf "$TMP"' EXIT
    ROWS="$TMP/rows" CHANGED="$TMP/changed" TREE="$TMP/tree"
    : > "$ROWS"; : > "$TMP/failed"; declare -gA SEEN=() KEPT=() WITHHELD=()
    # -z keeps a quote, backslash or tab in a path unquoted; tr then gives one path per line.
    g diff -z --name-only --no-renames "$BASE" "$HEAD" > "$TMP/z" || fail "git diff"; tr '\0' '\n' < "$TMP/z" > "$CHANGED"
    g diff -z --numstat --no-renames "$BASE" "$HEAD" > "$TMP/z" || fail "git diff --numstat"
    tr '\0' '\n' < "$TMP/z" | awk -F'\t' '$1 == "-" { print $3 }' > "$TMP/binary"
    g ls-tree -z -r --name-only "$HEAD" > "$TMP/z" || fail "git ls-tree"; tr '\0' '\n' < "$TMP/z" > "$TREE"
    g log -z --no-renames --format='%x01%ct' --name-only -n "$HISTORY" "$HEAD" > "$TMP/z" || fail "git log $HEAD"
    tr '\0' '\n' < "$TMP/z" > "$TMP/headlog"
    awk '/^\001/ { t = substr($0, 2); next } NF && !($0 in seen) { seen[$0] = 1; print t "\t" $0 }' "$TMP/headlog" > "$TMP/lastmod"
    # pairs: changed<TAB>partner<TAB>together<TAB>commits of changed, support >= 3 and confidence >= 0.5
    g log -z --no-renames --format='%x01' --name-only -n "$HISTORY" "$BASE" > "$TMP/z" || fail "git log $BASE"
    tr '\0' '\n' < "$TMP/z" > "$TMP/baselog"
    MAX="$MAXF" LIST="$CHANGED" awk '
        BEGIN { max = ENVIRON["MAX"] + 0; while ((getline l < ENVIRON["LIST"]) > 0) want[l] = 1 }
        function flush(   i, j) { if (n > 0 && n <= max) for (i = 1; i <= n; i++) if (f[i] in want) {
              tot[f[i]]++; for (j = 1; j <= n; j++) if (j != i) tog[f[i] SUBSEP f[j]]++ }
            n = 0 }
        /^\001/ { flush(); next } NF { f[++n] = $0 }
        END { flush(); for (k in tog) { split(k, p, SUBSEP)
              if (tog[k] >= 3 && tog[k] / tot[p[1]] >= 0.5) print p[1] "\t" p[2] "\t" tog[k] "\t" tot[p[1]] } }
    ' "$TMP/baselog" | sort > "$TMP/pairs"
    while IFS= read -r a; do [ -n "$a" ] && map_file "$a"; done < "$CHANGED"
    cr_redact_runtime < "$ROWS" | awk -F'\t' 'BEGIN { OFS = "\t" } NF { $6 = substr($6, 1, 160); print }'
    local state=complete reason=- counts="" w=0 r
    for r in $RELATIONS; do counts="$counts	$r=${KEPT[$r]:-0}/${WITHHELD[$r]:-0}"; w=$((w + ${WITHHELD[$r]:-0})); done
    [ "$w" -gt 0 ] && state=capped reason="cap $CAP per relation per file, per symbol for caller and test"
    [ -s "$TMP/failed" ] && state=partial reason=$(probe_sanitize "$(head -1 "$TMP/failed") failed")
    printf 'map-status\t%s\t%s%s\n' "$state" "$reason" "$counts"
}

read_map() { # <map> — refuses a map with no status line, a row that is not six fields, or a bad line field
    [ -r "$1" ] || die "cannot read map $1"
    awk -F'\t' '$1 == "map-status" { s = 1; next } NF != 6 || $5 !~ /^([0-9]+|-)$/ { bad = 1 }
        END { exit (s && !bad) ? 0 : 1 }' "$1" \
        || die "malformed map $1: rows must have six fields, a line number or -, and one map-status line"
}

cmd_slice() {
    local map="" persona="" paths="" rels
    while [ $# -gt 0 ]; do
        [ $# -ge 2 ] || die "$1 needs a value"
        case $1 in --map) map=$2 ;; --persona) persona=$2 ;; --paths) paths=$2 ;; *) die "unknown option: $1" ;; esac
        shift 2
    done
    [ -n "$map" ] && [ -n "$persona" ] || die "slice needs --map and --persona"
    read_map "$map"
    [ -r "$persona" ] || die "cannot read persona $persona"
    rels=$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit }
        /^map:[[:space:]]*\[.*\][[:space:]]*$/ { sub(/^map:[[:space:]]*\[/, ""); sub(/\][[:space:]]*$/, ""); gsub(/[ ,]+/, " "); print "@" $0; exit }' "$persona")
    [ -n "$rels" ] || die "persona $persona has no map: key"
    [ -z "$paths" ] || [ -r "$paths" ] || die "cannot read --paths $paths"
    RELS="${rels#@}" PATHS="$paths" CAPB="$SLICE_BYTES" awk -F'\t' '
        BEGIN { n = split(ENVIRON["RELS"], r, " "); for (i = 1; i <= n; i++) want[r[i]] = 1; cap = ENVIRON["CAPB"] + 0
                if (ENVIRON["PATHS"] != "") { while ((getline l < ENVIRON["PATHS"]) > 0) keep[l] = 1; usep = 1 } }
        $1 == "map-status" { print; next }
        !($1 in want) || (usep && !($2 in keep)) { next }
        { if (used + length($0) + 1 > cap) { held++; next } used += length($0) + 1; out[++m] = $0 }
        END { for (i = 1; i <= m; i++) print out[i]; if (held) print "withheld: " held " rows" }' "$map"
}

cmd_status() {
    [ $# -eq 2 ] && [ "$1" = --map ] || die "status needs --map <file>"
    read_map "$2"
    awk -F'\t' '$1 == "map-status" { r = ($3 == "-" ? "" : " " $3); print "map_status: " $2 r
        for (i = 4; i <= NF; i++) { split($i, kv, "="); print "map_" kv[1] ": " kv[2] } }' "$2"
}

case ${1:-} in
    build)  shift; cmd_build "$@" ;;
    slice)  shift; cmd_slice "$@" ;;
    status) shift; cmd_status "$@" ;;
    *) die "usage: change-map.sh build --repo <r> --base <ref> --head <ref> | slice --map <f> --persona <f> [--paths <f>] | status --map <f>" ;;
esac
