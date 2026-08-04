#!/usr/bin/env bats
# Tests for bin/release-check.sh — the guard against publishing without a plugin.json version bump.
#
# The script is run against throwaway repos built in $TEST_HOME, not against /code, so the base ref
# is a local branch rather than origin/main. Each case is one branch of the decision it encodes:
# shipped-changes × version-changed.

load "../helpers/setup.bash"

git_init() {
    git -C "$1" init --quiet --initial-branch=main 2>/dev/null || git -C "$1" init --quiet
    git -C "$1" config user.email "test@local"
    git -C "$1" config user.name  "test"
}

write_manifest() {
    mkdir -p "${REPO}/.claude-plugin"
    cat > "${REPO}/.claude-plugin/plugin.json" <<EOF
{
  "name": "vault",
  "version": "$1"
}
EOF
}

# A repo with a committed baseline on the `published` branch, which stands in for origin/main.
make_repo() {
    REPO="${TEST_HOME}/repo"
    mkdir -p "${REPO}/bin" "${REPO}/commands" "${REPO}/tests" "${REPO}/vault" "${REPO}/docs"
    git_init "${REPO}"
    cp "${VAULT_ROOT}/bin/release-check.sh" "${REPO}/bin/release-check.sh"
    chmod +x "${REPO}/bin/release-check.sh"
    write_manifest "1.0.0"
    echo "a command" > "${REPO}/commands/v-thing.md"
    echo "a test"    > "${REPO}/tests/thing.bats"
    echo "a note"    > "${REPO}/vault/note.md"
    echo "a doc"     > "${REPO}/docs/thing.md"
    git -C "${REPO}" add -A
    git -C "${REPO}" commit --quiet -m "baseline"
    git -C "${REPO}" branch published
}

CHECK() { "${REPO}/bin/release-check.sh" --base published --no-fetch; }

setup() {
    make_test_home
    export GIT_AUTHOR_NAME="test"    GIT_AUTHOR_EMAIL="test@local"
    export GIT_COMMITTER_NAME="test" GIT_COMMITTER_EMAIL="test@local"
    make_repo
}

teardown() {
    cleanup_test_home
}

@test "passes when nothing changed" {
    run CHECK
    [ "$status" -eq 0 ]
    [[ "$output" == *"no shipped files changed"* ]]
}

@test "fails when a shipped file changed and the version did not" {
    echo "edited" >> "${REPO}/commands/v-thing.md"
    run CHECK
    [ "$status" -eq 1 ]
    [[ "$output" == *"still 1.0.0"* ]]
    [[ "$output" == *"commands/v-thing.md"* ]]
}

@test "passes when a shipped file changed and the version was bumped" {
    echo "edited" >> "${REPO}/commands/v-thing.md"
    write_manifest "1.1.0"
    run CHECK
    [ "$status" -eq 0 ]
    [[ "$output" == *"1.0.0 -> 1.1.0"* ]]
}

@test "a new untracked command counts as a shipped change" {
    echo "new" > "${REPO}/commands/v-new.md"
    run CHECK
    [ "$status" -eq 1 ]
    [[ "$output" == *"commands/v-new.md"* ]]
}

@test "test-only changes need no version bump" {
    echo "edited" >> "${REPO}/tests/thing.bats"
    echo "new"     > "${REPO}/tests/new.bats"
    run CHECK
    [ "$status" -eq 0 ]
    [[ "$output" == *"no shipped files changed"* ]]
}

@test "vault docs and docs/ changes need no version bump" {
    echo "edited" >> "${REPO}/vault/note.md"
    echo "edited" >> "${REPO}/docs/thing.md"
    run CHECK
    [ "$status" -eq 0 ]
    [[ "$output" == *"no shipped files changed"* ]]
}

@test "a mix of shipped and excluded changes still fails" {
    echo "edited" >> "${REPO}/vault/note.md"
    echo "edited" >> "${REPO}/commands/v-thing.md"
    run CHECK
    [ "$status" -eq 1 ]
    [[ "$output" == *"commands/v-thing.md"* ]]
    [[ "$output" != *"vault/note.md"* ]]
}

@test "an unreachable base ref warns and passes rather than blocking" {
    echo "edited" >> "${REPO}/commands/v-thing.md"
    run "${REPO}/bin/release-check.sh" --base no-such-branch --no-fetch
    [ "$status" -eq 0 ]
    [[ "$output" == *"unreachable"* ]]
}

@test "the manifest version bump alone is enough, even with no other change" {
    write_manifest "1.1.0"
    run CHECK
    [ "$status" -eq 0 ]
    [[ "$output" == *"1.0.0 -> 1.1.0"* ]]
}

@test "--help exits 0 and prints usage" {
    run "${REPO}/bin/release-check.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"release-check.sh"* ]]
}

@test "the Makefile exposes release-check and keeps it out of make test" {
    grep -q "^release-check:" "${VAULT_ROOT}/Makefile"
    run bash -c "sed -n '/^test:/,/^$/p' '${VAULT_ROOT}/Makefile' | grep -c release-check"
    [ "$output" -eq 0 ]
}
