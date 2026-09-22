#!/usr/bin/env bash
# SC-1 of vault/plans/2026-09-22-0900-stack-packs.md — five new stack-pack registry rows exist.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[ -x "$root/bin/probe.sh" ] || { echo "bin/probe.sh is not executable"; exit 2; }
out=$("$root/bin/probe.sh" list --repo "$root" 2>/dev/null) || { echo "bin/probe.sh list failed"; exit 2; }
n=$(printf '%s\n' "$out" | grep -cE '^(laravel-phpstan|laravel-arkitect|nuxt-tsc|dart-analyze|python-ruff)	')
[ "$n" = 5 ] || { echo "found $n of 5 stack-pack rows"; exit 1; }
exit 0
