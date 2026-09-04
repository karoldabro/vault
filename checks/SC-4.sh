#!/usr/bin/env bash
# SC-4: the gate executes every committed check against this repo's own plan and passes only on
# the real exit codes. Runs the criteria half, which is the part that does not recurse.
set -uo pipefail
PLAN=vault/plans/2026-09-04-0900-mechanical-session-gates.md
./bin/gate.sh criteria "$PLAN" >/dev/null 2>&1 || { printf 'criteria refused its own plan\n'; exit 1; }
if ./bin/gate.sh criteria vault/plans/2026-09-03-0929-enforce-brevity-mechanically.md >/dev/null 2>&1; then
    printf 'criteria accepted a plan with no success criteria\n'; exit 1
fi
printf 'criteria accepts this plan and refuses one with no criteria table\n'
