#!/usr/bin/env bash
# similar-symbols.sh — finds existing functions whose names overlap something a plan says is new.
# Native probe; prints finding rows. It reads source text and never runs it. Contract:
# commands/_shared/probe-kit.md.
#
# Usage:  probes/similar-symbols.sh --check similar-symbols|spec-symbols [--repo <root>] [--spec <arch spec>] [--names a,b]
# With a spec, each `new` row of its Reuse map is a need. With --names, each comma separated phrase is a need.
# A need and a symbol overlap when they share a word (get, set, is, has, a, an, the, of, to, and, for, new
# do not count) or when one word is the start of the other and both have four letters or more.
# Without a need it reports symbols in different files that are made of the same words.
# Languages: sh, php, py, go, js, ts, vue. Dart is not read.
# The check spec-symbols reads the Reuse map of the spec and never scans the tree: for each row with decision reuse or extend it
# splits the existing-symbol cell on whitespace and commas. The first token with a `/` is a path that must exist inside the repo,
# and each later identifier must occur as a whole word in that file. A cell with no path token is skipped. The row's file is the
# spec's path in the repo, or its base name when the spec lies outside it. Rules: reuse-path-missing, reuse-symbol-missing.
#
# Exit: 0 clean · 1 findings · 2 usage error

set -uo pipefail
export LC_ALL=C
PROBE_FRAMEWORK=${PROBE_FRAMEWORK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
. "$PROBE_FRAMEWORK/lib/probe-emit.sh"
. "$PROBE_FRAMEWORK/lib/probe-scope.sh"
probe_native_init "$@"

if [ "$A_CHECK" = spec-symbols ]; then
    [ -n "$A_SPEC" ] || exit 0
    repop=$(cd "$repo" && pwd -P); specp=$(readlink -f "$A_SPEC")
    case $specp in "$repop"/*) sfile=${specp#"$repop"/} ;; *) sfile=$(basename "$specp") ;; esac
    rows="$TMP/spec-rows"; found="$TMP/spec-found"; : > "$found"
    [ -f "$A_SPEC" ] || probe_die "--spec needs a regular file"
    LC_ALL=C tr -d '\r' < "$A_SPEC" | LC_ALL=C awk -F'|' '
        $0 ~ /^## Reuse map[ \t]*(\(.*\))?[ \t]*$/ { on = 1; next }
        on && /^## / { exit }
        on && /^\|/ {
            line = $0; gsub(/\\\|/, "\001", line)
            if (!hdr) { n = split(line, c, "|")
                for (i = 1; i <= n; i++) { h = tolower(c[i]); gsub(/^[ \t]+|[ \t]+$/, "", h); gsub(/_/, " ", h); if (h == "existing symbol") si = i; if (h == "decision") di = i }
                hdr = 1; if (!si || !di) { print NR "\t\001unreadable"; exit }
                next }
            if (line ~ /^\|[- |:]*\|$/) next
            n = split(line, c, "|"); dc = tolower(c[di]); sc = c[si]
            gsub(/^[ \t]+|[ \t]+$/, "", dc); gsub(/^[ \t]+|[ \t]+$/, "", sc); gsub(/[*`]/, "", dc); gsub(/\001/, "|", sc)
            if (dc == "reuse" || dc == "extend") print NR "\t" sc }
    ' > "$rows"
    set -f
    while IFS=$'\t' read -r ln cell; do
        path="" syms=""
        if [ "$cell" = $'\001unreadable' ]; then printf '%s\t%s\twarn\treuse-map-unreadable\tthe Reuse map has no decision column or no existing symbol column\n' "$sfile" "$ln" >> "$found"; continue; fi
        for tok in $(printf '%s' "$cell" | LC_ALL=C tr '`,;' '   '); do
            while [ "${tok%.}" != "$tok" ]; do tok=${tok%.}; done
            [ -n "$tok" ] || continue
            if [ -z "$path" ]; then
                case $tok in */*) path=${tok#./}; path=${path%%#L[0-9]*}; path=${path%:}; path=$(printf '%s' "$path" | sed 's/:[0-9][0-9]*$//') ;; esac
            elif [ "${#tok}" -le 200 ] && [[ $tok =~ ^[A-Za-z_][A-Za-z0-9_]+$ ]]; then syms="$syms $tok"; fi
        done
        [ -n "$path" ] || continue
        case /$path/ in /../*|*/../*|//*) printf '%s\t%s\terror\treuse-path-missing\tpath %s leaves the repo\n' "$sfile" "$ln" "$path" >> "$found"; continue ;; esac
        target="$repop/$path"; real=$(readlink -f -- "$target" 2>/dev/null || true)
        case $real in "$repop"/*|"$repop") ;; *) [ ! -e "$target" ] || real="" ;; esac
        if [ -z "$real" ] || [ ! -e "$real" ]; then printf '%s\t%s\terror\treuse-path-missing\tpath %s does not exist in the repo\n' "$sfile" "$ln" "$path" >> "$found"; continue; fi
        probe_safe_file "$repop" "$path" || continue
        [ "$(wc -c < "$target" | tr -d ' ')" -le "${PROBE_FILE_MAX:-2097152}" ] || continue
        for sym in $syms; do
            grep -qwF -- "$sym" "$target" || printf '%s\t%s\terror\treuse-symbol-missing\tsymbol %s does not occur in %s\n' "$sfile" "$ln" "$sym" "$path" >> "$found"
        done
    done < "$rows"
    set +f
    probe_emit_sorted "$A_CHECK" < "$found"
    exit $?
fi

probe_files "$repo" "$TMP/full" || exit 2

needs="$TMP/needs"; : > "$needs"
[ -z "$A_NAMES" ] || printf '%s\n' "$A_NAMES" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' >> "$needs"
if [ -n "$A_SPEC" ]; then
    LC_ALL=C awk -F'|' '
        $0 == "## Reuse map" { on = 1; next }
        on && /^## / { exit }
        on && /^\|/ {
            if (!hdr) { n = split($0, c, "|")
                for (i = 1; i <= n; i++) { h = c[i]; gsub(/^[ \t]+|[ \t]+$/, "", h); if (tolower(h) == "need") ni = i; if (tolower(h) == "decision") di = i }
                hdr = 1; next }
            if ($0 ~ /^\|[- |:]*\|$/) next
            n = split($0, c, "|"); nd = c[ni]; dc = c[di]
            gsub(/^[ \t]+|[ \t]+$/, "", nd); gsub(/^[ \t]+|[ \t]+$/, "", dc)
            if (dc == "new" && nd != "") print nd }
    ' "$A_SPEC" >> "$needs"
fi

symbols="$TMP/symbols"; : > "$symbols"
while IFS= read -r -d '' f; do
    ext=${f##*.}
    case $ext in sh|php|py|go|js|ts|vue) ;; *) continue ;; esac
    case "/$f" in */node_modules/*|*/vendor/*|*/dist/*|*/build/*|*/tests/*|*/test/*|*/fixtures/*) continue ;; esac
    [ "$(wc -c < "$repo/$f" | tr -d ' ')" -le "${PROBE_FILE_MAX:-2097152}" ] || continue
    PROBE_SYM_FILE=$f LC_ALL=C awk -v ext="$ext" '
        function ident(s) { if (match(s, /^[A-Za-z_$][A-Za-z0-9_$]*/)) return substr(s, 1, RLENGTH); return "" }
        { l = $0; name = ""
          if (ext == "sh") {
              if (match(l, /^[ \t]*function[ \t]+/)) name = ident(substr(l, RLENGTH + 1))
              else if (match(l, /^[ \t]*[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)/)) { name = l; sub(/^[ \t]*/, "", name); sub(/[ \t]*\(\).*$/, "", name) } }
          else if (ext == "py") { if (match(l, /^[ \t]*(async[ \t]+)?def[ \t]+/)) name = ident(substr(l, RLENGTH + 1)) }
          else if (ext == "php") { if (match(l, /function[ \t]+&?/)) name = ident(substr(l, RSTART + RLENGTH)) }
          else if (ext == "go") { if (match(l, /^func[ \t]+(\([^)]*\)[ \t]*)?/)) name = ident(substr(l, RLENGTH + 1)) }
          else {
              if (match(l, /function[ \t]*\*?[ \t]*/)) name = ident(substr(l, RSTART + RLENGTH))
              else if (match(l, /(const|let|var)[ \t]+[A-Za-z_$][A-Za-z0-9_$]*[ \t]*=[ \t]*(async[ \t]*)?(\(|function|[A-Za-z_$][A-Za-z0-9_$]*[ \t]*=>)/)) { t = l; sub(/^.*(const|let|var)[ \t]+/, "", t); name = ident(t) } }
          if (length(name) >= 3) print ENVIRON["PROBE_SYM_FILE"] "\t" FNR "\t" name }
    ' < "$repo/$f" >> "$symbols"
