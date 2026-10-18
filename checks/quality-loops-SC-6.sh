#!/usr/bin/env bash
# SC-6 of vault/plans/2026-10-18-1257-quality-loops.md — the whole unit suite passes, except tests that already failed.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
# known: one test name per line, each failing on the parent of this plan's first commit.
known=$(cat <<'KNOWN'
KNOWN
)
out=$(./tests/run.sh tests/unit 2>&1)
grep -q '^1\.\.' <<<"$out" || { echo "tests/unit did not run"; exit 2; }
bad=$(grep '^not ok' <<<"$out" || true)
[ -n "$known" ] && bad=$(grep -vF "$known" <<<"$bad" || true)
[ -z "$bad" ] || { printf '%s\n' "$bad"; exit 1; }
exit 0
