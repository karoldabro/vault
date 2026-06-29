#!/usr/bin/env bats
# Contracts for the generative test-design fan-out (split-test-planning-step):
# the design/ generator group, the system-domain-expert critic, and the PROPOSE (f2) wiring.
# File contracts only — agent-loop behavior is validated by manual dry-runs.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    TESTING_DIR="${VAULT_ROOT}/personas/_shared/testing"
    DESIGN_DIR="${TESTING_DIR}/design"
    GENERATORS="fault-relation-prospector business-logic-cartographer boundary-property-explorer"
}

@test "design generator group dir exists with a README index" {
    [ -d "${DESIGN_DIR}" ]
    [ -f "${DESIGN_DIR}/README.md" ]
    grep -qE '^group: testing-design$' "${DESIGN_DIR}/README.md"
}

@test "all three generators exist with valid generator frontmatter" {
    for g in ${GENERATORS}; do
        local f="${DESIGN_DIR}/${g}.md"
        [ -f "${f}" ] || { echo "missing generator: ${f}"; return 1; }
        grep -qE '^type: persona$'                       "${f}"
        grep -qE "^id: ${g}$"                            "${f}"
        grep -qE '^group: testing-design$'               "${f}"
        grep -qE '^base_agent: '                         "${f}"
        grep -q  'tags: \[persona, shared, testing, generator\]' "${f}"
    done
}

@test "generators bind NO analyzer and ground in the design plan (not code)" {
    for g in ${GENERATORS}; do
        local f="${DESIGN_DIR}/${g}.md"
        # The whole point of the decorrelation: generators must not carry a critic's Bound analyzer.
        ! grep -q '## Bound analyzer' "${f}" || { echo "${g}: must not bind an analyzer"; return 1; }
        grep -qi 'design plan'        "${f}" || { echo "${g}: no design-plan grounding"; return 1; }
        grep -q  '## Output'          "${f}" || { echo "${g}: no Output section"; return 1; }
    done
}

@test "each generator declares BOTH vertical (->critic) and horizontal (->generator) decorrelation" {
    for g in ${GENERATORS}; do
        local f="${DESIGN_DIR}/${g}.md"
        grep -q  '## Decorrelation'        "${f}" || { echo "${g}: no Decorrelation section"; return 1; }
        # vertical: names a critic it defers to
        grep -q  'NOT → edge-case-hunter'  "${f}" || { echo "${g}: no vertical NOT->critic"; return 1; }
        # horizontal: names another generator
        grep -qE 'NOT → (fault-relation-prospector|business-logic-cartographer|boundary-property-explorer)' "${f}" \
            || { echo "${g}: no horizontal NOT->generator"; return 1; }
    done
}

@test "system-domain-expert critic exists with a real two-stage bound analyzer" {
    local f="${TESTING_DIR}/system-domain-expert.md"
    [ -f "${f}" ]
    grep -qE '^id: system-domain-expert$'             "${f}"
    grep -q  'tags: \[persona, shared, testing\]'     "${f}"
    grep -q  '## Bound analyzer'                      "${f}"
    grep -q  '## Mandate'                             "${f}"
    grep -q  '## Severity rubric'                     "${f}"
    grep -q  '## Checklist'                           "${f}"
    grep -q  '## Output'                              "${f}"
    # absence is confirmed by coverage, not a bare keyword grep (skeptic-r2-2)
    grep -qi 'coverage'                               "${f}"
    grep -qi 'indications'                            "${f}"
}

@test "(f2) sub-phase is wired into PROPOSE: generation-only, sole backlog writer, dedup, hint sink" {
    local f="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -q  '(f2)'                            "${f}"
    grep -qi 'sole authoritative writer'       "${f}"
    grep -qi 'no confirmation'                 "${f}"
    grep -qi 'dedup'                           "${f}"
    grep -qi 'Advisory test hints'             "${f}"
    grep -qi 'fail open'                       "${f}"
}

@test "design-critic PROPOSED_TESTS are demoted to advisory hints" {
    local f="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -qi 'advisory test hints' "${f}"
    grep -qi 'not.*authoritative\|sole authoritative writer' "${f}"
}

@test "EXECUTE loop confirms the dossier post-impl and seats the system-domain-expert" {
    local f="${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md"
    grep -qi 'system-domain-expert'            "${f}"
    grep -qi 'generate→confirm\|generate→confirm loop\|post-impl half' "${f}"
}

@test "design README routes metamorphic/property artifacts to assertion-auditor" {
    local f="${DESIGN_DIR}/README.md"
    grep -qi 'metamorphic'      "${f}"
    grep -qi 'assertion-auditor' "${f}"
    grep -qi 'traceability'     "${f}"
}

@test "resolution doc (2.1a) seats domain-expert regardless of glob and never selects generators" {
    local f="${VAULT_ROOT}/personas/_resolution.md"
    grep -q  '2.1a'                              "${f}"
    grep -qi 'never selected\|never.*panel'      "${f}"
    grep -qi 'regardless of the test-file glob'  "${f}"
    grep -qi 'system-domain-expert'              "${f}"
}

@test "plan template has Test Design Dossier, source column, and traceability rule" {
    local f="${VAULT_ROOT}/templates/plan.md"
    grep -q  'Test Design Dossier'   "${f}"
    grep -qi 'traceability'          "${f}"
    grep -q  '| id | source |'       "${f}"
}

@test "v-team dispatcher documents the (f2) fan-out + cost envelope" {
    local f="${VAULT_ROOT}/commands/v-team.md"
    grep -qi 'team_max_test_designers' "${f}"
    grep -q  '(f2)'                     "${f}"
}

@test "VAULT template documents team_max_test_designers" {
    grep -q 'team_max_test_designers:' "${VAULT_ROOT}/templates/VAULT.md"
}

@test "v-work 03-propose gains decision-table + name-the-fault vocabulary" {
    local f="${VAULT_ROOT}/commands/v-work/steps/03-propose.md"
    grep -qi 'decision table' "${f}"
    grep -qi 'name.*fault\|fault that would break' "${f}"
}
