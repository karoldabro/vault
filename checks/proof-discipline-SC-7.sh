#!/usr/bin/env bash
# SC-7 — a weak claim is recorded, and a refuted one carries nothing.
#
# The two halves of what a grade permits. A work item resting on a `refuted` claim is refused. A
# claim graded `C` is NOT refused — it is an unverified assumption, and the refusal lands only when
# `## Open & deferred` does not name it. Banning a `C` claim's work items would stall a session on
# its own mechanism, which is why this check proves the softer behaviour rather than the harder one.
#
# Each fixture's `domains` cell must FOLD to the grade in its `grade` cell, or the gate refuses for
# disagreement instead of for the condition under test and the check proves nothing.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
fail=0

[ -x "$gate" ] || { printf '  MISSING  %s\n' "$gate"; exit 1; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# $1 domains cell · $2 grade cell · $3 Open & deferred body · $4 out path
mkplan() {
    {
        printf -- '---\ntype: plan\nstatus: proposed\n---\n# fixture — plan\n\n'
        printf '## Open & deferred\n\n| item | state |\n|------|-------|\n| %s | open |\n\n' "$3"
        printf '## Claims\n\n'
        printf '| id | claim | kind | grounds | warrant | falsifier | domains | grade |\n'
        printf '|----|-------|------|---------|---------|-----------|---------|-------|\n'
        printf '| C-1 | The fixture holds | cmd | `/bin/true` exits 0 | it runs here | `/bin/false` exits 1 | `%s` | %s |\n\n' "$1" "$2"
        printf '## Work items\n\n'
        printf '| id | file (exact path) | action | tool | constraint | rests on | covers | verification | status |\n'
        printf '|----|-------------------|--------|------|------------|----------|--------|--------------|--------|\n'
        printf '| W-1 | README.md | modify | Edit | none | C-1 | SC-1 | none | TODO |\n'
    } > "$4"
}

# (a) a work item resting on a refuted claim: exit 1, naming the claim or the item.
# `-` on resolves is a hard failure, which folds to `refuted`.
mkplan '-++nn' 'refuted' 'nothing outstanding' "$tmp/refuted.md"
out=$("$gate" claims "$tmp/refuted.md" 2>&1); rc=$?
if [ "$rc" -ne 1 ]; then
    printf '  FAIL  a work item resting on a refuted claim exited %s; expected 1\n%s\n' "$rc" "$out"; fail=1
elif ! printf '%s\n' "$out" | grep -qE 'C-1|W-1'; then
    printf '  FAIL  the refusal names neither the claim nor the work item\n%s\n' "$out"; fail=1
fi

# (b) a claim graded C, unnamed in Open & deferred: exit 1.
# `-` on independence is a soft failure, which caps at `C`.
mkplan '+++n-' 'C' 'nothing outstanding' "$tmp/c-unnamed.md"
out=$("$gate" claims "$tmp/c-unnamed.md" 2>&1); rc=$?
[ "$rc" -eq 1 ] || { printf '  FAIL  a C claim absent from Open & deferred exited %s; expected 1\n%s\n' "$rc" "$out"; fail=1; }

# (c) the same claim, named: exit 0, and its work item stands.
mkplan '+++n-' 'C' 'C-1 is an unverified assumption' "$tmp/c-named.md"
out=$("$gate" claims "$tmp/c-named.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] || { printf '  FAIL  a C claim named in Open & deferred exited %s; expected 0\n%s\n' "$rc" "$out"; fail=1; }

# (d) a grade cell that disagrees with the fold: exit 1. Without this, (a) to (c) would pass against
# a gate that reads the grade cell and never recomputes it.
mkplan '+++nn' 'C' 'C-1 is an unverified assumption' "$tmp/disagree.md"
out=$("$gate" claims "$tmp/disagree.md" 2>&1); rc=$?
[ "$rc" -eq 1 ] || { printf '  FAIL  a grade cell disagreeing with the fold exited %s; expected 1\n%s\n' "$rc" "$out"; fail=1; }

[ "$fail" -eq 0 ] || exit 1
printf '  OK  refuted blocks its work item; C is recorded, not banned; a typed grade is recomputed\n'
