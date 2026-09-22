#!/usr/bin/env bash
# sql-schema.sh — checks of SQL schema text: duplicate columns, foreign keys without an index, names,
# and (spec-tables/spec-naming) the same logic run against a draft spec's Data model table.
# Native probe; prints finding rows. Nothing is run against a database. Contract: commands/_shared/probe-kit.md.
#
# Usage:  probes/sql-schema.sh --check sql-dup-columns|sql-fk-index|sql-naming|spec-tables|spec-naming [--repo <root>] [--spec <arch spec>]
# Reads:  the .sql files under database, migrations, db and schema, and schema.sql, or PROBE_SQL (repo relative
#         paths separated by spaces), each up to PROBE_FILE_MAX bytes. The glossary is probes/glossary.tsv of the repo:
#         banned<TAB>preferred. It reads the whole tree, so a change under `diff` is compared with every schema file.
#
# spec-tables/spec-naming: --spec's `## Data model` table (table|column|type|null|key|index|references) is
#         read into the same T/C/K facts real SQL produces (lib/probe-md-table.sh locates the table), each
#         fact tagged `real` or `spec` in its trailing field. `spec-tables` runs the dup-columns/fk-index
#         programs with `spec_mode` on: every keyed structure widens from (table,column) to
#         (table,column,origin), so a spec table sharing a real table's name is compared against it rather
#         than merged with it, and a row prints only when a spec-derived fact contributes to it.
#         `id-column-no-fk` is suppressed under spec_mode (real-SQL-appropriate heuristic, noisy on a draft).
#         `spec-naming` runs the unchanged naming program over spec-origin facts only. Absent `--spec`, or
#         a spec with no Data model table, both print nothing. The plain `sql-dup-columns`/`sql-fk-index`/
#         `sql-naming` checks never set spec_mode and never read a spec — byte-identical to before this.
#
# Exit: 0 clean · 1 findings · 2 usage error

set -uo pipefail
export LC_ALL=C
PROBE_FRAMEWORK=${PROBE_FRAMEWORK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
. "$PROBE_FRAMEWORK/lib/probe-emit.sh"
. "$PROBE_FRAMEWORK/lib/probe-scope.sh"
. "$PROBE_FRAMEWORK/lib/probe-sql.sh"
. "$PROBE_FRAMEWORK/lib/probe-md-table.sh"
probe_native_init "$@"

case $A_CHECK in spec-tables|spec-naming) [ -n "$A_SPEC" ] || exit 0 ;; esac

probe_files "$repo" "$TMP/full" || exit 2

