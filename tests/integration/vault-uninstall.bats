#!/usr/bin/env bats
# Tests for bin/vault-uninstall.sh — reverses setup.sh / install.sh, in layers.

load "../helpers/setup.bash"

setup() {
    make_test_home
    export VAULT_HOME="${TEST_HOME}/vault"
    FAKEBIN="${TEST_HOME}/fakebin"
    mkdir -p "${FAKEBIN}"
    # Stand up a representative "installed" state to tear down.
    mkdir -p "${HOME}/.claude/commands" \
             "${HOME}/.openviking/data" \
             "${HOME}/.openviking/claude-code-memory-plugin" \
             "${HOME}/.config/systemd/user" \
             "${VAULT_HOME}/_global"
    ln -s "${VAULT_ROOT}/commands/v-work.md" "${HOME}/.claude/commands/v-work.md"
    ln -s "/some/other/tool.md"              "${HOME}/.claude/commands/foreign.md"
    printf '{"server":{"port":1933}}\n' > "${HOME}/.openviking/ov.conf"
    printf '{"mode":"local"}\n'          > "${HOME}/.openviking/claude-code-memory-plugin/config.json"
    printf 'seeded\n'                    > "${HOME}/.openviking/data/index.bin"
    printf 'unit\n'                      > "${HOME}/.config/systemd/user/openviking.service"
    printf '{ "model": "opus", "env": { "FOO": "bar", "OPENVIKING_CONFIG_FILE": "%s/.openviking/ov.conf", "OPENVIKING_CC_CONFIG_FILE": "%s/.openviking/claude-code-memory-plugin/config.json" } }\n' \
        "${HOME}" "${HOME}" > "${HOME}/.claude/settings.json"
}

teardown() { cleanup_test_home; }

stub() {
    printf '#!/usr/bin/env bash\n%s\n' "$2" > "${FAKEBIN}/$1"; chmod +x "${FAKEBIN}/$1"
}

uninstall() { run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/bin/vault-uninstall.sh" "$@"; }

@test "--help exits 0 and prints usage" {
    uninstall --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Reverse what setup.sh"* ]]
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

@test "default --yes removes ov.conf + client config but KEEPS data" {
    uninstall --yes
    [ "$status" -eq 0 ]
    [ ! -f "${HOME}/.openviking/ov.conf" ]
    [ ! -f "${HOME}/.openviking/claude-code-memory-plugin/config.json" ]
    [ -f "${HOME}/.openviking/data/index.bin" ]      # data preserved
}

@test "default --yes removes the systemd unit" {
    uninstall --yes
    [ "$status" -eq 0 ]
    [ ! -f "${HOME}/.config/systemd/user/openviking.service" ]
}

@test "default --yes strips OPENVIKING_* env keys, keeps other settings" {
    uninstall --yes
    [ "$status" -eq 0 ]
    [ "$(jq -r '.model' "${HOME}/.claude/settings.json")" = "opus" ]
    [ "$(jq -r '.env.FOO' "${HOME}/.claude/settings.json")" = "bar" ]
    [ "$(jq -r '.env.OPENVIKING_CONFIG_FILE // "gone"' "${HOME}/.claude/settings.json")" = "gone" ]
    [ "$(jq -r '.env.OPENVIKING_CC_CONFIG_FILE // "gone"' "${HOME}/.claude/settings.json")" = "gone" ]
}

@test "--dry-run changes nothing" {
    uninstall --dry-run
    [ "$status" -eq 0 ]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
    [ -f "${HOME}/.openviking/ov.conf" ]
    [ -f "${HOME}/.config/systemd/user/openviking.service" ]
    [ "$(jq -r '.env.OPENVIKING_CONFIG_FILE' "${HOME}/.claude/settings.json")" = "${HOME}/.openviking/ov.conf" ]
}

@test "no --yes and no TTY → prints plan, changes nothing" {
    run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/bin/vault-uninstall.sh" </dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *"Nothing was changed"* ]]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
    [ -f "${HOME}/.openviking/ov.conf" ]
}

@test "--purge-data deletes ~/.openviking and _global" {
    uninstall --purge-data --yes
    [ "$status" -eq 0 ]
    [ ! -d "${HOME}/.openviking" ]
    [ ! -d "${VAULT_HOME}/_global" ]
}

@test "default run leaves data dirs and does not purge" {
    uninstall --yes
    [ "$status" -eq 0 ]
    [ -d "${HOME}/.openviking/data" ]
    [ -d "${VAULT_HOME}/_global" ]
}

@test "--tools uninstalls vault tools via pipx/uv; default does not" {
    stub pipx 'echo "pipx $*" >> '"${TEST_HOME}"'/toollog'
    stub uv   'echo "uv $*"   >> '"${TEST_HOME}"'/toollog'

    uninstall --yes                       # no --tools
    [ ! -f "${TEST_HOME}/toollog" ]       # tools untouched

    uninstall --tools --yes
    grep -q 'pipx uninstall openviking' "${TEST_HOME}/toollog"
    grep -q 'pipx uninstall graphifyy'  "${TEST_HOME}/toollog"
    grep -q 'uv tool uninstall serena-agent' "${TEST_HOME}/toollog"
}
