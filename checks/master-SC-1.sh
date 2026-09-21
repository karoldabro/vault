#!/usr/bin/env bash
# SC-1 of vault/plans/2026-09-21-1940-cross-session-contracts.md — the master-plan template.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
t="$root/templates/master-plan.md"; p="$root/templates/plan.md"
[ -r "$t" ] && [ -r "$p" ] || { echo "templates/master-plan.md is not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
[ "$(grep -c '^## ' "$t")" = 2 ] || fail "templates/master-plan.md has a line starting with '## ' other than its two headings"
grep -qx '## Sessions' "$t" && grep -qx '## Cross-session contracts' "$t" || fail "a heading is missing from templates/master-plan.md"
grep -q '^| id | scope | command | status | depends | date | evidence |$' "$t" || fail "the Sessions header lacks the depends column"
grep -q '^| id | contract | produced by | consumed by | shape |$' "$t" || fail "the contracts header has the wrong columns"
grep -q '^    | the `## Cross-session contracts` table' "$t" || fail "the artifact-lifecycle row is missing"
grep -q '^session_of:' "$p" || fail "templates/plan.md has no session_of key"
"$root/bin/doc-lint.sh" "$t" "$p" >/dev/null 2>&1 || fail "doc-lint fails on a template"
exit 0
