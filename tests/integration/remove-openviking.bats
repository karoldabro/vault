#!/usr/bin/env bats
# Tests for bin/remove-openviking.sh — the one-time OpenViking remover.
#
# OpenViking is no longer part of this framework; this script exists so an install
# that predates the removal can be taken off a machine. It deletes indexed data, so
# the safety properties below are the point of the file, not incidental coverage.

load "../helpers/setup.bash"

setup() {
    make_test_home
    FAKEBIN="${TEST_HOME}/fakebin"
    mkdir -p "${FAKEBIN}"
    # A representative "OpenViking is installed" state.
    mkdir -p "${HOME}/.claude" \
             "${HOME}/.openviking/data" \
             "${HOME}/.openviking/claude-code-memory-plugin" \
             "${HOME}/.config/systemd/user"
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

remove_ov() { run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/bin/remove-openviking.sh" "$@"; }

@test "--help exits 0 and prints usage" {
    remove_ov --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"take OpenViking off this machine"* ]]
}

@test "--help prints no shell code" {
    remove_ov --help
    [[ "$output" != *"set -euo pipefail"* ]]
    [[ "$output" != *"VAULT_ROOT="* ]]
}

@test "unknown flag exits non-zero" {
    remove_ov --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown flag"* ]]
}

@test "--yes removes config, unit and settings keys but KEEPS data by default" {
    remove_ov --yes
    [ "$status" -eq 0 ]
    [ ! -f "${HOME}/.openviking/ov.conf" ]
    [ ! -f "${HOME}/.openviking/claude-code-memory-plugin/config.json" ]
    [ ! -f "${HOME}/.config/systemd/user/openviking.service" ]
    [ -f "${HOME}/.openviking/data/index.bin" ]
    [ "$(jq -r '.model' "${HOME}/.claude/settings.json")" = "opus" ]
    [ "$(jq -r '.env.FOO' "${HOME}/.claude/settings.json")" = "bar" ]
    [ "$(jq -r '.env.OPENVIKING_CONFIG_FILE // "gone"' "${HOME}/.claude/settings.json")" = "gone" ]
    [ "$(jq -r '.env.OPENVIKING_CC_CONFIG_FILE // "gone"' "${HOME}/.claude/settings.json")" = "gone" ]
}

@test "--purge-data deletes the indexed data" {
    remove_ov --purge-data --yes
    [ "$status" -eq 0 ]
    [ ! -d "${HOME}/.openviking" ]
}

# t1 — dry-run must be a pure read.
@test "--dry-run prints a plan, exits 0 and leaves every seeded file byte-identical" {
    before="$(find "${HOME}/.openviking" "${HOME}/.config/systemd/user" -type f -exec md5sum {} + | sort)"
    settings_before="$(cat "${HOME}/.claude/settings.json")"

    remove_ov --all --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"Nothing was changed"* ]]

    after="$(find "${HOME}/.openviking" "${HOME}/.config/systemd/user" -type f -exec md5sum {} + | sort)"
    [ "${before}" = "${after}" ]
    [ "${settings_before}" = "$(cat "${HOME}/.claude/settings.json")" ]
}

@test "no --yes and no TTY → prints the plan, changes nothing" {
    run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/bin/remove-openviking.sh" </dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *"Nothing was changed"* ]]
    [ -f "${HOME}/.openviking/ov.conf" ]
}

# t2 — idempotency + degradation when the host has none of the optional deps.
@test "--all --yes is idempotent and survives missing jq/systemctl/pipx" {
    # systemctl and pipx are genuinely absent on the alpine test image; jq is not
    # (/usr/bin/jq), so shadow it with a non-executable stub to reach the warn branch.
    printf 'not-an-executable\n' > "${FAKEBIN}/jq"   # present but not runnable
    chmod -x "${FAKEBIN}/jq"

    run env PATH="${FAKEBIN}:/usr/bin:/bin" \
        "${VAULT_ROOT}/bin/remove-openviking.sh" --all --yes
    [ "$status" -eq 0 ]

    run env PATH="${FAKEBIN}:/usr/bin:/bin" \
        "${VAULT_ROOT}/bin/remove-openviking.sh" --all --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"already absent"* ]]
}

@test "reports each part as already absent on a machine that never had it" {
    rm -rf "${HOME}/.openviking" "${HOME}/.config/systemd/user/openviking.service"
    printf '{ "model": "opus" }\n' > "${HOME}/.claude/settings.json"
    remove_ov --all --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"already absent"* ]]
}

# t3 — the classic expansion bug: with HOME empty, "${HOME}/.openviking" is
# "/.openviking". set -u does not catch it, so the script must check explicitly.
@test "refuses to delete anything when HOME is empty" {
    run env -u HOME PATH="${FAKEBIN}:${PATH}" HOME="" \
        "${VAULT_ROOT}/bin/remove-openviking.sh" --purge-data --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"refusing to delete"* ]]
    [ ! -e "/.openviking" ]
}

