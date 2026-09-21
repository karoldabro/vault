#!/usr/bin/env bash
# sql-schema.sh — checks of SQL schema text: duplicate columns, foreign keys without an index, names.
# Native probe; prints finding rows. Nothing is run against a database. Contract: commands/_shared/probe-kit.md.
#
# Usage:  probes/sql-schema.sh --check sql-dup-columns|sql-fk-index|sql-naming [--repo <root>]
# Reads:  the .sql files under database, migrations, db and schema, and schema.sql, or PROBE_SQL (repo relative
#         paths separated by spaces), each up to PROBE_FILE_MAX bytes. The glossary is probes/glossary.tsv of the repo:
#         banned<TAB>preferred. It reads the whole tree, so a change under `diff` is compared with every schema file.
#
# Exit: 0 clean · 1 findings · 2 usage error

set -uo pipefail
export LC_ALL=C
PROBE_FRAMEWORK=${PROBE_FRAMEWORK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
. "$PROBE_FRAMEWORK/lib/probe-emit.sh"
. "$PROBE_FRAMEWORK/lib/probe-scope.sh"
. "$PROBE_FRAMEWORK/lib/probe-sql.sh"
probe_native_init "$@"
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
    sql_facts "$f" "$repo/$f" >> "$facts"
done < "$TMP/full"
[ -s "$facts" ] || exit 0

glossary="$TMP/glossary"; : > "$glossary"
probe_safe_file "$repo" probes/glossary.tsv && grep -v '^[ 	]*#' "$repo/probes/glossary.tsv" > "$glossary"

# The checks read the facts and print: file, line, severity, rule, message.
case $A_CHECK in
    sql-dup-columns) prog='
        function norm(t) { return tolower(t) }
        $1 == "T" { tk = norm($3); if (!(tk in tline)) { tord[++nt] = tk; tname[tk] = $3; tline[tk] = $4; tfile[tk] = $2 } }
        $1 == "C" { tk = norm($3); ck = tolower($5)
                    if ($8 != 0) { dk = $2 SUBSEP tk SUBSEP ck SUBSEP $8; if (dk in hd) print $2 "\t" $4 "\terror\tdup-column-in-table\tcolumn " $5 " appears twice in table " $3; else hd[dk] = 1 }
                    if (!((tk SUBSEP ck) in have)) { have[tk SUBSEP ck] = 1; cols[tk] = cols[tk] " " ck; ncol[tk]++
                        if (ck != "id") { key = ck SUBSEP $6; if (!(key in seen)) { seen[key] = 1; nty[ck]++; tys[ck] = tys[ck] (tys[ck] == "" ? "" : ", ") $6 " in " $3; if (nty[ck] == 1) { dfile[ck] = $2; dline[ck] = $4 } } } }
                  }
        END {
            for (i = 1; i <= nt; i++) { a = tord[i]; na = 0; delete sa; m = split(cols[a], ca, " ")
                for (x = 1; x <= m; x++) if (ca[x] !~ /^(id|created_at|updated_at|deleted_at|inserted_at)$/) { sa[ca[x]] = 1; na++ }
                if (na < 4) continue
                for (j = i + 1; j <= nt; j++) { b = tord[j]; nb = 0; inter = 0; m2 = split(cols[b], cb, " ")
                    for (y = 1; y <= m2; y++) if (cb[y] !~ /^(id|created_at|updated_at|deleted_at|inserted_at)$/) { nb++; if (cb[y] in sa) inter++ }
                    if (nb < 4) continue
                    un = na + nb - inter
                    if (inter * 10 >= un * 8) print tfile[b] "\t" tline[b] "\twarn\tdup-column-set\ttables " tname[a] " and " tname[b] " share " inter " of " un " column names" } }
            for (ck in nty) if (nty[ck] > 1) print dfile[ck] "\t" dline[ck] "\twarn\tcolumn-drift\tcolumn " ck " is declared with different types: " tys[ck]
        }' ;;
    sql-fk-index) prog='
        $1 == "K" { tk = tolower($3); ck = tolower($5)
                    if ($6 == "FK") { fk[++n] = tk SUBSEP ck; ff[n] = $2; fl[n] = $4; fn[n] = $3 "." $5 }
                    else { idx[tk SUBSEP ck] = 1; if ($6 == "PK") pk[tk SUBSEP ck] = 1 } }
        $1 == "C" { tk = tolower($3); ck = tolower($5); cc[++nc] = tk SUBSEP ck; cf[nc] = $2; cl[nc] = $4; cn[nc] = $3 "." $5 }
        END {
            for (i = 1; i <= n; i++) { haskey[fk[i]] = 1; if (!(fk[i] in idx)) print ff[i] "\t" fl[i] "\terror\tfk-no-index\tforeign key " fn[i] " has no index that starts with that column" }
            for (i = 1; i <= nc; i++) { split(cc[i], p, SUBSEP)
                if (p[2] ~ /._id$/ && !(cc[i] in haskey) && !(cc[i] in pk)) print cf[i] "\t" cl[i] "\tinfo\tid-column-no-fk\tcolumn " cn[i] " ends in _id and has no foreign key" }
        }' ;;
    sql-naming) prog='
        BEGIN { while ((getline line < gloss) > 0) { split(line, g, "\t"); if (g[1] != "") ban[tolower(g[1])] = g[2] } }
        function chk(kind, name, file, ln,   k, n, t) {
            if (name !~ /^[a-z][a-z0-9_]*$/) print file "\t" ln "\twarn\tnaming-snake-case\t" kind " " name " is not lower snake_case"
            n = split(tolower(name), t, "_")
            for (k = 1; k <= n; k++) if (t[k] in ban) print file "\t" ln "\twarn\tnaming-glossary\t" kind " " name " uses \"" t[k] "\"; the glossary prefers \"" ban[t[k]] "\""
        }
        $1 == "T" { if (!(($3) in seenT)) { seenT[$3] = 1; chk("table", $3, $2, $4) } }
        $1 == "C" { key = $3 SUBSEP $5; if (!(key in seenC)) { seenC[key] = 1; chk("column", $5, $2, $4) } }' ;;
    *) probe_die "unknown check: $A_CHECK" ;;
esac

LC_ALL=C awk -F'\t' -v gloss="$glossary" "$prog" "$facts" | probe_emit_sorted "$A_CHECK"
exit $?
