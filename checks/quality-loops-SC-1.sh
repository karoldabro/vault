#!/usr/bin/env bash
# SC-1 of vault/plans/2026-10-18-1257-quality-loops.md — bin/vault-check.sh runs the opted-in check point or falls back to the repo commands.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
fail() { printf '%s\n' "$*"; exit 1; }
[ -x bin/vault-check.sh ] || fail "bin/vault-check.sh is missing or not executable"
[ -r tests/unit/vault-check.bats ] || fail "tests/unit/vault-check.bats is missing"
out=$(./tests/run.sh tests/unit/vault-check.bats 2>&1)
grep -q '^1\.\.' <<<"$out" || { echo "tests/unit/vault-check.bats did not run"; exit 2; }
for t in 'exit 0' 'exit 1' 'exit 2' 'clamp' 'not opted in' 'lint_command' 'unmeasured' 'absent' 'template' 'comment' 'not found' 'floor' 'withheld' 'timeout' 'no coverage line' 'untracked'; do
    grep -qi "^ok .*$t" <<<"$out" || fail "no passing vault-check test names: $t"
done
grep -q '^not ok' <<<"$out" && fail "$(grep '^not ok' <<<"$out")"
exit 0
