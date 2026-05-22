#!/usr/bin/env bats
# Tests for install.sh — symlink creation, idempotency, prune behavior.

load "../helpers/setup.bash"

setup() {
    make_test_home
}

teardown() {
    cleanup_test_home
}

@test "install.sh creates symlinks for each command in commands/" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    assert_symlink_to "${HOME}/.claude/commands/v-work.md"    "${VAULT_ROOT}/commands/v-work.md"
    assert_symlink_to "${HOME}/.claude/commands/v-capture.md" "${VAULT_ROOT}/commands/v-capture.md"
}

@test "install.sh skips commands/README.md" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ ! -e "${HOME}/.claude/commands/README.md" ]
}

@test "install.sh is idempotent (second run links 0, skips all)" {
    "${VAULT_ROOT}/install.sh" >/dev/null
    # Count command sources excluding the README, which install.sh skips.
    expected="$(find "${VAULT_ROOT}/commands" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Linked:  0"* ]]
    [[ "$output" == *"Skipped: ${expected}"* ]]
}

@test "install.sh refuses to overwrite a non-symlink command file" {
    mkdir -p "${HOME}/.claude/commands"
    echo "user content" > "${HOME}/.claude/commands/v-work.md"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"REFUSED"* ]]
    # Original content is preserved.
    grep -q "user content" "${HOME}/.claude/commands/v-work.md"
}

@test "install.sh prunes stale symlinks pointing into commands/ for deleted sources" {
    "${VAULT_ROOT}/install.sh" >/dev/null
    # Simulate a previous-version symlink for a command that no longer exists.
    ln -s "${VAULT_ROOT}/commands/ghost.md" "${HOME}/.claude/commands/ghost.md"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ ! -e "${HOME}/.claude/commands/ghost.md" ]
    [ ! -L "${HOME}/.claude/commands/ghost.md" ]
    [[ "$output" == *"Pruned:  1"* ]]
}

@test "install.sh leaves unrelated host symlinks alone" {
    mkdir -p "${HOME}/.claude/commands" "${HOME}/other"
    echo "x" > "${HOME}/other/unrelated.md"
    ln -s "${HOME}/other/unrelated.md" "${HOME}/.claude/commands/unrelated.md"
    "${VAULT_ROOT}/install.sh" >/dev/null
    [ -L "${HOME}/.claude/commands/unrelated.md" ]
}
