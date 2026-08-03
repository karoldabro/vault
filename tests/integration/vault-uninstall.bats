#!/usr/bin/env bats
# Tests for bin/vault-uninstall.sh — reverses setup.sh / install.sh, in layers.

load "../helpers/setup.bash"

setup() {
    make_test_home
    export VAULT_HOME="${TEST_HOME}/vault"
    FAKEBIN="${TEST_HOME}/fakebin"
    mkdir -p "${FAKEBIN}"
    # Stand up a representative "installed" state to tear down.
    mkdir -p "${HOME}/.claude/commands" "${VAULT_HOME}/_global"
    ln -s "${VAULT_ROOT}/commands/v-work.md" "${HOME}/.claude/commands/v-work.md"
    ln -s "/some/other/tool.md"              "${HOME}/.claude/commands/foreign.md"
    printf '{ "model": "opus", "env": { "FOO": "bar" } }\n' > "${HOME}/.claude/settings.json"
}

teardown() { cleanup_test_home; }

stub() {
    printf '#!/usr/bin/env bash\n%s\n' "$2" > "${FAKEBIN}/$1"; chmod +x "${FAKEBIN}/$1"
}

uninstall() { run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/bin/vault-uninstall.sh" "$@"; }

@test "--help exits 0 and prints usage" {
    uninstall --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"reverse what setup.sh"* ]]
}

@test "unknown flag exits non-zero" {
    uninstall --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown flag"* ]]
}

@test "default --yes removes only vault command symlinks, keeps foreign ones" {
    uninstall --yes
    [ "$status" -eq 0 ]
    [ ! -L "${HOME}/.claude/commands/v-work.md" ]
    [ -L "${HOME}/.claude/commands/foreign.md" ]
}




@test "--dry-run changes nothing" {
    uninstall --dry-run
    [ "$status" -eq 0 ]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
    [ -d "${VAULT_HOME}/_global" ]
    [ "$(jq -r '.env.FOO' "${HOME}/.claude/settings.json")" = "bar" ]
}

@test "no --yes and no TTY → prints plan, changes nothing" {
    run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/bin/vault-uninstall.sh" </dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *"Nothing was changed"* ]]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
    [ -d "${VAULT_HOME}/_global" ]
}

# Regression guard: _global and ~/.openviking used to share one `rm -rf`. Dropping
# the OpenViking argument must not take the _global cleanup with it.
@test "--purge-data still deletes _global" {
    uninstall --purge-data --yes
    [ "$status" -eq 0 ]
    [ ! -d "${VAULT_HOME}/_global" ]
}

@test "default run leaves data dirs and does not purge" {
    uninstall --yes
    [ "$status" -eq 0 ]
    [ -d "${VAULT_HOME}/_global" ]
}

@test "--tools uninstalls vault tools via pipx/uv; default does not" {
    stub pipx 'echo "pipx $*" >> '"${TEST_HOME}"'/toollog'
    stub uv   'echo "uv $*"   >> '"${TEST_HOME}"'/toollog'

    uninstall --yes                       # no --tools
    [ ! -f "${TEST_HOME}/toollog" ]       # tools untouched

    uninstall --tools --yes
    grep -q 'pipx uninstall graphifyy'  "${TEST_HOME}/toollog"
    grep -q 'uv tool uninstall serena-agent' "${TEST_HOME}/toollog"
    ! grep -q 'openviking' "${TEST_HOME}/toollog"
}

# claude-mem@claude-mem was never a real id, so the uninstall silently no-opped
# and left the plugin installed. The marketplace declares "thedotmack".
@test "claude-mem is uninstalled under its real qualified id" {
    stub claude 'echo "claude $*" >> '"${TEST_HOME}"'/pluginlog; exit 0'
    uninstall --yes
    grep -q 'plugin uninstall claude-mem@thedotmack' "${TEST_HOME}/pluginlog"
    ! grep -q 'claude-mem@claude-mem' "${TEST_HOME}/pluginlog"
}
