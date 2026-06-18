#!/usr/bin/env bats
# e2e: run setup.sh's REAL auto-install on Ubuntu and assert tools actually land.
# Runs only via tests/e2e/run.sh (root + network). Proves the machinery works
# end-to-end; the offline unit suite proves command construction.

load "../helpers/setup.bash"

setup() {
    make_test_home
    export VAULT_HOME="${TEST_HOME}/vault"
    export CLAUDE_HOME="${TEST_HOME}/.claude"
}

teardown() { cleanup_test_home; }

@test "real install: uv lands on disk via the curl|sh path" {
    run "${VAULT_ROOT}/setup.sh" --with-serena --yes
    [ "$status" -eq 0 ]
    [ -x "${HOME}/.local/bin/uv" ]
}

@test "real install: graphify lands on PATH via pipx" {
    run "${VAULT_ROOT}/setup.sh" --with-graphify --yes
    [ "$status" -eq 0 ]
    PATH="${HOME}/.local/bin:${PATH}" command -v graphify
}

@test "doctor reflects a real install with a ✓ row and exits 0" {
    "${VAULT_ROOT}/setup.sh" --with-graphify --yes >/dev/null
    run env PATH="${HOME}/.local/bin:${PATH}" "${VAULT_ROOT}/setup.sh" --doctor
    [ "$status" -eq 0 ]
    # Must be the check glyph, not just the label (which prints either way).
    [[ "$output" == *"✓] graphify"* ]]
}

@test "re-running a completed install is an idempotent no-op (exit 0)" {
    "${VAULT_ROOT}/setup.sh" --with-graphify --yes >/dev/null
    run "${VAULT_ROOT}/setup.sh" --with-graphify --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"graphify present"* ]]
}
