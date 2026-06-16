#!/usr/bin/env bats
# Tests for the /v-team command, persona library, and plan template — file contracts only.
# (Agent-loop behavior is validated by manual dry-runs, not unit tests.)

load "../helpers/setup.bash"

setup() {
    make_test_home
}

teardown() {
    cleanup_test_home
}

@test "install.sh symlinks the v-team command + steps dir" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    assert_symlink_to "${HOME}/.claude/commands/v-team.md" "${VAULT_ROOT}/commands/v-team.md"
    assert_symlink_to "${HOME}/.claude/commands/v-team"    "${VAULT_ROOT}/commands/v-team"
}

@test "v-team dispatcher has the looped step routing" {
    local f="${VAULT_ROOT}/commands/v-team.md"
    [ -f "${f}" ]
    grep -q 'v-team/steps/03-propose-loop.md' "${f}"
    grep -q 'v-team/steps/04-execute-loop.md' "${f}"
    # reuses v-work steps 01/02/05
    grep -q 'v-work/steps/01-analyze.md'        "${f}"
    grep -q 'v-work/steps/02-load-context.md'   "${f}"
    grep -q 'v-work/steps/05-commit-capture.md' "${f}"
}

@test "both v-team step files exist" {
    [ -f "${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md" ]
    [ -f "${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md" ]
}

@test "plan template exists with type: plan and a proposed-test backlog" {
    local f="${VAULT_ROOT}/templates/plan.md"
    [ -f "${f}" ]
    grep -qE '^type: plan$'            "${f}"
    grep -q  'Proposed test backlog'   "${f}"
    grep -q  'Critique trail'          "${f}"
}

@test "each shared persona declares type: persona and a base_agent" {
    for p in security performance quality skeptic; do
        local f="${VAULT_ROOT}/personas/_shared/${p}.md"
        [ -f "${f}" ] || { echo "missing shared persona: ${f}"; return 1; }
        grep -qE '^type: persona$'  "${f}"
        grep -qE '^base_agent: '    "${f}"
    done
}

@test "each stack pack is a persona-pack that composes shared + a local persona" {
    for pack in api-laravel nuxt flutter; do
        local f="${VAULT_ROOT}/personas/${pack}.md"
        [ -f "${f}" ] || { echo "missing pack: ${f}"; return 1; }
        grep -qE '^type: persona-pack$' "${f}"
        grep -qE '^use_shared: '        "${f}"
        grep -q  '## Persona:'          "${f}"   # at least one stack-local persona
    done
}

@test "resolution doc documents all three auto-detect markers + fallback" {
    local f="${VAULT_ROOT}/personas/_resolution.md"
    [ -f "${f}" ]
    grep -q 'composer.json'  "${f}"
    grep -q 'nuxt.config'    "${f}"
    grep -q 'pubspec.yaml'   "${f}"
    grep -qi 'fallback'      "${f}"
}

@test "VAULT.md template documents the v-team persona config keys" {
    local f="${VAULT_ROOT}/templates/VAULT.md"
    grep -q 'project_type:'             "${f}"
    grep -q 'team_max_rounds:'          "${f}"
    grep -q 'team_max_parallel_critics:' "${f}"
}
