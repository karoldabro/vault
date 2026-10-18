#!/usr/bin/env bats
# Behaviour of bin/vault-check.sh: the check point path and the fallback to the repo's own commands.
#
# Contract: vault/architecture/plugin-extension-contract.md, `check` point.
# Plan: vault/plans/2026-10-18-1257-quality-loops.md, D-1 to D-5.

load "../helpers/setup.bash"

setup() {
    make_test_home
    export VAULT_HOME="${TEST_HOME}/vault-home"
    CHECK_SH="${VAULT_ROOT}/bin/vault-check.sh"
    PLUGIN_SH="${VAULT_ROOT}/bin/vault-plugin.sh"
    git config --global user.email t@example.com; git config --global user.name t
    git config --global init.defaultBranch main
}

teardown() { cleanup_test_home; }

# make_repo <name> [<VAULT.md lines>...] — a git repo with one commit and the given VAULT.md lines.
make_repo() {
    local dir="${TEST_HOME}/$1"; shift
    mkdir -p "${dir}"
    printf '%s\n' "$@" > "${dir}/VAULT.md"
    git -C "${dir}" init --quiet && git -C "${dir}" add -A && git -C "${dir}" commit --quiet -m init
    printf '%s\n' "${dir}"
}

# use_plugin [<dir>] — register a copy of the fixture check plugin, at <dir> when given.
use_plugin() {
    local dir=${1:-${TEST_HOME}/check-plugin}
    mkdir -p "$(dirname "${dir}")"
    cp -r "${VAULT_ROOT}/tests/fixtures/plugins/check-plugin" "${dir}"
    "${PLUGIN_SH}" add "${dir}" >/dev/null
}

# --- the check point --------------------------------------------------------------------

@test "plugin exit 0 with a coverage line at the floor exits 0" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_LINES='coverage\t85\t80' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *$'coverage\t85\t80'* ]]
}

@test "plugin exit 1 passes through as exit 1" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_EXIT=1 CHECK_FIXTURE_LINES='finding\ta.php:3\trule\tmsg' run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 1 ]
    [[ "$output" == *"a.php:3"* ]]
}

@test "plugin exit 2 passes through as exit 2" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_EXIT=2 run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
}

@test "plugin exit 3 and 127 clamp to exit 2 and never run the fallback" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin' 'lint_command: echo FALLBACK-RAN')
    for code in 3 127; do
        CHECK_FIXTURE_EXIT=$code run "${CHECK_SH}" static --repo "$r" --base HEAD
        [ "$status" -eq 2 ]
        [[ "$output" == *"could not run"* ]]
        [[ "$output" != *"FALLBACK-RAN"* ]]
    done
}

@test "two plugins: the highest exit wins" {
    use_plugin; use_plugin "${TEST_HOME}/second/check-plugin-b"
    sed -i 's/^check-plugin\t/check-plugin-b\t/' "${TEST_HOME}/second/check-plugin-b/extend/plugin.tsv"
    printf '#!/usr/bin/env bash\nexit 1\n' > "${TEST_HOME}/second/check-plugin-b/extend/check.sh"
    "${PLUGIN_SH}" add "${TEST_HOME}/second/check-plugin-b" >/dev/null
    local r; r=$(make_repo r 'plugins: check-plugin, check-plugin-b')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 1 ]
}

@test "a registered check plugin the repo is not opted in to is not run" {
    use_plugin; local r; r=$(make_repo r 'lint_command: true')
    CHECK_FIXTURE_EXIT=1 run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"fallback"* ]]
}

@test "coverage below the 80 floor exits 1 and a plugin floor below 80 prints floor-below" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_LINES='coverage\t75\t70' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 1 ]
    [[ "$output" == *$'floor-below\t70\t80'* ]]
    CHECK_FIXTURE_LINES='coverage\t85\t90' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 1 ]
}

@test "coverage none meets the floor" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_LINES='coverage\tnone\t-' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
}

@test "a tests point that exits 0 with no coverage line exits 2" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_LINES='survivor\ta.php:3\tPlus' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"printed no coverage line"* ]]
}

@test "the point receives stage, repo and base, and untracked files in the changed list" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    echo new > "$r/untracked.txt"; echo more >> "$r/VAULT.md"
    CHECK_FIXTURE_ARGS="${TEST_HOME}/args" CHECK_FIXTURE_FILES="${TEST_HOME}/files" \
        run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$(sed -n 1p "${TEST_HOME}/args")" = static ]
    [ "$(sed -n 2p "${TEST_HOME}/args")" = "$r" ]
    [ "$(sed -n 3p "${TEST_HOME}/args")" = HEAD ]
    grep -qx untracked.txt "${TEST_HOME}/files"
    grep -qx VAULT.md "${TEST_HOME}/files"
}

