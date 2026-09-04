#!/usr/bin/env bats
# Behaviour tests for bin/rule-count.sh and scripts/rule-inject-hook.sh.
#
# The load-bearing one is the last: the injection hook must never grow beyond the prose list. If it
# could carry its own rules it would become the place people add instructions, which is the opposite
# of what it is for — every added instruction lowers compliance on the ones that already exist.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    COUNT="${VAULT_ROOT}/bin/rule-count.sh"
    INJECT="${VAULT_ROOT}/scripts/rule-inject-hook.sh"
    TMP="$(mktemp -d)"
    unset GATE
}

teardown() { [ -n "${TMP:-}" ] && rm -rf "${TMP}"; }

@test "rule-count reports a corpus size, a rule count and both grammatical forms" {
    run "${COUNT}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"corpus"* ]]
    [[ "$output" == *"rule lines"* ]]
    [[ "$output" == *"prohibitions"* ]]
    [[ "$output" == *"requirements"* ]]
}

@test "rule-count --assert fails while prohibitions outnumber requirements" {
    run "${COUNT}" --assert
    [ "$status" -eq 1 ]
    [[ "$output" == *"prohibitions against"* ]]
}

@test "rule-count names why the form matters, so the number is actionable" {
    run "${COUNT}" --assert
    [[ "$output" == *"33% compliance by turn 16"* ]]
    [[ "$output" == *"Rewrite, do not delete"* ]]
}

@test "rule-count --lines ranks files by prohibition count" {
    run "${COUNT}" --lines
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ [0-9]+[[:space:]]+commands/ ]]
}

@test "rule-count leaves the output style out of the budget" {
    run "${COUNT}"
    [[ "$output" == *"not budgeted"* ]]
}

@test "the injection hook exits 0 and prints the prose rules" {
    run "${INJECT}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Rules nothing checks"* ]]
}

@test "GATE=off silences the injection hook" {
    GATE=off run "${INJECT}"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "the injection hook carries no rules of its own — it can only echo the prose list" {
    local from_file injected
    from_file=$(awk '/^## Rules kept as prose/{s=1;next} s&&/^## /{exit} s&&/^\|/&&!/^\|[- |:]*\|$/{n++} END{print n+0}' \
        "${VAULT_ROOT}/vault/check-budget.md")
    injected=$("${INJECT}" | grep -c '^  - ')
    [ "$((from_file - 1))" -eq "$injected" ]
}
