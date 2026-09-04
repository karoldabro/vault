#!/usr/bin/env bash
# regression-count.sh — run the unit suite and refuse when it fails more tests than a stated budget.
#
# The budget is a number you pass, not a number this reads from anywhere, so raising it is a visible
# edit in a plan or a check rather than a silent drift. A suite whose failure count creeps upward one
# test at a time is how a session comes to report green against a suite that stopped meaning anything.
#
# Usage: bin/regression-count.sh <budget>
# Exit:  0 at or under budget · 1 over budget · 2 usage error

set -uo pipefail

budget=${1:-}
case "$budget" in
    ''|*[!0-9]*) printf 'usage: %s <budget>\n' "$0" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="${SCRIPT_DIR}/../tests/run.sh"
[ -x "$RUNNER" ] || { printf 'no test runner at %s\n' "$RUNNER" >&2; exit 2; }

out=$("$RUNNER" tests/unit 2>&1)
fails=$(printf '%s' "$out" | grep -c '^not ok' || true)
total=$(printf '%s' "$out" | grep -c '^ok' || true)

printf '%s failing, %s passing, budget %s\n' "$fails" "$total" "$budget"

if [ "$fails" -gt "$budget" ]; then
    printf '%s\n' "$out" | grep -A2 '^not ok' >&2
    exit 1
fi
exit 0
