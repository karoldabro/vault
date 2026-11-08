#!/usr/bin/env bash
# C4 of vault/plans/2026-10-24-1903-v-cr-abstract-review.md — the rule-line count stays within its budget of 173.
#
# commands/_shared/critic-panel.md is in the corpus bin/rule-count.sh reads, and the plan edits it.
# The count was 170 before the edit; the pin is the budget.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
counter="$root/bin/rule-count.sh"
PIN=${PIN:-173}

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
