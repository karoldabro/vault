#!/usr/bin/env bats
# Tests for setup.sh — the umbrella installer.

load "../helpers/setup.bash"

setup() {
    make_test_home
    # setup.sh writes to VAULT_HOME and CLAUDE_HOME; isolate both.
    export VAULT_HOME="${TEST_HOME}/vault"
    export CLAUDE_HOME="${TEST_HOME}/.claude"
}

teardown() {
    cleanup_test_home
}

@test "--help exits 0 and prints usage" {
    run "${VAULT_ROOT}/setup.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "unknown flag exits non-zero with usage" {
    run "${VAULT_ROOT}/setup.sh" --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown flag"* ]]
}

@test "--minimal creates VAULT_HOME/_global/coupled-groups.md" {
    run "${VAULT_ROOT}/setup.sh" --minimal --yes
    [ "$status" -eq 0 ]
    [ -d "${VAULT_HOME}/_global" ]
    [ -f "${VAULT_HOME}/_global/coupled-groups.md" ]
    grep -q "Coupled project groups" "${VAULT_HOME}/_global/coupled-groups.md"
}

@test "--minimal calls install.sh and symlinks commands" {
    run "${VAULT_ROOT}/setup.sh" --minimal --yes
    [ "$status" -eq 0 ]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
    [ -L "${HOME}/.claude/commands/v-capture.md" ]
}

@test "--minimal is idempotent (second run is a no-op for coupled-groups)" {
    "${VAULT_ROOT}/setup.sh" --minimal --yes >/dev/null
    cp "${VAULT_HOME}/_global/coupled-groups.md" "${TEST_HOME}/before"
    "${VAULT_ROOT}/setup.sh" --minimal --yes >/dev/null
    cmp -s "${TEST_HOME}/before" "${VAULT_HOME}/_global/coupled-groups.md"
}

@test "--minimal preserves existing coupled-groups.md (does not clobber)" {
    mkdir -p "${VAULT_HOME}/_global"
    echo "USER CONTENT" > "${VAULT_HOME}/_global/coupled-groups.md"
    run "${VAULT_ROOT}/setup.sh" --minimal --yes
    [ "$status" -eq 0 ]
    grep -q "USER CONTENT" "${VAULT_HOME}/_global/coupled-groups.md"
}

@test "--with-ov writes ov.conf with VAULT_HOME workspace" {
    run "${VAULT_ROOT}/setup.sh" --with-ov --yes
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.openviking/ov.conf" ]
    grep -q "workspace = ${VAULT_HOME}" "${HOME}/.openviking/ov.conf"
    grep -q "model     = nomic-embed-text" "${HOME}/.openviking/ov.conf"
}

@test "--minimal beats --with-ov (no ov.conf written)" {
    run "${VAULT_ROOT}/setup.sh" --with-ov --minimal --yes
    [ "$status" -eq 0 ]
    [ ! -f "${HOME}/.openviking/ov.conf" ]
}

@test "prints CLAUDE.md snippet TODO when ~/.claude/CLAUDE.md is absent" {
    run "${VAULT_ROOT}/setup.sh" --minimal --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"snippet"* ]]
    [[ "$output" == *"/v-work"* ]]
}

@test "skips CLAUDE.md snippet when marker already present in CLAUDE.md" {
    mkdir -p "${CLAUDE_HOME}"
    printf '## Cross-project memory stack\n\nalready wired.\n' > "${CLAUDE_HOME}/CLAUDE.md"
    run "${VAULT_ROOT}/setup.sh" --minimal --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"snippet already present"* ]]
}
