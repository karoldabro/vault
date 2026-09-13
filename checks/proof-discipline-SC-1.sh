#!/usr/bin/env bash
# SC-1 — the claims gate and its anchor resolver behave on real plans.
#
# Wraps tests/unit/proof-discipline.bats, and names the cases this criterion owns. A green bats file
# is not evidence that the case for THIS criterion exists, so the titles are asserted too. An absent
# Docker is an unrunnable check, not a failed criterion, so that path exits 2.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bats="$root/tests/unit/proof-discipline.bats"

[ -f "$bats" ] || { printf '  MISSING  %s does not exist yet\n' "$bats"; exit 1; }

fail=0
for title in 'grounds that do not resolve' 'anchor followed by prose' 'unknown sha'; do
    run_hit=$(grep -cF "$title" "$bats" || true)
    [ "$run_hit" -ge 1 ] || { printf '  FAIL  %s names no case for "%s"\n' "$bats" "$title"; fail=1; }
done
[ "$fail" -eq 0 ] || exit 1

"$root/tests/run.sh" tests/unit/proof-discipline.bats; rc=$?
# tests/run.sh exits 2 when Docker is absent — an unrunnable check, not a failing criterion.
[ "$rc" -ne 2 ] || { printf '  UNRUNNABLE  tests/run.sh exited 2; Docker is required\n'; exit 2; }
exit "$rc"
