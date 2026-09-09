#!/usr/bin/env bash
# SC-4 — this plan does not raise the framework's rule-line count.
#
# The corpus is already over budget (175 lines against 173) and tests/unit/rule-count.bats asserts
# that failing exit code, so the unit suite cannot notice a rise. This pins the NUMBER instead of
# the verdict: two of the files this plan edits are in the corpus bin/rule-count.sh reads.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
counter="$root/bin/rule-count.sh"
PIN=${PIN:-175}

[ -x "$counter" ] || { printf '  MISSING  %s\n' "$counter"; exit 1; }

case "$PIN" in
    ''|*[!0-9]*) printf '  FAIL  PIN is not a number: %s\n' "$PIN"; exit 1 ;;
esac

# The counter's own exit status is part of the evidence. Discarding it lets a broken counter that
# prints a plausible line grade this check OK, which is the failure mode the pin exists to catch.
out=$("$counter" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then
    printf '  FAIL  %s exited %s\n%s\n' "$counter" "$rc" "$out"
    exit 1
fi

now=$(printf '%s\n' "$out" | awk '/^rule lines/ {print $3; exit}')
case "$now" in
    ''|*[!0-9]*) printf '  FAIL  could not parse a rule-line count out of %s\n' "$counter"; exit 1 ;;
esac

if [ "$now" -gt "$PIN" ]; then
    printf '  FAIL  rule lines rose to %s from the pinned %s — cut a rule before adding one\n' "$now" "$PIN"
    exit 1
fi
printf '  OK  %s rule lines, at or under the pinned %s\n' "$now" "$PIN"