facts="$TMP/facts"; : > "$facts"
while IFS= read -r -d '' f; do
    case $f in *.sql) ;; *) continue ;; esac
    if [ -n "${PROBE_SQL:-}" ]; then
        case " $PROBE_SQL " in *" $f "*) ;; *) continue ;; esac
    else
        case $f in database/*|migrations/*|db/*|schema/*|schema.sql) ;; *) continue ;; esac
    fi
    [ "$(wc -c < "$repo/$f" | tr -d ' ')" -le "${PROBE_FILE_MAX:-2097152}" ] || continue
    sql_facts "$f" "$repo/$f" | LC_ALL=C awk -F'\t' -v OFS='\t' '{ print $0, "real" }' >> "$facts"
done < "$TMP/full"

if [ "$A_CHECK" = spec-tables ] || [ "$A_CHECK" = spec-naming ]; then
    [ -f "$A_SPEC" ] || probe_die "--spec needs a regular file"
    repop=$(cd "$repo" && pwd -P); specp=$(readlink -f "$A_SPEC")
    case $specp in "$repop"/*) sfile=${specp#"$repop"/} ;; *) sfile=$(basename "$specp") ;; esac
    md_table_rows "$A_SPEC" '^## Data model[ \t]*(\(.*\))?[ \t]*$' | LC_ALL=C awk -F'\t' -v sfile="$sfile" '
        NR == 1 {
            for (i = 2; i <= NF; i++) { h = $i
                if (h == "table") ti = i; if (h == "column") ci = i; if (h == "type") yi = i
                if (h == "null") nlz = i; if (h == "key") ki = i; if (h == "index") xi = i; if (h == "references") ri = i }
            if (!ti || !ci || !yi || !nlz || !ki || !xi || !ri) exit
            next }
        {
            ln = $1; tb = $ti; col = $ci; typ = $yi; nul = tolower($nlz); key = toupper($ki); idx = $xi; ref = $ri
            if (tb == "" || col == "") next
            if (!(tb in seen)) { seen[tb] = 1; tdecl[tb] = ln; print "T\t" sfile "\t" tb "\t" ln "\t-\t-\t-\tspec" }
            nn = (nul == "no") ? 1 : 0
            print "C\t" sfile "\t" tb "\t" ln "\t" col "\t" typ "\t" nn "\t" tdecl[tb] "\tspec"
            if (key == "PK" || key == "FK" || key == "UQ") {
                r = (key == "FK" && ref != "") ? ref : "-"
                print "K\t" sfile "\t" tb "\t" ln "\t" col "\t" key "\t" r "\tspec"
            }
            if (idx != "" && idx != "-") print "K\t" sfile "\t" tb "\t" ln "\t" col "\tIX\t-\tspec"
        }
    ' >> "$facts"
fi

[ -s "$facts" ] || exit 0

glossary="$TMP/glossary"; : > "$glossary"
probe_safe_file "$repo" probes/glossary.tsv && grep -v '^[ 	]*#' "$repo/probes/glossary.tsv" > "$glossary"

# The checks read the facts and print: file, line, severity, rule, message. `org` is the fact's
# trailing field ($8 for T/K rows, $9 for C rows — decl stays at C's original $8). spec_mode gates
# both the key width (table,column) -> (table,column,origin) and which rows may print.
dup_prog='
    function norm(t) { return tolower(t) }
    function tk_key(tb, org) { return spec_mode ? norm(tb) SUBSEP org : norm(tb) }
    $1 == "T" { org = $8; tk = tk_key($3, org)
                if (!(tk in tline)) { tord[++nt] = tk; tname[tk] = $3; tline[tk] = $4; tfile[tk] = $2; torg[tk] = org } }
    $1 == "C" { org = $9; tk = tk_key($3, org); ck = tolower($5)
                if ($8 != 0) { dk = $2 SUBSEP tk SUBSEP ck SUBSEP $8
                    if (dk in hd) { if (!spec_mode || org == "spec") print $2 "\t" $4 "\terror\tdup-column-in-table\tcolumn " $5 " appears twice in table " $3 }
                    else hd[dk] = 1 }
                if (!((tk SUBSEP ck) in have)) { have[tk SUBSEP ck] = 1; cols[tk] = cols[tk] " " ck; ncol[tk]++
                    if (ck != "id") { key = ck SUBSEP $6
                        if (!(key in seen)) { seen[key] = 1; nty[ck]++
                            tys[ck] = tys[ck] (tys[ck] == "" ? "" : ", ") $6 " in " $3 (spec_mode ? " (" org ")" : "")
                            if (nty[ck] == 1) { dfile[ck] = $2; dline[ck] = $4 } }
                        if (spec_mode && org == "spec" && !(ck in ckspec)) { dfile[ck] = $2; dline[ck] = $4 }
                        if (org == "spec") ckspec[ck] = 1 } }
              }
    END {
        for (i = 1; i <= nt; i++) { a = tord[i]; na = 0; delete sa; m = split(cols[a], ca, " ")
            for (x = 1; x <= m; x++) if (ca[x] !~ /^(id|created_at|updated_at|deleted_at|inserted_at)$/) { sa[ca[x]] = 1; na++ }
            if (na < 4) continue
            for (j = i + 1; j <= nt; j++) { b = tord[j]; nb = 0; inter = 0; m2 = split(cols[b], cb, " ")
                for (y = 1; y <= m2; y++) if (cb[y] !~ /^(id|created_at|updated_at|deleted_at|inserted_at)$/) { nb++; if (cb[y] in sa) inter++ }
                if (nb < 4) continue
                if (spec_mode && torg[a] != "spec" && torg[b] != "spec") continue
                if (spec_mode && torg[a] != torg[b] && tolower(tname[a]) == tolower(tname[b])) continue
                un = na + nb - inter
                if (inter * 10 >= un * 8) print tfile[b] "\t" tline[b] "\twarn\tdup-column-set\ttables " tname[a] " and " tname[b] " share " inter " of " un " column names" } }
        for (ck in nty) if (nty[ck] > 1 && (!spec_mode || ckspec[ck])) print dfile[ck] "\t" dline[ck] "\twarn\tcolumn-drift\tcolumn " ck " is declared with different types: " tys[ck]
    }'
fk_prog='
    $1 == "K" { org = $8; tk = spec_mode ? tolower($3) SUBSEP org : tolower($3); ck = tolower($5)
                if ($6 == "FK") { fk[++n] = tk SUBSEP ck; ff[n] = $2; fl[n] = $4; fn[n] = $3 "." $5; fo[n] = org }
                else { idx[tk SUBSEP ck] = 1; if ($6 == "PK") pk[tk SUBSEP ck] = 1 } }
    $1 == "C" { org = $9; tk = spec_mode ? tolower($3) SUBSEP org : tolower($3); ck = tolower($5); cc[++nc] = tk SUBSEP ck; cf[nc] = $2; cl[nc] = $4; cn[nc] = $3 "." $5 }
    END {
        for (i = 1; i <= n; i++) { haskey[fk[i]] = 1
            if (!(fk[i] in idx) && (!spec_mode || fo[i] == "spec")) print ff[i] "\t" fl[i] "\terror\tfk-no-index\tforeign key " fn[i] " has no index that starts with that column" }
        if (!spec_mode) for (i = 1; i <= nc; i++) { split(cc[i], p, SUBSEP)
            if (p[2] ~ /._id$/ && !(cc[i] in haskey) && !(cc[i] in pk)) print cf[i] "\t" cl[i] "\tinfo\tid-column-no-fk\tcolumn " cn[i] " ends in _id and has no foreign key" }
    }'
naming_prog='
    BEGIN { while ((getline line < gloss) > 0) { split(line, g, "\t"); if (g[1] != "") ban[tolower(g[1])] = g[2] } }
    function chk(kind, name, file, ln,   k, n, t) {
        if (name !~ /^[a-z][a-z0-9_]*$/) print file "\t" ln "\twarn\tnaming-snake-case\t" kind " " name " is not lower snake_case"
        n = split(tolower(name), t, "_")
        for (k = 1; k <= n; k++) if (t[k] in ban) print file "\t" ln "\twarn\tnaming-glossary\t" kind " " name " uses \"" t[k] "\"; the glossary prefers \"" ban[t[k]] "\""
    }
    $1 == "T" { if (!(($3) in seenT)) { seenT[$3] = 1; chk("table", $3, $2, $4) } }
    $1 == "C" { key = $3 SUBSEP $5; if (!(key in seenC)) { seenC[key] = 1; chk("column", $5, $2, $4) } }'

case $A_CHECK in
    sql-dup-columns) LC_ALL=C awk -F'\t' -v spec_mode=0 "$dup_prog" "$facts" | probe_emit_sorted "$A_CHECK"; exit $? ;;
    sql-fk-index)    LC_ALL=C awk -F'\t' -v spec_mode=0 "$fk_prog"  "$facts" | probe_emit_sorted "$A_CHECK"; exit $? ;;
    sql-naming)      LC_ALL=C awk -F'\t' -v gloss="$glossary" "$naming_prog" "$facts" | probe_emit_sorted "$A_CHECK"; exit $? ;;
    spec-tables)
        { LC_ALL=C awk -F'\t' -v spec_mode=1 "$dup_prog" "$facts"
          LC_ALL=C awk -F'\t' -v spec_mode=1 "$fk_prog"  "$facts"
        } | probe_emit_sorted "$A_CHECK"
        exit $? ;;
    spec-naming)
        LC_ALL=C awk -F'\t' '$NF == "spec"' "$facts" | LC_ALL=C awk -F'\t' -v gloss="$glossary" "$naming_prog" | probe_emit_sorted "$A_CHECK"
        exit $? ;;
    *) probe_die "unknown check: $A_CHECK" ;;
esac
