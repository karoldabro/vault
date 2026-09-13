#!/usr/bin/env bash
# SC-4 — the counted corpus comes back inside its own budget, on both numbers.
#
# `bin/rule-count.sh` without an argument exits 0 whatever it printed, so an rc check on the bare
# call decides nothing — and `--assert` can never pass here, because it also enforces a 1:1
# prohibition-to-requirement ceiling that the corpus misses by 120 lines. Rewriting 120 prohibitions
# across twelve files is a separate change. So this pins the three numbers directly, which is what
# this plan can actually hold, and the ratio overrun is recorded in the plan's open items instead.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
counter="$root/bin/rule-count.sh"
PIN_RULES=170
PIN_PROHIBITIONS=145
MIN_REQUIREMENTS=25
fail=0

[ -x "$counter" ] || { printf '  MISSING  %s\n' "$counter"; exit 1; }

out=$("$counter" 2>&1)

rules=$(printf '%s\n' "$out" | awk '/^rule lines/ {print $3; exit}')
proh=$(printf '%s\n' "$out"  | awk '/^prohibitions/ {print $2; exit}')
reqs=$(printf '%s\n' "$out"  | awk '/^requirements/ {print $2; exit}')

for pair in "rule lines:$rules" "prohibitions:$proh" "requirements:$reqs"; do
    v=${pair#*:}
    case "$v" in ''|*[!0-9]*) printf '  FAIL  could not parse %s out of %s\n' "${pair%%:*}" "$counter"; exit 1 ;; esac
done

[ "$rules" -le "$PIN_RULES" ]      || { printf '  FAIL  %s rule lines, over the pinned %s\n' "$rules" "$PIN_RULES"; fail=1; }
[ "$proh"  -le "$PIN_PROHIBITIONS" ] || { printf '  FAIL  %s prohibitions, over the pinned %s\n' "$proh" "$PIN_PROHIBITIONS"; fail=1; }
[ "$reqs"  -ge "$MIN_REQUIREMENTS" ] || { printf '  FAIL  %s requirements, under the floor of %s — a deleted requirement is not a saving\n' "$reqs" "$MIN_REQUIREMENTS"; fail=1; }

[ "$fail" -eq 0 ] || exit 1
printf '  OK  %s rule lines, %s prohibitions, %s requirements (the 1:1 ratio ceiling is a standing overrun, not closed here)\n' "$rules" "$proh" "$reqs"
