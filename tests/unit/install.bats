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
    for cmd in v-init v-work v-capture v-link v-do v-ask; do
        assert_symlink_to "${HOME}/.claude/commands/${cmd}.md" "${VAULT_ROOT}/commands/${cmd}.md"
    done
}

@test "install.sh installs no README and no attic" {
    # Both now live outside commands/ so the plugin's default scan can't pick them
    # up either; the skip_file/skip_dir arguments stay as belt and braces.
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    [ ! -e "${HOME}/.claude/commands/README.md" ]
    [ ! -e "${HOME}/.claude/commands/attic" ]
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

# --- opt-in activation flags -------------------------------------------------------------------

@test "install.sh links the style but does not switch it on without a flag" {
    # Linking and activating are separate steps. The default must never touch settings.json.
    local home="${BATS_TEST_TMPDIR}/h"; mkdir -p "${home}/.claude"
    printf '{"permissions":{"allow":[]}}' > "${home}/.claude/settings.json"
    HOME="${home}" run bash "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    run grep -c outputStyle "${home}/.claude/settings.json"
    [ "$output" -eq 0 ]
}

@test "--enable-style writes the global setting and keeps what was there" {
    local home="${BATS_TEST_TMPDIR}/h2"; mkdir -p "${home}/.claude"
    printf '{"permissions":{"allow":["Bash"]}}' > "${home}/.claude/settings.json"
    HOME="${home}" run bash "${VAULT_ROOT}/install.sh" --enable-style
    [ "$status" -eq 0 ]
    grep -q '"outputStyle": "director"' "${home}/.claude/settings.json"
    grep -q '"permissions"'             "${home}/.claude/settings.json"
}

@test "--enable-doc-lint registers the hook once, however many times it runs" {
    local home="${BATS_TEST_TMPDIR}/h3"; mkdir -p "${home}/.claude"
    printf '{}' > "${home}/.claude/settings.json"
    HOME="${home}" bash "${VAULT_ROOT}/install.sh" --enable-doc-lint >/dev/null
    HOME="${home}" bash "${VAULT_ROOT}/install.sh" --enable-doc-lint >/dev/null
    run grep -c 'doc-lint-hook' "${home}/.claude/settings.json"
    [ "$output" -eq 1 ]
}

@test "a default run leaves settings.json with neither brevity hook registered" {
    # Same rule as the style: linking is not activating. Without the flag the two hooks are on
    # disk and inert, which is the only state that does not surprise someone running the installer.
    local home="${BATS_TEST_TMPDIR}/h4"; mkdir -p "${home}/.claude"
    printf '{}' > "${home}/.claude/settings.json"
    HOME="${home}" run bash "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    run grep -c 'brevity\|output-lint' "${home}/.claude/settings.json"
    [ "$output" -eq 0 ]
}

@test "--enable-brevity registers both hooks once, however many times it runs" {
    local home="${BATS_TEST_TMPDIR}/h5"; mkdir -p "${home}/.claude"
    printf '{}' > "${home}/.claude/settings.json"
    HOME="${home}" bash "${VAULT_ROOT}/install.sh" --enable-brevity >/dev/null
    HOME="${home}" bash "${VAULT_ROOT}/install.sh" --enable-brevity >/dev/null
    run grep -c 'output-lint-hook' "${home}/.claude/settings.json"
    [ "$output" -eq 1 ]
    run grep -c 'brevity-reminder-hook' "${home}/.claude/settings.json"
    [ "$output" -eq 1 ]
}

@test "registering the brevity hooks leaves an unrelated Stop entry in place" {
    # He already runs observability hooks on Stop. Appending to that bucket must not replace it.
    local home="${BATS_TEST_TMPDIR}/h6"; mkdir -p "${home}/.claude"
    printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"my-observability.py"}]}]}}' \
        > "${home}/.claude/settings.json"
    HOME="${home}" bash "${VAULT_ROOT}/install.sh" --enable-brevity >/dev/null
    grep -q 'my-observability.py'  "${home}/.claude/settings.json"
    grep -q 'output-lint-hook'     "${home}/.claude/settings.json"
    run jq -r '.hooks.Stop | length' "${home}/.claude/settings.json"
    [ "$output" -eq 2 ]
}

@test "--enable-all switches on the style and every shipped hook" {
    local home="${BATS_TEST_TMPDIR}/h7"; mkdir -p "${home}/.claude"
    printf '{}' > "${home}/.claude/settings.json"
    HOME="${home}" bash "${VAULT_ROOT}/install.sh" --enable-all >/dev/null
    grep -q '"outputStyle": "director"' "${home}/.claude/settings.json"
    grep -q 'doc-lint-hook'             "${home}/.claude/settings.json"
    grep -q 'output-lint-hook'          "${home}/.claude/settings.json"
    grep -q 'brevity-reminder-hook'     "${home}/.claude/settings.json"
}

@test "every hook in the installer's list ships a script that exists" {
    # The list is the single place a hook is declared; a typo there installs a dangling symlink.
    local row script
    while IFS= read -r row; do
        script="${row%%;*}"
        [ -f "${VAULT_ROOT}/scripts/${script}" ] \
            || { echo "installer lists a missing hook script: ${script}"; return 1; }
    done < <(sed -n '/^HOOK_ROWS=(/,/^)/p' "${VAULT_ROOT}/install.sh" \
             | grep -oE '"[a-z-]+\.sh;[^"]*"' | tr -d '"')
}

@test "an unknown flag is refused rather than ignored" {
    run bash "${VAULT_ROOT}/install.sh" --enable-everything
    [ "$status" -eq 2 ]
}

@test "INSTALL.md documents every flag and the scope trap" {
    local f="${VAULT_ROOT}/INSTALL.md"
    grep -q -- '--enable-style'     "${f}"
    grep -q -- '--enable-doc-lint'  "${f}"
    grep -q -- '--enable-brevity'   "${f}"
    grep -q    'BREVITY=off'        "${f}"
    # /config writes project-local settings; that is the thing people get wrong.
    grep -q 'settings.local.json'   "${f}"
}
