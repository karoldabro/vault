#!/usr/bin/env bats
# Tests for the Claude Code plugin install path: the two manifests, the repo
# layout the plugin loader assumes, the SessionStart detect hook, and the guard
# that keeps the plugin and the symlink install from both being active.

load "../helpers/setup.bash"

setup() {
    make_test_home
}

teardown() {
    cleanup_test_home
}

# --- manifests ---------------------------------------------------------------

@test "plugin.json is valid JSON with a kebab-case name" {
    run jq -e . "${VAULT_ROOT}/.claude-plugin/plugin.json"
    [ "$status" -eq 0 ]
    name="$(jq -r '.name' "${VAULT_ROOT}/.claude-plugin/plugin.json")"
    [ "${name}" = "vault" ]
    [[ "${name}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

@test "plugin.json pins a semver version" {
    # Claude Code keys its cache on this string. Without it, every commit to main
    # ships to everyone who installed the plugin; with a malformed one, nothing does.
    local v
    v="$(jq -r '.version' "${VAULT_ROOT}/.claude-plugin/plugin.json")"
    [[ "${v}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "not semver: ${v}"; return 1; }
}

@test "the version is pinned in exactly one place" {
    # Set in both plugin.json and the marketplace entry, plugin.json silently wins
    # and the marketplace copy drifts into a lie. Keep it in plugin.json only.
    [ "$(jq -r '.plugins[0].version // "unset"' "${VAULT_ROOT}/.claude-plugin/marketplace.json")" = "unset" ]
}

@test "marketplace.json is valid JSON with an owner and one plugin entry" {
    local m="${VAULT_ROOT}/.claude-plugin/marketplace.json"
    run jq -e . "${m}"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.owner.name' "${m}")" != "null" ]
    [ "$(jq -r '.plugins | length' "${m}")" -eq 1 ]
    # source "./" means the marketplace repo IS the plugin — one repo, one clone.
    [ "$(jq -r '.plugins[0].source' "${m}")" = "./" ]
}

@test "the marketplace entry names the same plugin as plugin.json" {
    a="$(jq -r '.name' "${VAULT_ROOT}/.claude-plugin/plugin.json")"
    b="$(jq -r '.plugins[0].name' "${VAULT_ROOT}/.claude-plugin/marketplace.json")"
    [ "${a}" = "${b}" ]
}

@test "the marketplace name is not one Anthropic reserves" {
    # A reserved name stops the marketplace loading entirely, and the list grows —
    # this catches a rename onto a name that only looks available.
    local name reserved
    name="$(jq -r '.name' "${VAULT_ROOT}/.claude-plugin/marketplace.json")"
    for reserved in claude-code-marketplace claude-code-plugins claude-plugins-official \
                    claude-plugins-community claude-community anthropic-marketplace \
                    anthropic-plugins agent-skills anthropic-agent-skills \
                    knowledge-work-plugins life-sciences claude-for-legal \
                    claude-for-financial-services financial-services-plugins \
                    first-party-plugins healthcare; do
        [ "${name}" != "${reserved}" ] || { echo "reserved marketplace name: ${name}"; return 1; }
    done
    # Names that impersonate an official source are blocked too.
    [[ ! "${name}" =~ ^(official|anthropic) ]]
}

# --- layout the plugin loader assumes ----------------------------------------

@test ".claude-plugin/ holds only the two manifests" {
    # Components inside .claude-plugin/ are silently not loaded — the single most
    # common way to ship a plugin that installs but does nothing.
    local stray
    stray="$(find "${VAULT_ROOT}/.claude-plugin" -mindepth 1 \
        ! -name 'plugin.json' ! -name 'marketplace.json' | wc -l | tr -d ' ')"
    [ "${stray}" -eq 0 ] || { find "${VAULT_ROOT}/.claude-plugin" -mindepth 1; return 1; }
}

@test "components sit at the plugin root where the default scan finds them" {
    [ -d "${VAULT_ROOT}/commands" ]
    [ -d "${VAULT_ROOT}/output-styles" ]
    [ -f "${VAULT_ROOT}/hooks/hooks.json" ]
    [ -d "${VAULT_ROOT}/scripts" ]
}

@test "commands/ contains no README and no attic" {
    # The plugin scans every .md under commands/. Anything parked there becomes an
    # invocable command, so docs and archived commands live outside it.
    [ ! -e "${VAULT_ROOT}/commands/README.md" ]
    [ ! -d "${VAULT_ROOT}/commands/attic" ]
    [ -f "${VAULT_ROOT}/docs/commands.md" ]
    [ -d "${VAULT_ROOT}/attic" ]
}

@test "every top-level command has a description in its frontmatter" {
    # The description is what the plugin picker and the model both read.
    local f missing=0
    for f in "${VAULT_ROOT}"/commands/v-*.md; do
        head -5 "${f}" | grep -q '^description:' || { echo "no description: ${f}"; missing=1; }
    done
    [ "${missing}" -eq 0 ]
}

# --- path portability --------------------------------------------------------

@test "no command file hardcodes ~/.claude/commands" {
    # Under a plugin install the framework lives in a versioned cache directory,
    # not ~/.claude/commands. A hardcoded path there silently reads the OTHER
    # install's files, or nothing at all.
    run grep -rn '~/\.claude/commands' "${VAULT_ROOT}/commands"
    [ "$status" -ne 0 ] || { echo "hardcoded path: ${output}"; return 1; }
}

@test "every dispatcher resolves the framework root before using it" {
    local f missing=0
    for f in "${VAULT_ROOT}"/commands/v-*.md; do
        grep -qF 'CLAUDE_PLUGIN_ROOT' "${f}" || { echo "no framework-root rule: ${f}"; missing=1; }
    done
    [ "${missing}" -eq 0 ]
}

@test "no command file opens with the path note" {
    # A file with no frontmatter takes its picker description from its first line.
    # The path note leading the file makes every step read "Path note: ..." there.
    local f bad=0
    while IFS= read -r f; do
        head -1 "${f}" | grep -q '^> Path note:' && { echo "note leads file: ${f}"; bad=1; }
    done < <(find "${VAULT_ROOT}/commands" -name '*.md')
    [ "${bad}" -eq 0 ]
}

@test "every step file that uses the framework root also says how to resolve it" {
    # Step files are loaded on demand, often many turns after the dispatcher that
    # resolved the path. Each has to be able to re-resolve it on its own.
    local f missing=0
    while IFS= read -r f; do
        grep -qF 'CLAUDE_PLUGIN_ROOT' "${f}" || { echo "no path note: ${f}"; missing=1; }
    done < <(grep -rl 'VAULT_FRAMEWORK_PATH' "${VAULT_ROOT}/commands")
    [ "${missing}" -eq 0 ]
}

@test "the framework-root rule prefers the plugin path over the recorded config" {
    # Order matters: the plugin cache path changes on every update, so a stale
    # framework_path in config.md must never win over the live one.
    local step="${VAULT_ROOT}/commands/v-work/steps/01-analyze.md"
    grep -qF 'CLAUDE_PLUGIN_ROOT' "${step}"
    [ "$(grep -c 'CLAUDE_PLUGIN_ROOT' "${VAULT_ROOT}/vault-guide.md")" -ge 1 ]
    # In the guide's ordered list the plugin path is item 1.
    grep -q '^1\. \*\*`${CLAUDE_PLUGIN_ROOT}`\*\*' "${VAULT_ROOT}/vault-guide.md"
}

# --- SessionStart detect hook ------------------------------------------------

@test "hooks.json is valid JSON and wires SessionStart to a bundled script" {
    local h="${VAULT_ROOT}/hooks/hooks.json"
    run jq -e . "${h}"
    [ "$status" -eq 0 ]
    cmd="$(jq -r '.hooks.SessionStart[0].hooks[0].command' "${h}")"
    [[ "${cmd}" == *'${CLAUDE_PLUGIN_ROOT}'* ]]
    [[ "${cmd}" == *'detect-stack.sh'* ]]
    [ -x "${VAULT_ROOT}/scripts/detect-stack.sh" ]
}

@test "the detect hook installs nothing" {
    # It runs unattended at session start. Anything that mutates the machine there
    # would bypass the consent gate ADR-005 commits the installer to.
    run grep -nE '^[^#]*\b(apt|apt-get|curl|wget|npm|pnpm|bun|pipx|uv|sudo)\b' \
        "${VAULT_ROOT}/scripts/detect-stack.sh"
    [ "$status" -ne 0 ] || { echo "detect hook has an install path: ${output}"; return 1; }
}

@test "the detect hook points at /v-setup when the machine layer is missing" {
    run "${VAULT_ROOT}/scripts/detect-stack.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/v-setup"* ]]
}

@test "the detect hook never reports the developer tools as missing" {
    # Serena and Graphify ship only in the --full profile, so on a normal light
    # install their absence is the expected state. Naming them would report
    # normality as a problem (ADR-021).
    run "${VAULT_ROOT}/scripts/detect-stack.sh"
    [ "$status" -eq 0 ]
    [[ "${output,,}" != *"graphify"* ]]
    [[ "${output,,}" != *"serena"* ]]
}

@test "the detect hook is silent once the machine layer exists" {
    mkdir -p "${HOME}/vault/_global"
    echo "vault_home: ${HOME}/vault" > "${HOME}/vault/_global/config.md"
    run "${VAULT_ROOT}/scripts/detect-stack.sh"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "the detect hook exits 0 even with no HOME" {
    # A non-zero SessionStart hook must never be able to block a session.
    run env -u HOME "${VAULT_ROOT}/scripts/detect-stack.sh"
    [ "$status" -eq 0 ]
}

# --- double-install guard ----------------------------------------------------

@test "install.sh refuses when the vault plugin is recorded in settings" {
    mkdir -p "${HOME}/.claude"
    echo '{"enabledPlugins": {"vault@kdabro-vault": true}}' > "${HOME}/.claude/settings.json"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"REFUSED"* ]]
    [ ! -e "${HOME}/.claude/commands/v-work.md" ]
}

@test "install.sh still runs when an unrelated plugin is installed" {
    mkdir -p "${HOME}/.claude"
    echo '{"enabledPlugins": {"claude-mem@some-marketplace": true}}' > "${HOME}/.claude/settings.json"
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
}

@test "install.sh refuses when it is running from the plugin cache" {
    # Symlinking out of the plugin cache leaves dangling links at the next update.
    local fake="${HOME}/.claude/plugins/cache/vault-abc123"
    mkdir -p "${fake}/lib"
    cp "${VAULT_ROOT}/install.sh" "${fake}/install.sh"
    cp "${VAULT_ROOT}/lib/plugin-detect.sh" "${fake}/lib/plugin-detect.sh"
    run "${fake}/install.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"REFUSED"* ]]
    [[ "$output" == *"/v-setup"* ]]
}

@test "VAULT_ALLOW_DOUBLE_INSTALL=1 overrides the guard" {
    mkdir -p "${HOME}/.claude"
    echo '{"enabledPlugins": {"vault@kdabro-vault": true}}' > "${HOME}/.claude/settings.json"
    VAULT_ALLOW_DOUBLE_INSTALL=1 run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ -L "${HOME}/.claude/commands/v-work.md" ]
}

# --- /v-setup ----------------------------------------------------------------

@test "/v-setup exists, gates on consent, and never runs under sudo" {
    local f="${VAULT_ROOT}/commands/v-setup.md"
    [ -f "${f}" ]
    grep -qF 'setup.sh' "${f}"
    grep -qi 'STOP' "${f}"
    grep -qi 'sudo' "${f}"
    grep -qi -- '--doctor' "${f}"
}

@test "setup.sh skips the symlink step under a plugin install" {
    grep -q 'vault_running_from_plugin_cache\|vault_plugin_installed' "${VAULT_ROOT}/setup.sh"
    grep -q 'plugin-detect.sh' "${VAULT_ROOT}/setup.sh"
}
