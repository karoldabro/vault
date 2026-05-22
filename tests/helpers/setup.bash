#!/usr/bin/env bash
# Common bats helpers. Source from each .bats file's `setup()`.

# Create a fresh isolated HOME for this test. Caller gets:
#   $TEST_HOME    — temp directory, becomes $HOME for the duration of the test
#   $VAULT_ROOT   — read-only path to the framework repo (mounted at /code)
make_test_home() {
    TEST_HOME="$(mktemp -d -t vault-test.XXXXXX)"
    export TEST_HOME
    export HOME="${TEST_HOME}"
    export VAULT_ROOT="/code"
}

cleanup_test_home() {
    if [ -n "${TEST_HOME:-}" ] && [ -d "${TEST_HOME}" ]; then
        rm -rf "${TEST_HOME}"
    fi
}

# Convenience: assert a path is a symlink pointing at $1.
assert_symlink_to() {
    local link="$1"
    local expected="$2"
    [ -L "${link}" ] || { echo "not a symlink: ${link}"; return 1; }
    local actual
    actual="$(readlink "${link}")"
    [ "${actual}" = "${expected}" ] || {
        echo "symlink target mismatch:"
        echo "  expected: ${expected}"
        echo "  actual:   ${actual}"
        return 1
    }
}