done < "$TMP/full"
[ -s "$symbols" ] || exit 0
[ -z "$A_SPEC$A_NAMES" ] || [ -s "$needs" ] || exit 0

LC_ALL=C awk -F'\t' -v nf="$needs" '
    function tokens(n,   out, i, c, cur) {
        out = ""; cur = ""
        for (i = 1; i <= length(n); i++) {
            c = substr(n, i, 1)
            if (c ~ /[A-Z]/ && cur ~ /[a-z0-9]$/) { out = out " " cur; cur = "" }
            if (c ~ /[A-Za-z0-9]/) cur = cur tolower(c)
            else { if (cur != "") out = out " " cur; cur = "" }
        }
        if (cur != "") out = out " " cur
        return out
    }
    function clean(t,   n, a, i, out) {
        n = split(t, a, " "); out = ""
        for (i = 1; i <= n; i++) if (length(a[i]) >= 2 && index(" get set is has a an the of to and for new in on by at from ", " " a[i] " ") == 0) out = out " " a[i]
        return out
    }
    function overlap(x, y,   nx, ny, ax, ay, i, j) {
        nx = split(x, ax, " "); ny = split(y, ay, " ")
        for (i = 1; i <= nx; i++) for (j = 1; j <= ny; j++) {
            if (ax[i] == ay[j]) return ax[i]
            if (length(ax[i]) >= 4 && length(ay[j]) >= 4 && (index(ax[i], ay[j]) == 1 || index(ay[j], ax[i]) == 1)) return ax[i] "/" ay[j]
        }
        return ""
    }
    function sortwords(t,   n, a, i, j, x) {
        n = split(t, a, " ")
        for (i = 2; i <= n; i++) { x = a[i]; for (j = i - 1; j >= 1 && a[j] > x; j--) a[j + 1] = a[j]; a[j + 1] = x }
        t = ""; for (i = 1; i <= n; i++) t = t " " a[i]; return t
    }
    FILENAME == nf { nn++; need[nn] = $0; ntok[nn] = clean(tokens($0)); next }
    { st = clean(tokens($3))
      if (nn > 0) {
          for (k = 1; k <= nn; k++) if (count[k] < 10) { w = overlap(ntok[k], st)
              if (w != "") { count[k]++; print $1 "\t" $2 "\twarn\tsimilar-symbol\texisting " $3 " shares the word " w " with the planned need \"" need[k] "\"" } }
      } else if (split(st, tmpa, " ") >= 2) {
          key = sortwords(st)
          if (key in first) { split(first[key], fp, "\t"); if (fp[1] != $1 && emitted < 200) { emitted++; print $1 "\t" $2 "\twarn\tduplicate-symbol-tokens\t" $3 " is made of the same words as " fp[3] " at " fp[1] ":" fp[2] } }
          else first[key] = $1 "\t" $2 "\t" $3
      } }
' "$needs" "$symbols" | probe_emit_sorted "$A_CHECK"
exit $?
