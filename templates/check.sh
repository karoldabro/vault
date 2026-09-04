#!/usr/bin/env bash
# checks/<criterion-id>.sh — decides one success criterion.
#
# The gate runs this and reads its exit code. Nobody's opinion is involved, and the session that
# writes the work does not write the verdict.
#
# Contract:
#   exit 0   the criterion is met
#   exit 1   it is not
#   stdout   what you observed, so a person reading the plan later knows what was checked.
#            The gate copies your LAST line into the plan's evidence cell.
#
# Two rules that make the difference between a check and a decoration:
#
#   1. Read what a run PRODUCED, never what the system said about itself. A manifest records what
#      the pipeline intended; the artifact records what it did. A field can appear in every JSON a
#      run writes and reach no output.
#   2. Fail first. Write this script before the work, run it, and see it exit 1. A check that has
#      never failed has not been shown to check anything.
#
# Run from the repository root; the gate does that for you.

set -uo pipefail

# --- what this criterion requires -------------------------------------------
# Replace everything below.

if ! output=$(./some/real/command 2>&1); then
    printf 'the run failed: %s\n' "$(printf '%s' "$output" | tail -1)"
    exit 1
fi

if ! printf '%s' "$output" | grep -q 'the thing this change was supposed to produce'; then
    printf 'the run succeeded and the change did not arrive in its output\n'
    exit 1
fi

printf 'found the change in what the run produced\n'
exit 0
