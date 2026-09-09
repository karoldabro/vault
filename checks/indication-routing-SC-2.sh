#!/usr/bin/env bash
# SC-2 — a verdict whose anchor does not resolve counts the rule unchecked.
#
# Three ways an anchor fails, each proven against the real cr_anchor_check rather than against a
# description of it: a token absent from the named line, a line outside every hunk, and a path the
# diff never touched. A grep for the function name would pass on a stub.
#
# Output is captured before it is matched. cr_anchor_check returns 1 when it finds a bad anchor —
# that is the success case here — so piping it into grep under `set -o pipefail` would read the
# function working correctly as the check failing.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lib="$root/lib/cr-helpers.sh"
TAB=$(printf '\t')

[ -r "$lib" ] || { printf '  MISSING  %s\n' "$lib"; exit 1; }
# shellcheck source=/dev/null
. "$lib"

for fn in cr_anchor_check cr_rule_coverage; do
    command -v "$fn" >/dev/null 2>&1 || { printf '  MISSING  %s is not defined in %s\n' "$fn" "$lib"; exit 1; }
done

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

printf 'lib/cr-helpers.sh\t2\t0\n' > "$tmp/changed"
cat > "$tmp/diff" <<'DIFF'
--- a/lib/cr-helpers.sh
+++ b/lib/cr-helpers.sh
@@ -10,0 +11,2 @@
+cr_rule_route() {
+    local index="${1:-}"
DIFF

fail=0
note() { printf '  FAIL  %s\n' "$1"; fail=1; }

rejects() {  # <receipt-file> <description>
    local out
    out=$(cr_anchor_check "$tmp/diff" "$1")
    case "$out" in
        bad-anchor*) : ;;
        *) note "$2" ;;
    esac
}

# 1. the quoted token is not on the line it names
printf 'holds\tlib/cr-helpers.sh:L11:"cr_anchor_check"\tautomated-cr-safety\n' > "$tmp/r1"
rejects "$tmp/r1" 'a token absent from the named line was accepted'

# 2. the line is outside every hunk
printf 'holds\tlib/cr-helpers.sh:L900:"cr_rule_route() {"\tautomated-cr-safety\n' > "$tmp/r2"
rejects "$tmp/r2" 'a line outside every hunk was accepted'

# 3. the path the diff never touched
printf 'holds\tbin/doc-lint.sh:L11:"cr_rule_route() {"\tautomated-cr-safety\n' > "$tmp/r3"
rejects "$tmp/r3" 'a path the diff never touched was accepted'

# 4. an all-n/a receipt cannot reach full coverage
printf 'n/a\tthe rule fires on a migration; none changed\tautomated-cr-safety\n' > "$tmp/r4"
out=$(cr_anchor_check "$tmp/diff" "$tmp/r4")
[ -n "$out" ] && note 'a well-formed n/a trigger clause was rejected'

# 5. a well-formed anchor survives
printf 'holds\tlib/cr-helpers.sh:L11:"cr_rule_route() {"\tautomated-cr-safety\n' > "$tmp/r5"
out=$(cr_anchor_check "$tmp/diff" "$tmp/r5")
[ -n "$out" ] && note 'a well-formed anchor was rejected'

# 6. a bad-anchor row counts its rule unchecked, verdict notwithstanding
printf 'applies\tautomated-cr-safety\tlib/cr-helpers.sh\n' > "$tmp/routes"
cr_anchor_check "$tmp/diff" "$tmp/r1" > "$tmp/bad"
out=$(cr_rule_coverage "$tmp/routes" "$tmp/r1" "$tmp/bad")
case "$out" in
    *"routed-unchecked${TAB}1"*) : ;;
    *) note 'a slug with a bad anchor was counted as checked' ;;
esac

[ "$fail" -eq 0 ] && printf '  OK  every unresolvable anchor counts its rule unchecked\n'
exit "$fail"
