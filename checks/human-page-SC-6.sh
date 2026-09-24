#!/usr/bin/env bash
# SC-6 of vault/plans/2026-09-24-1902-human-page-essentials.md: every local plan page matches a fresh render.
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bad=0; n=0
for page in "$root"/vault/plans/*.human.html; do
    [ -e "$page" ] || { echo "no human pages found"; exit 2; }
    plan="${page%.human.html}.md"; n=$((n + 1))
    out=$(cd "$root" && "$root/bin/gate.sh" human "$plan" 2>&1) || { printf '%s\n' "$out"; bad=1; }
done
[ "$n" -ge 12 ] || { echo "found $n pages, expected at least 12"; exit 1; }
exit "$bad"
