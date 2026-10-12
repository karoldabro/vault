#!/usr/bin/env bash
# SC-1 of vault/plans/2026-10-12-0944-v-pm-planning-loop.md — the planning persona group.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
d="$root/personas/_shared/planning"
fail() { printf '%s\n' "$*"; exit 1; }
[ -d "$d" ] || fail "personas/_shared/planning/ does not exist"
[ -f "$d/README.md" ] || fail "the planning group has no README.md"
for id in solution-architect codebase-fit lazy-dev future-scope system-integration security-architect harness-engineer delivery-planner; do
    f="$d/$id.md"
    [ -f "$f" ] || fail "missing lens $id.md"
    n=$(wc -l < "$f"); [ "$n" -le 150 ] || fail "$id.md has $n lines, cap 150"
    grep -q '^type: persona$' "$f" || fail "$id.md frontmatter lacks type: persona"
    grep -q "^id: $id\$" "$f" || fail "$id.md frontmatter lacks id: $id"
    grep -q '^base_agent: ' "$f" || fail "$id.md has no base_agent"
    for s in Mandate 'Bound analyzer' 'Severity rubric' Checklist Scale Output; do
        grep -q "^## $s" "$f" || fail "$id.md has no ## $s section"
    done
    grep -q "$id" "$d/README.md" || fail "README.md does not list $id"
done
n=$(wc -l < "$d/README.md"); [ "$n" -le 150 ] || fail "README.md has $n lines, cap 150"
grep -qi 'tier' "$d/README.md" || fail "README.md has no scale tier table"
grep -q 'planning/' "$root/personas/_resolution.md" || fail "_resolution.md names no planning-group selection"
exit 0
