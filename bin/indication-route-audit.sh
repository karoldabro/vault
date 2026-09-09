#!/usr/bin/env bash
# indication-route-audit.sh — show which of a project's indications a code review can reach.
#
# A rule is reachable when its Applies-to cell names a file glob, or a surface the project declared
# in VAULT.md `indication_scopes`. A cell holding only prose ("queue jobs", "all controllers") can be
# routed by nothing, so no review will ever assign it to a critic. This lists those rows so they can
# be repaired; inside a review the same rows are reported and never gate.
#
# It measures the index, not the rules: a listed slug is unreachable, not wrong.
#
# Usage:  bin/indication-route-audit.sh <index.md> [changed-files.tsv]
#         bin/indication-route-audit.sh --help
#
# With no changed-file list, every glob-shaped row counts as routable. With one, the output also
# separates the rows that reach a changed path from the rows that reach nothing in this diff.
#
# Exit 0 every row is reachable · 1 some row is unroutable · 2 bad input.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(dirname "$here")

usage() { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

case "${1:-}" in
    -h|--help|'') usage; [ -n "${1:-}" ] && exit 0 || exit 2 ;;
esac

index="$1"
changed="${2:-}"

[ -r "$index" ] || { printf 'no readable index at %s\n' "$index" >&2; exit 2; }

# shellcheck source=/dev/null
. "$root/lib/cr-helpers.sh" || exit 2

tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

if [ -n "$changed" ]; then
    [ -r "$changed" ] || { printf 'no readable changed-file list at %s\n' "$changed" >&2; exit 2; }
else
    : > "$tmp/changed"
    changed="$tmp/changed"
fi

# The project's declared surfaces, when its VAULT.md names any: a cell holding one of those is
# routable on the surface channel even though it is not a glob.
scopes=""
vault_md=""
for candidate in "$(dirname "$index")/../VAULT.md" "$(dirname "$index")/../../VAULT.md"; do
    [ -r "$candidate" ] && { vault_md="$candidate"; break; }
done
if [ -n "$vault_md" ]; then
    # Both YAML spellings. Reading only the inline list gives a project that writes a block list an
    # empty scope set with no warning, and every surface-routed rule then reports as unroutable —
    # the audit's headline verdict flips on a formatting choice.
    scopes=$(awk '
        /^[[:space:]]*indication_scopes:[[:space:]]*\[/ {
            line = $0
            sub(/^[^[]*\[/, "", line); sub(/\].*$/, "", line)
            printf "%s", line; exit
        }
        /^[[:space:]]*indication_scopes:[[:space:]]*$/ { block = 1; next }
        block && /^[[:space:]]*-[[:space:]]*[^[:space:]]/ {
            v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v)
            printf "%s%s", (n++ ? "," : ""), v; next
        }
        block { exit }
    ' "$vault_md" | tr -d ' "'"'"'' )
fi

cr_rule_route "$index" "$changed" "$scopes" > "$tmp/routes" 2> "$tmp/err"
rc=$?
if [ "$rc" -eq 2 ]; then
    cat "$tmp/err" >&2
    exit 2
fi

applies=$(grep -c '^applies' "$tmp/routes")
nomatch=$(grep -c '^no-match' "$tmp/routes")
unrout=$(grep -c '^unroutable' "$tmp/routes")
rows=$((applies + nomatch + unrout))

printf 'index\t%s\n' "$index"
[ -n "$scopes" ] && printf 'scopes\t%s\n' "$scopes"
printf 'rows\t%d\n'        "$rows"
printf 'routable\t%d\n'    "$((applies + nomatch))"
printf 'unroutable\t%d\n'  "$unrout"
[ -s "$changed" ] && printf 'reaches-this-diff\t%d\n' "$applies"

grep '^unroutable' "$tmp/routes" | cut -f2 | sort | while IFS= read -r slug; do
    [ -n "$slug" ] && printf 'unroutable\t%s\n' "$slug"
done

exit "$rc"
