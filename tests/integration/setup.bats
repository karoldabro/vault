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

@test "--with-ov writes a valid JSON ov.conf + plugin client config + service unit" {
    run "${VAULT_ROOT}/setup.sh" --with-ov --yes
    [ "$status" -eq 0 ]
    # Server config: JSON the server can actually parse (not the old 3-line format).
    [ -f "${HOME}/.openviking/ov.conf" ]
    grep -q '"server"' "${HOME}/.openviking/ov.conf"
    grep -q '"port": 1933' "${HOME}/.openviking/ov.conf"
    grep -q 'nomic-embed-text' "${HOME}/.openviking/ov.conf"
    # Plugin client config — the file whose absence makes the MCP exit ("Connection closed").
    [ -f "${HOME}/.openviking/claude-code-memory-plugin/config.json" ]
    grep -q '"mode": "local"' "${HOME}/.openviking/claude-code-memory-plugin/config.json"
    # systemd --user unit that runs the server.
    [ -f "${HOME}/.config/systemd/user/openviking.service" ]
    grep -q 'openviking-server --config' "${HOME}/.config/systemd/user/openviking.service"
}

@test "--with-ov rewrites a stale 3-line ov.conf into JSON" {
    mkdir -p "${HOME}/.openviking"
    printf 'workspace = /old\nprovider  = ollama\nmodel     = nomic-embed-text\n' > "${HOME}/.openviking/ov.conf"
    run "${VAULT_ROOT}/setup.sh" --with-ov --yes
    [ "$status" -eq 0 ]
    grep -q '"server"' "${HOME}/.openviking/ov.conf"
    ! grep -q 'workspace = /old' "${HOME}/.openviking/ov.conf"
}

@test "--with-ov sets the OPENVIKING_*_CONFIG_FILE keys in settings.json" {
    run "${VAULT_ROOT}/setup.sh" --with-ov --yes
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.claude/settings.json" ]
    [ "$(jq -r '.env.OPENVIKING_CC_CONFIG_FILE' "${HOME}/.claude/settings.json")" = "${HOME}/.openviking/claude-code-memory-plugin/config.json" ]
    [ "$(jq -r '.env.OPENVIKING_CONFIG_FILE' "${HOME}/.claude/settings.json")" = "${HOME}/.openviking/ov.conf" ]
}

@test "--with-ov preserves existing settings.json keys and is idempotent" {
    mkdir -p "${HOME}/.claude"
    printf '{ "model": "opus", "env": { "FOO": "bar" } }\n' > "${HOME}/.claude/settings.json"
    "${VAULT_ROOT}/setup.sh" --with-ov --yes >/dev/null
    "${VAULT_ROOT}/setup.sh" --with-ov --yes >/dev/null   # second run = no-op
    [ "$(jq -r '.model' "${HOME}/.claude/settings.json")" = "opus" ]
    [ "$(jq -r '.env.FOO' "${HOME}/.claude/settings.json")" = "bar" ]
    [ "$(jq -r '.env.OPENVIKING_CONFIG_FILE' "${HOME}/.claude/settings.json")" = "${HOME}/.openviking/ov.conf" ]
}

@test "--with-ov keeps a user override whose config file exists" {
    mkdir -p "${HOME}/.claude" "${HOME}/custom"
    printf '{}\n' > "${HOME}/custom/cc.json"
    printf '{ "env": { "OPENVIKING_CC_CONFIG_FILE": "%s/custom/cc.json" } }\n' "${HOME}" > "${HOME}/.claude/settings.json"
    run "${VAULT_ROOT}/setup.sh" --with-ov --yes
    [ "$status" -eq 0 ]
    # Existing-and-valid override is preserved, not clobbered.
    [ "$(jq -r '.env.OPENVIKING_CC_CONFIG_FILE' "${HOME}/.claude/settings.json")" = "${HOME}/custom/cc.json" ]
    # The other (absent) key is still added.
    [ "$(jq -r '.env.OPENVIKING_CONFIG_FILE' "${HOME}/.claude/settings.json")" = "${HOME}/.openviking/ov.conf" ]
}

@test "--minimal beats --with-ov (no ov.conf written)" {
    run "${VAULT_ROOT}/setup.sh" --with-ov --minimal --yes
    [ "$status" -eq 0 ]
    [ ! -f "${HOME}/.openviking/ov.conf" ]
}

@test "prints per-repo onboarding instructions (vault-init / VAULT.md)" {
    run "${VAULT_ROOT}/setup.sh" --minimal --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"bin/vault-init.sh"* ]]
    [[ "$output" == *"VAULT.md"* ]]
    [[ "$output" == *"VAULT_FRAMEWORK_PATH"* ]]
}

@test "does not write into the user-owned ~/.claude/CLAUDE.md" {
    mkdir -p "${CLAUDE_HOME}"
    printf 'MY OWN CLAUDE.md\n' > "${CLAUDE_HOME}/CLAUDE.md"
    run "${VAULT_ROOT}/setup.sh" --minimal --yes
    [ "$status" -eq 0 ]
    # The installer must leave the user's global CLAUDE.md exactly as it was.
    [ "$(cat "${CLAUDE_HOME}/CLAUDE.md")" = "MY OWN CLAUDE.md" ]
}
