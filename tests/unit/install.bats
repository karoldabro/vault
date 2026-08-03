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
    for cmd in v-init v-work v-capture v-sync v-link v-backfill; do
        assert_symlink_to "${HOME}/.claude/commands/${cmd}.md" "${VAULT_ROOT}/commands/${cmd}.md"
    done
}

@test "install.sh skips commands/README.md" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ ! -e "${HOME}/.claude/commands/README.md" ]
}

@test "install.sh is idempotent (second run links 0, skips all)" {
    "${VAULT_ROOT}/install.sh" >/dev/null
    # Count command sources (md files excluding README) plus command subdirectories — both are linked.
    files="$(find "${VAULT_ROOT}/commands" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')"
    dirs="$(find "${VAULT_ROOT}/commands" -mindepth 1 -maxdepth 1 -type d ! -name attic | wc -l | tr -d ' ')"
    # Output styles are linked into a second tree by the same helpers.
    styles="$(find "${VAULT_ROOT}/output-styles" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')"
    expected=$((files + dirs + styles))
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Linked:  0"* ]]
    [[ "$output" == *"Skipped: ${expected}"* ]]
}

@test "install.sh symlinks command subdirectories (e.g. v-work/)" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    assert_symlink_to "${HOME}/.claude/commands/v-work" "${VAULT_ROOT}/commands/v-work"
    # Step files resolve through the directory symlink.
    [ -f "${HOME}/.claude/commands/v-work/steps/01-analyze.md" ]
}

@test "install.sh prunes a stale command-subdir symlink for a deleted source" {
    "${VAULT_ROOT}/install.sh" >/dev/null
    ln -s "${VAULT_ROOT}/commands/ghost-dir" "${HOME}/.claude/commands/ghost-dir"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ ! -L "${HOME}/.claude/commands/ghost-dir" ]
    [[ "$output" == *"Pruned:  1"* ]]
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

# Characterization: the prune must key off the SOURCE PREFIX, not merely "is dangling".
# The test above uses a target that exists, so it would still pass if the prefix guard were
# dropped. This one dangles, so only the prefix guard saves it.
@test "install.sh leaves a DANGLING symlink pointing outside commands/ alone" {
    mkdir -p "${HOME}/.claude/commands" "${HOME}/other"
    ln -s "${HOME}/other/deleted.md" "${HOME}/.claude/commands/foreign-dangling.md"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ -L "${HOME}/.claude/commands/foreign-dangling.md" ]
    [[ "$output" == *"Pruned:  0"* ]]
}

# Characterization: the re-link branch (`ln -sfn` when an existing symlink points at a wrong
# source) had zero coverage before the link_tree extraction.
@test "install.sh re-points a symlink whose source moved" {
    mkdir -p "${HOME}/.claude/commands" "${HOME}/stale"
    echo "old" > "${HOME}/stale/v-work.md"
    ln -s "${HOME}/stale/v-work.md" "${HOME}/.claude/commands/v-work.md"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    assert_symlink_to "${HOME}/.claude/commands/v-work.md" "${VAULT_ROOT}/commands/v-work.md"
}

@test "install.sh links output styles into ~/.claude/output-styles/" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ -d "${HOME}/.claude/output-styles" ]
    assert_symlink_to "${HOME}/.claude/output-styles/director.md" "${VAULT_ROOT}/output-styles/director.md"
}

@test "install.sh prunes a stale output-style symlink for a deleted source" {
    "${VAULT_ROOT}/install.sh" >/dev/null
    ln -s "${VAULT_ROOT}/output-styles/ghost-style.md" "${HOME}/.claude/output-styles/ghost-style.md"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ ! -L "${HOME}/.claude/output-styles/ghost-style.md" ]
    [[ "$output" == *"Pruned:  1"* ]]
}

@test "install.sh prints the correct activation path for the director style" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/config"* ]]
    [[ "$output" == *"director"* ]]
    # /output-style was removed in Claude Code v2.1.91 — never advertise it.
    [[ "$output" != *"/output-style "* ]]
}

@test "install.sh never installs the attic (archived commands)" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ ! -e "${HOME}/.claude/commands/attic" ]
    [ ! -e "${HOME}/.claude/commands/v-resume.md" ]
    [ ! -e "${HOME}/.claude/commands/v-migrate.md" ]
}
