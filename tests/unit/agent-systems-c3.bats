#!/usr/bin/env bats
# Tests for checks/agent-systems-lens-C3.sh — the parser that decides criterion C3 of
# vault/plans/2026-10-20-1934-agent-systems-lens.md from one saved agent-systems review.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    C3="${VAULT_ROOT}/checks/agent-systems-lens-C3.sh"
    FX="${VAULT_ROOT}/tests/fixtures/agent-systems-c3"
}

@test "a review with 3 evidenced confirmed findings, one on the judge, passes" {
    run "${C3}" "${FX}/pass.md"
    [ "$status" -eq 0 ]
}

@test "a confirmed finding whose check is 'none, could not run' does not count" {
    run "${C3}" "${FX}/check-none.md"
    [ "$status" -eq 1 ]
}

@test "a check made only of backticked identifiers does not count" {
    run "${C3}" "${FX}/identifiers-only.md"
    [ "$status" -eq 1 ]
}

@test "prose that mentions the grounding phrase does not count" {
    run "${C3}" "${FX}/prose-mentions.md"
    [ "$status" -eq 1 ]
}

@test "evidence on a line no deeper than the id line does not join the check field" {
    run "${C3}" "${FX}/trailing-prose.md"
    [ "$status" -eq 1 ]
}

@test "a review from another persona fails" {
    run "${C3}" "${FX}/wrong-persona.md"
    [ "$status" -eq 1 ]
}

@test "a review with no confirmed finding on the judge fails" {
    run "${C3}" "${FX}/no-judge.md"
    [ "$status" -eq 1 ]
}

@test "with no argument the script reads the plan's default run file, and exits 2 when it is absent" {
    local root; root="$(mktemp -d)"
    mkdir -p "${root}/checks" "${root}/vault/plans"
    cp "${C3}" "${root}/checks/"
    run "${root}/checks/agent-systems-lens-C3.sh"
    [ "$status" -eq 2 ]
    cp "${FX}/pass.md" "${root}/vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md"
    run "${root}/checks/agent-systems-lens-C3.sh"
    [ "$status" -eq 0 ]
    rm -rf "${root}"
}
