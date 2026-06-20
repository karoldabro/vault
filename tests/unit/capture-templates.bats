#!/usr/bin/env bats
# Tests for the /v-capture business-logic capture contract — file contracts only.
# Guards the `## Behaviors & rules` section against silent drift / rename across the two
# templates and the v-capture command that wires them. (Capture behavior itself is validated
# by manual dry-runs, not unit tests — it exercises the LLM command.)

load "../helpers/setup.bash"

setup() {
    make_test_home
}

teardown() {
    cleanup_test_home
}

@test "session template carries the Behaviors & rules section" {
    local f="${VAULT_ROOT}/templates/session.md"
    [ -f "${f}" ]
    grep -q '^## Behaviors & rules$' "${f}"
}

@test "feature template carries the Behaviors & rules section" {
    local f="${VAULT_ROOT}/templates/feature.md"
    [ -f "${f}" ]
    grep -q '^## Behaviors & rules$' "${f}"
}

@test "v-capture wires Behaviors & rules into session write + feature gate" {
    local f="${VAULT_ROOT}/commands/v-capture.md"
    [ -f "${f}" ]
    # Step 3 session "Fill honestly" list mentions the section.
    grep -q 'Behaviors & rules' "${f}"
    # Step 5b feature-gate UPDATE trigger now includes behaviors/rules.
    grep -q 'behaviors/rules' "${f}"
}
