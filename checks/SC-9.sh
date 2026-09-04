#!/usr/bin/env bash
# SC-9: the unit suite fails no more tests than the four failing before this work began.
set -uo pipefail
BUDGET=4
fails=$(./tests/run.sh tests/unit 2>&1 | grep -c '^not ok')
if [ "$fails" -gt "$BUDGET" ]; then
    printf 'unit suite: %s failing, budget %s\n' "$fails" "$BUDGET"; exit 1
fi
printf 'unit suite: %s failing, budget %s\n' "$fails" "$BUDGET"
