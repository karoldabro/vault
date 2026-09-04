#!/usr/bin/env bats
# Behaviour tests for bin/gate.sh budget and recurrence — the two measurements that say whether any
# of the other checks are worth keeping.
#
# The budget one is load-bearing in a way that is easy to miss: a check people stop trusting is not
# ignored selectively, it is switched off wholesale. GATE=off takes every check with it, so one
# noisy check costs all of them. Ten percent is where Google disables a Tricorder analyzer.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    GATE_SH="${VAULT_ROOT}/bin/gate.sh"
    TMP="$(mktemp -d)"
    unset GATE
}

teardown() { [ -n "${TMP:-}" ] && rm -rf "${TMP}"; }

mkbudget() {
    local f="${TMP}/budget.md"
    { echo "## Check budget"; echo
      echo "| check | fires | wrong | note |"
      echo "|-------|-------|-------|------|"
      printf '%s\n' "$@"; echo; } > "$f"
    echo "$f"
}

mkledger() {
    local f="${TMP}/ledger.md"
    { echo "## Defect ledger"; echo
      echo "| id | defect | repair | test | recurrences |"
      echo "|----|--------|--------|------|-------------|"
      printf '%s\n' "$@"; echo; } > "$f"
    echo "$f"
}

@test "budget refuses a check wrong more than one time in ten" {
    local f; f=$(mkbudget '| criteria | 100 | 11 | |')
    run "${GATE_SH}" budget "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"over the one-in-ten budget"* ]]
    [[ "$output" == *"takes every other check with it"* ]]
}

@test "budget accepts a check at exactly one in ten" {
    local f; f=$(mkbudget '| criteria | 100 | 10 | |')
    run "${GATE_SH}" budget "$f"
    [ "$status" -eq 0 ]
}

@test "budget accepts a check that has never fired" {
    local f; f=$(mkbudget '| criteria | 0 | 0 | |')
    run "${GATE_SH}" budget "$f"
    [ "$status" -eq 0 ]
}

@test "budget refuses a non-numeric count rather than reading it as zero" {
    local f; f=$(mkbudget '| criteria | many | 0 | |')
    run "${GATE_SH}" budget "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"non-numeric"* ]]
}

@test "budget says nothing when no file has been written yet" {
    run "${GATE_SH}" budget "${TMP}/absent.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"nothing recorded yet"* ]]
}

@test "recurrence refuses a repair naming no failing-before test" {
    local f; f=$(mkledger '| D-1 | a thing broke | someone fixed it | I checked | 0 |')
    run "${GATE_SH}" recurrence "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"names no test"* ]]
    [[ "$output" == *"the repair is a claim"* ]]
}

@test "recurrence accepts a repair naming a test by path and line" {
    local f; f=$(mkledger '| D-1 | a thing broke | a gate now refuses it | tests/unit/x.bats:12 | 0 |')
    run "${GATE_SH}" recurrence "$f"
    [ "$status" -eq 0 ]
}

@test "recurrence reports how many defect classes came back" {
    local f; f=$(mkledger \
        '| D-1 | one | fixed | tests/unit/x.bats:1 | 0 |' \
        '| D-2 | two | fixed | tests/unit/y.bats:1 | 2 |')
    run "${GATE_SH}" recurrence "$f"
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 of 2 defect classes came back"* ]]
}

@test "recurrence refuses a non-numeric recurrence count" {
    local f; f=$(mkledger '| D-1 | one | fixed | tests/unit/x.bats:1 | twice |')
    run "${GATE_SH}" recurrence "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"non-numeric recurrence"* ]]
}

@test "the framework's own budget and ledger pass their checks" {
    run "${GATE_SH}" budget "${VAULT_ROOT}/vault/check-budget.md"
    [ "$status" -eq 0 ]
    run "${GATE_SH}" recurrence "${VAULT_ROOT}/vault/defect-ledger.md"
    [ "$status" -eq 0 ]
}
