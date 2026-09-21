#!/usr/bin/env bash
# harness.sh — checks of instruction files (commands, templates, notes): broken links, files no other file
# mentions, and file size. Native probe; prints finding rows. Contract: commands/_shared/probe-kit.md.
#
# Usage:  probes/harness.sh --check md-links|dead-files|token-size [--repo <root>]
# Env:    PROBE_REPO, PROBE_FILES (the file list the core exports), PROBE_TOKEN_MAX (6000),
#         PROBE_FILE_MAX (2097152 bytes: a larger markdown file is not scanned),
#         PROBE_DEAD_DIRS (commands lib bin templates personas arch-profiles hooks scripts checks)
#
# Exit: 0 clean · 1 findings · 2 usage error

set -uo pipefail
export LC_ALL=C
PROBE_FRAMEWORK=${PROBE_FRAMEWORK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
. "$PROBE_FRAMEWORK/lib/probe-emit.sh"
. "$PROBE_FRAMEWORK/lib/probe-scope.sh"
probe_native_init "$@"
dirs=${PROBE_DEAD_DIRS:-commands lib bin templates personas arch-profiles hooks scripts checks}
found=0

emit() { probe_finding "$A_CHECK" "$@"; found=1; }

in_dirs() { local d; for d in $dirs; do case $1 in "$d"/*) return 0 ;; esac; done; return 1; }

small_enough() { [ "$(wc -c < "$repo/$1" | tr -d ' ')" -le "${PROBE_FILE_MAX:-2097152}" ]; }

# resolves <dir of the linking file> <target> <L|W> — 0 the target exists, 1 it does not, 2 it leaves the repo.
# A wikilink is tried beside the linking file and in every folder above it up to the repo root, with and
# without `.md`.
resolves() {
    local dir=$1 t=$2 kind=$3 p norm d
    if [ "$kind" = L ]; then
        case $t in /*) p=${t#/} ;; *) p="$dir/$t" ;; esac
        norm=$(probe_normalize "$p") || return 2
        [ -e "$repo/$norm" ]; return
    fi
    d=$dir
    while :; do
        norm=$(probe_normalize "$d/$t") && { [ -e "$repo/$norm" ] || [ -e "$repo/$norm.md" ]; } && return 0
        [ "$d" = . ] && break
        case $d in */*) d=${d%/*} ;; *) d=. ;; esac
    done
    return 1
}

check_links() {
    local f kind ln t dir rc
    while IFS= read -r -d '' f; do
        case $f in *.md) ;; *) continue ;; esac
        small_enough "$f" || continue
        dir=$(dirname "$f")
        while IFS=$'\t' read -r kind ln t; do
            if [ "$kind" = W ]; then
                t=${t%%\\|*}; t=${t%%|*}; t=${t%%#*}
                case $t in */*) ;; *) continue ;; esac
            else
                if [[ $t =~ ^[A-Za-z][A-Za-z0-9+.-]*: ]] || [[ $t == //* ]]; then continue; fi
                t=${t%%#*}; t=${t%%\?*}; t=${t//%20/ }
            fi
            case $t in ''|*'<'*|*'{'*|*'$'*|*'*'*) continue ;; esac
            resolves "$dir" "$t" "$kind"; rc=$?
            [ "$rc" -eq 0 ] && continue
            if [ "$rc" -eq 2 ]; then emit "$f" "$ln" error broken-link "link leaves the repository: $t"
            elif [ "$kind" = W ]; then emit "$f" "$ln" warn broken-wikilink "wikilink target not found: $t"
            else emit "$f" "$ln" error broken-link "link target not found: $t"; fi
        done < <(LC_ALL=C awk '
            /^ ? ? ?(```|~~~)/ { fence = !fence; next }
            fence { next }
            { s = $0; gsub(/`[^`]*`/, "", s)
              while ((i = index(s, "](")) > 0) {
                  s = substr(s, i + 2); d = 1; t = ""
                  for (j = 1; j <= length(s); j++) { c = substr(s, j, 1); if (c == "(") d++; else if (c == ")") { d--; if (d == 0) break }; t = t c }
                  if (d != 0) break
                  s = substr(s, j + 1); sub(/[ \t].*$/, "", t)
                  if (t != "") print "L\t" NR "\t" t
              }
              s = $0; gsub(/`[^`]*`/, "", s)
              while ((i = index(s, "[[")) > 0) {
                  s = substr(s, i + 2); j = index(s, "]]"); if (j == 0) break
                  print "W\t" NR "\t" substr(s, 1, j - 1); s = substr(s, j + 2)
              }
            }' < "$repo/$f")
    done < "$LIST"
}

check_tokens() {
    local f bytes max=$(( ${PROBE_TOKEN_MAX:-6000} * 4 ))
    while IFS= read -r -d '' f; do
        case $f in *.md) ;; *) continue ;; esac
        in_dirs "$f" || continue
        bytes=$(wc -c < "$repo/$f" | tr -d ' ')
        [ "$bytes" -gt "$max" ] && emit "$f" 0 warn large-file "about $((bytes / 4)) tokens (bytes divided by 4), the limit is ${PROBE_TOKEN_MAX:-6000}"
    done < "$LIST"
    return 0
}

check_dead() {
    local f base full="$TMP/full" cands="$TMP/cands"
    probe_files "$repo" "$full" || exit 2
    tok=$RANDOM$RANDOM$RANDOM
    : > "$cands"
    while IFS= read -r -d '' f; do
        case $f in *.md|*.sh) ;; *) continue ;; esac
        in_dirs "$f" || continue
        base=${f##*/}
        case $base in README.md|CLAUDE.md|_*|install.sh|setup.sh) continue ;; esac
        case $f in hooks/*) continue ;; commands/*/*) ;; commands/*) continue ;; esac
        printf '%s\n' "$f" >> "$cands"
    done < "$LIST"
    [ -s "$cands" ] || return 0
    while IFS= read -r -d '' f; do
        case ${f##*/} in *.md|*.sh|*.tsv|*.txt|*.json|*.yml|*.yaml|*.toml|*.html|*.js|*.ts|*.py|*.php|*.bats|*.mk|Makefile) ;; *) continue ;; esac
        small_enough "$f" || continue
        printf '\033@@%s\t%s\n' "$tok" "$f"
        cat "$repo/$f"
        printf '\n'
    done < "$full" | LC_ALL=C awk -v cands="$cands" -v mk="$tok" '
        function note(w) { if (length(w) < 3) return; if (!(w in ref)) ref[w] = cur; else if (ref[w] != cur) other[w] = 1 }
        BEGIN { while ((getline line < cands) > 0) cand[line] = 1 }
        substr($0, 1, 1) == "\033" && index($0, "@@" mk "\t") == 2 { cur = substr($0, 5 + length(mk) + 1); next }
        { s = $0
          while (match(s, /[A-Za-z0-9_.\/-]+/)) {
              tok = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
              sub(/^.*\//, "", tok); sub(/[.]+$/, "", tok)
              note(tok); sub(/\.[A-Za-z0-9]+$/, "", tok); note(tok)
          } }
        END { for (c in cand) { b = c; sub(/^.*\//, "", b); s = b; sub(/\.[A-Za-z0-9]+$/, "", s)
                if ((!(b in ref) || (ref[b] == c && !(b in other))) && (!(s in ref) || (ref[s] == c && !(s in other)))) print c "\t0\tinfo\tunreferenced-file\tno other file mentions " b } }
    ' | probe_emit_sorted "$A_CHECK" || found=1
}

case $A_CHECK in
    md-links) check_links ;;
    token-size) check_tokens ;;
    dead-files) check_dead ;;
    *) probe_die "unknown check: $A_CHECK" ;;
esac
[ "$found" -eq 0 ] || exit 1
exit 0
