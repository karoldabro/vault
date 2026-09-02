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

@test "plan template exists with type: plan and a test backlog" {
    local f="${VAULT_ROOT}/templates/plan.md"
    [ -f "${f}" ]
    grep -qE '^type: plan$'   "${f}"
    grep -q  'Test backlog'   "${f}"
    grep -q  'Work items'     "${f}"
}

@test "the plan template carries no process record, and points at the sidecar that does" {
    # The plan is a contract document: current truth only. Everything about how it was reached —
    # rounds, findings, rejected options — lives in templates/trail.md, or the plan grows past a
    # thousand lines again.
    local plan="${VAULT_ROOT}/templates/plan.md"
    local trail="${VAULT_ROOT}/templates/trail.md"
    [ -f "${trail}" ]
    grep -qE '^process_record:'          "${plan}"
    ! grep -q  'Critique trail'          "${plan}"
    ! grep -qE '^rounds:'                "${plan}"
    ! grep -qE '^convergence:'           "${plan}"
    ! grep -q  'Round 0'                 "${plan}"
    grep -qE '^type: trail$'             "${trail}"
    grep -q  'Findings & dispositions'   "${trail}"
    grep -q  'Rejected / deferred'       "${trail}"
}

@test "the plan template demands an exact file path per work item" {
    # The first thing lost when a plan is shortened is the path an implementing agent cannot
    # reconstruct. The table column is what protects it.
    grep -q 'file (exact path)' "${VAULT_ROOT}/templates/plan.md"
}

@test "the propose loop writes the trail to the sidecar, not into the plan" {
    local f="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -q 'trail sidecar'      "${f}"
    grep -q 'templates/trail.md' "${f}"
    ! grep -q 'as \*\*Round 0\*\*'  "${f}"
}

@test "the execute loop never prints rounds or convergence to the user" {
    # Both are process state, already barred by _shared/communication.md.
    local f="${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md"
    ! grep -qE '^Review rounds: <n>' "${f}"
    grep -q 'Never print'            "${f}"
}

@test "v-team commits the sidecar alongside the plan" {
    grep -q 'trail.md' "${VAULT_ROOT}/commands/v-team.md"
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

@test "skeptic persona carries the pre-mortem technique (ADR-017)" {
    local f="${VAULT_ROOT}/personas/_shared/skeptic.md"
    grep -qi 'pre-mortem'            "${f}"
    grep -qi 'prospective hindsight' "${f}"
}

@test "propose-loop synthesizer carries dissent + grounding-ownership hardening (ADR-017)" {
    local f="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -qi 'minority flag' "${f}"
    grep -qi 'sycophancy'    "${f}"
    grep -qi 'critic-owned'  "${f}"
}

@test "every ADR file is registered in decisions/_inventory.md" {
    local dir="${VAULT_ROOT}/vault/decisions"
    for f in "${dir}"/ADR-*.md; do
        local id
        id="$(basename "${f}" | grep -oE '^ADR-[0-9]+')"
        [ -n "${id}" ] || { echo "malformed ADR filename: ${f}"; return 1; }
        grep -q "${id}-" "${dir}/_inventory.md" || { echo "unregistered ADR: ${id}"; return 1; }
    done
}

@test "propose loop decomposes into session-sized units inside the appetite" {
    PL="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -qi 'f3'              "${PL}"
    grep -qi 'session-sized'   "${PL}"
    grep -qi 'appetite'        "${PL}"
    grep -qi 'ceiling'         "${PL}"
    grep -qi 'light-command-siblings' "${PL}"
    # /v-ask writes nothing, so it cannot be assigned a row
    grep -qi 'v-ask` is not eligible' "${PL}"
    # a deviation is the tracker working, not a failure
    grep -qi 'deviation'       "${PL}"
}

@test "feature pickup reports progress from the Sessions rows" {
    PU="${VAULT_ROOT}/commands/v-team/steps/00-feature-pickup.md"
    grep -q  '## Sessions'     "${PU}"
    grep -qi 'evidence'        "${PU}"
    grep -qi 'Progress'        "${PU}"
}

# --- the consumer seat -------------------------------------------------------------------
#
# The seat is called guaranteed, and nothing outside prose would notice if it stopped being seated.
# These are the ceiling: they catch the seat being deleted or quietly demoted to a relevance pick.
# They cannot catch a run that skipped it, because there is no runtime to check.

@test "the consumer persona exists and simulates rather than reviews" {
    local f="${VAULT_ROOT}/personas/_shared/consumer.md"
    [ -f "${f}" ]
    grep -q '^id: consumer'        "${f}"
    grep -q '^base_agent: '        "${f}"
    # The dry run is the whole method. A checklist-only version of this seat approves the handoff
    # that reads complete and is not, which is the defect it exists to catch.
    grep -qi 'literal text'        "${f}"
    grep -qi 'one real output'     "${f}"
}

@test "the consumer seat is guaranteed in all three selection regimes" {
    local f="${VAULT_ROOT}/personas/_resolution.md"
    # §2 dev packs, §2.1 testing group, §2.2 business packs each carry their own seat list. A seat
    # written into one of them only is not guaranteed; it is guaranteed for dev work and absent
    # everywhere else.
    [ "$(grep -c 'consumer' "${f}")" -ge 3 ]
    grep -q 'always in on the PROPOSE panel'                    "${f}"
    grep -q 'never dropped by the cap'                          "${f}"
    grep -q 'The testing group replaces the mechanism lenses'   "${f}"
    grep -q 'the primary architect, or `consumer`'              "${f}"
}

@test "the cap may be raised rather than dropping a triggered lens" {
    # architect + consumer + a triggered lens + skeptic is four seats against a default of three.
    # Without this line the resolution silently drops the lens the change itself implicated.
    grep -q 'raise' "${VAULT_ROOT}/personas/_resolution.md"
    tr '\n' ' ' < "${VAULT_ROOT}/personas/_resolution.md" \
        | grep -q '`team_max_parallel_critics` to 4'
}

@test "the propose loop spawns the seat and demands its dry run" {
    local f="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -q '_shared/consumer.md'  "${f}"
    grep -qi 'literal text'        "${f}"
    # The envelope must say where the dry run goes, or the critic returns prose instead of grounding.
    grep -q '`check` field'        "${f}"
}

@test "v-work writes the plan artifact its own output contract describes" {
    local f="${VAULT_ROOT}/commands/v-work/steps/03-propose.md"
    # The step described a Layer 2 artifact and named no path, so /v-work wrote no plan file and
    # nothing mechanical ever saw its work.
    grep -q 'templates/plan.md'    "${f}"
    grep -q 'plans/YYYY-MM-DD-HHMM' "${f}"
    grep -q 'doc-lint.sh <plan>'   "${f}"
    # It runs no panel, so it must not claim a trail sidecar.
    grep -q 'no trail sidecar'     "${f}"
}

@test "the commit step stages the plan artifact" {
    grep -q 'Stage the plan artifact too' "${VAULT_ROOT}/commands/v-work/steps/05-commit-capture.md"
}

@test "the plan template carries the artifact lifecycle table" {
    local f="${VAULT_ROOT}/templates/plan.md"
    grep -q '^## Artifact lifecycles' "${f}"
    grep -q 'what requires it'        "${f}"
    grep -q 'missing or wrong'        "${f}"
    # The `none` escape must be shown, not described: the first version described it and the two
    # plausible shapes an author would write both failed the check they were meant to escape.
    grep -qF '| none | this plan edits three existing files and hands nothing to anyone | | | |' "${f}"
}