@test "refuses to delete anything when HOME is /" {
    run env PATH="${FAKEBIN}:${PATH}" HOME="/" \
        "${VAULT_ROOT}/bin/remove-openviking.sh" --purge-data --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"refusing to delete"* ]]
}

@test "uninstalls the plugin and the pipx package under --tools" {
    stub claude 'echo "claude $*" >> '"${TEST_HOME}"'/log; exit 0'
    stub pipx   'echo "pipx $*"   >> '"${TEST_HOME}"'/log'
    remove_ov --tools --yes
    [ "$status" -eq 0 ]
    grep -q 'plugin uninstall claude-code-memory-plugin@openviking-plugin' "${TEST_HOME}/log"
    grep -q 'pipx uninstall openviking' "${TEST_HOME}/log"
}

#------------------------------------------------------------------------------
# Second Claude home. A machine can run CLAUDE_CONFIG_DIR against another config
# dir, which carries its own settings.json and plugin registry. Cleaning only
# ~/.claude leaves that one loading the plugin, whose UserPromptSubmit hook then
# errors on the client config this script has just deleted — the exact failure
# that shipped on 2026-08-04.
#------------------------------------------------------------------------------
seed_alt_config_dir() {
    local dir="$1"
    mkdir -p "${dir}"
    printf '{ "env": { "OPENVIKING_CONFIG_FILE": "%s/.openviking/ov.conf" }, "enabledPlugins": { "claude-code-memory-plugin@openviking-plugin": true, "claude-mem@thedotmack": true }, "extraKnownMarketplaces": { "openviking-plugin": { "source": {} } } }\n' \
        "${HOME}" > "${dir}/settings.json"
}

@test "cleans the config dir named by CLAUDE_CONFIG_DIR, not just ~/.claude" {
    local alt="${TEST_HOME}/.claude-work"
    seed_alt_config_dir "${alt}"
    run env PATH="${FAKEBIN}:${PATH}" CLAUDE_CONFIG_DIR="${alt}" \
        "${VAULT_ROOT}/bin/remove-openviking.sh" --yes
    [ "$status" -eq 0 ]
    run grep -i openviking "${alt}/settings.json"
    [ "$status" -ne 0 ]
    # Unrelated plugins in that dir survive.
    [ "$(jq -r '.enabledPlugins["claude-mem@thedotmack"]' "${alt}/settings.json")" = "true" ]
    # ~/.claude is still cleaned in the same run.
    run grep -i openviking "${HOME}/.claude/settings.json"
    [ "$status" -ne 0 ]
}

@test "--config-dir cleans an extra config dir and is repeatable" {
    local a="${TEST_HOME}/.claude-a" b="${TEST_HOME}/.claude-b"
    seed_alt_config_dir "${a}"; seed_alt_config_dir "${b}"
    remove_ov --config-dir "${a}" --config-dir "${b}" --yes
    [ "$status" -eq 0 ]
    run grep -i openviking "${a}/settings.json"; [ "$status" -ne 0 ]
    run grep -i openviking "${b}/settings.json"; [ "$status" -ne 0 ]
}

@test "--config-dir with no argument exits non-zero" {
    remove_ov --config-dir
    [ "$status" -ne 0 ]
}

@test "drives the plugin + marketplace uninstall once per config dir" {
    local alt="${TEST_HOME}/.claude-work"
    seed_alt_config_dir "${alt}"
    stub claude 'echo "cfg=${CLAUDE_CONFIG_DIR} claude $*" >> '"${TEST_HOME}"'/log; exit 0'
    run env PATH="${FAKEBIN}:${PATH}" CLAUDE_CONFIG_DIR="${alt}" \
        "${VAULT_ROOT}/bin/remove-openviking.sh" --yes
    [ "$status" -eq 0 ]
    grep -q "cfg=${alt} claude plugin uninstall claude-code-memory-plugin@openviking-plugin" "${TEST_HOME}/log"
    grep -q "cfg=${HOME}/.claude claude plugin uninstall claude-code-memory-plugin@openviking-plugin" "${TEST_HOME}/log"
    grep -q "cfg=${alt} claude plugin marketplace remove openviking-plugin" "${TEST_HOME}/log"
}

@test "reports a config dir it did not visit instead of silently leaving it" {
    seed_alt_config_dir "${TEST_HOME}/.claude-stray"
    remove_ov --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"still references OpenViking"* ]]
    [[ "$output" == *"--config-dir ${TEST_HOME}/.claude-stray"* ]]
    # Reported only — an unvisited dir is never edited.
    grep -qi openviking "${TEST_HOME}/.claude-stray/settings.json"
}

@test "never touches the vault framework or a project vault" {
    mkdir -p "${HOME}/vault/_global" "${HOME}/.claude/commands"
    ln -s "${VAULT_ROOT}/commands/v-work.md" "${HOME}/.claude/commands/v-work.md"
    remove_ov --all --yes
    [ "$status" -eq 0 ]
    [ -d "${HOME}/vault/_global" ]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
}
