#!/usr/bin/env bats
# Tests for checks/v-cr-abstract-review-C3.sh — the scorer that decides criterion C3 of
# vault/plans/2026-10-24-1903-v-cr-abstract-review.md from a seeded run and a control run.
# Backlog id T22; the title starts with the id.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    C3="${VAULT_ROOT}/checks/v-cr-abstract-review-C3.sh"
    FX="${VAULT_ROOT}/tests/fixtures/v-cr-abstract-review-c3"
}

@test "T22: the C3 scorer passes valid runs and fails wrong anchors, a missing seat and dirty controls" {
    run "${C3}" "${FX}/pass.md" "${FX}/control-clean.md"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    run "${C3}" "${FX}/wrong-anchor.md" "${FX}/control-clean.md"
    [ "$status" -eq 1 ]; [[ "$output" == *"change-impact:bin/report.sh"* ]]; [[ "$output" == *"pattern-conformance:_need_args"* ]]
    run "${C3}" "${FX}/missing-seat.md" "${FX}/control-clean.md"
    [ "$status" -eq 1 ]; [[ "$output" == *"intent-trace"* ]]
    run "${C3}" "${FX}/pass.md" "${FX}/missing-seat.md"
    [ "$status" -eq 1 ]
    run "${C3}" "${FX}/pass.md" "${FX}/control-dirty.md"
    [ "$status" -eq 1 ]; [[ "$output" == *"control run has 1"* ]]
    run "${C3}" "${FX}/pass.md" "${FX}/control-dirty-noanchor.md"
    [ "$status" -eq 1 ]
    run "${C3}" "${FX}/nosuch.md" "${FX}/control-clean.md"
    [ "$status" -eq 2 ]
}