@test "a plugin path with a space runs" {
    use_plugin "${TEST_HOME}/dir with space/check-plugin"; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_LINES='coverage\t90\t80' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
}

@test "a point past VAULT_CHECK_TIMEOUT exits 2 (timeout)" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    VAULT_CHECK_TIMEOUT=1 CHECK_FIXTURE_SLEEP=5 run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"timed out"* ]]
}

@test "output over the line cap states the withheld count" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    VAULT_CHECK_LINES=2 CHECK_FIXTURE_LINES='finding\ta:1\tr\tm\nfinding\ta:2\tr\tm\nfinding\ta:3\tr\tm' \
        run "${CHECK_SH}" static --repo "$r" --base HEAD
    [[ "$output" == *$'withheld\t1 of 3 lines'* ]]
    [[ "$output" != *"a:3"* ]]
}

# --- the fallback -----------------------------------------------------------------------

@test "fallback static: a passing lint_command exits 0, a failing one exit 1" {
    local r; r=$(make_repo r 'lint_command: true')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *$'fallback\tscope repo'* ]]
    r=$(make_repo r2 'lint_command: false')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 1 ]
}

@test "fallback tests prints unmeasured coverage and mutation lines" {
    local r; r=$(make_repo r 'test_command: echo ran')
    run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *$'unmeasured\tcoverage'* ]]
    [[ "$output" == *$'unmeasured\tmutation'* ]]
    [[ "$output" == *"ran"* ]]
}

@test "an absent key exits 2 with its reason, and a missing key exits 2" {
    local r; r=$(make_repo r 'lint_command: absent: no linter here')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"no linter here"* ]]
    r=$(make_repo r2 'slug: x')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"missing"* ]]
}

@test "a template test_command exits 2 naming the template" {
    local r; r=$(make_repo r 'test_command: vendor/bin/phpunit <path> [--filter=...]')
    run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"is a template"* ]]
}

@test "a trailing comment is removed before the command runs" {
    local r; r=$(make_repo r 'lint_command: true   # never in the app container')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
}

@test "a command not found exits 2" {
    local r; r=$(make_repo r 'lint_command: no-such-tool-anywhere --check')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"could not run"* ]]
}

@test "usage errors exit 2" {
    run "${CHECK_SH}" lint --repo /tmp --base HEAD
    [ "$status" -eq 2 ]
    run "${CHECK_SH}" static --repo /tmp
    [ "$status" -eq 2 ]
}

# --- review fixes -----------------------------------------------------------------------

@test "a base that is not a commit exits 2 and runs nothing" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_LINES='coverage\tnone\t-' run "${CHECK_SH}" tests --repo "$r" --base no-such-ref
    [ "$status" -eq 2 ]
    [[ "$output" == *"is not a commit"* ]]
    [[ "$output" != *"coverage"*"none"* ]]
}

@test "a tests point that exits 1 with no coverage line stays exit 1" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    CHECK_FIXTURE_EXIT=1 CHECK_FIXTURE_LINES='failed\tT::a\tboom' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 1 ]
}

@test "a registry with a duplicate row exits 2 and never runs the fallback" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin' 'lint_command: echo FALLBACK-RAN')
    tail -1 "${VAULT_HOME}/_global/plugins.tsv" >> "${VAULT_HOME}/_global/plugins.tsv"
    CHECK_FIXTURE_EXIT=1 run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" != *"FALLBACK-RAN"* ]]
}

@test "the script's own unmeasured line survives the output cap" {
    use_plugin; local r; r=$(make_repo r 'plugins: check-plugin')
    VAULT_CHECK_LINES=1 CHECK_FIXTURE_LINES='survivor\ta:1\tm\nsurvivor\ta:2\tm' run "${CHECK_SH}" tests --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"printed no coverage line"* ]]
}

@test "a redirect is a command, a placeholder is a template, and invalid shell exits 2" {
    local r; r=$(make_repo r 'lint_command: cat < VAULT.md > /dev/null')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 0 ]
    r=$(make_repo r2 'lint_command: grep -q "a # b" VAULT.md')
    run "${CHECK_SH}" static --repo "$r" --base HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"not valid shell"* ]]
}
