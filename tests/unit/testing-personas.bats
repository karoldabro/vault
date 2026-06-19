#!/usr/bin/env bats
# Tests for the testing critic group (personas/_shared/testing/) — file contracts + grounding rule.
# Agent-loop behavior is validated by manual dry-runs, not unit tests.

load "../helpers/setup.bash"

setup() {
    # Read-only file-contract tests; no isolated HOME needed, just the repo root.
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    TESTING_DIR="${VAULT_ROOT}/personas/_shared/testing"
    TESTING_PERSONAS="test-behaviorist assertion-auditor edge-case-hunter test-double-critic flakiness-sentinel test-harness-critic"
}

@test "testing group dir exists with a README index" {
    [ -d "${TESTING_DIR}" ]
    [ -f "${TESTING_DIR}/README.md" ]
    grep -qE '^group: testing$' "${TESTING_DIR}/README.md"
}

@test "all six testing personas exist with valid frontmatter" {
    for p in ${TESTING_PERSONAS}; do
        local f="${TESTING_DIR}/${p}.md"
        [ -f "${f}" ] || { echo "missing testing persona: ${f}"; return 1; }
        grep -qE '^type: persona$'     "${f}"
        grep -qE "^id: ${p}$"          "${f}"
        grep -qE '^base_agent: '       "${f}"
        grep -q  'tags: \[persona, shared, testing\]' "${f}"
    done
}

@test "each testing persona has the required template sections" {
    for p in ${TESTING_PERSONAS}; do
        local f="${TESTING_DIR}/${p}.md"
        grep -q '## Mandate'        "${f}" || { echo "${p}: no Mandate"; return 1; }
        grep -q '## Bound analyzer' "${f}" || { echo "${p}: no Bound analyzer"; return 1; }
        grep -q '## Severity rubric' "${f}" || { echo "${p}: no Severity rubric"; return 1; }
        grep -q '## Checklist'      "${f}" || { echo "${p}: no Checklist"; return 1; }
        grep -q '## Output'         "${f}" || { echo "${p}: no Output"; return 1; }
    done
}

@test "grounding rule: each testing persona binds a real analyzer (not 'none')" {
    # Every testing lens must name a concrete analyzer under its Bound analyzer section.
    for p in ${TESTING_PERSONAS}; do
        local f="${TESTING_DIR}/${p}.md"
        # The section must exist and reference at least one real tool/command keyword.
        grep -qiE 'mutation|coverage|--shuffle|--order-by|randomly|randomize|eslint|infection|stryker|mutmut|AST|run the test|run a real|execute the changed' "${f}" \
            || { echo "${p}: Bound analyzer names no concrete tool"; return 1; }
    done
}

@test "test-double-critic declares its mandatory mock-density metric" {
    local f="${TESTING_DIR}/test-double-critic.md"
    grep -qi 'MANDATORY'     "${f}"
    grep -qi 'mock-density'  "${f}"
}

@test "resolution doc wires the testing-critic group (section 2.1)" {
    local f="${VAULT_ROOT}/personas/_resolution.md"
    grep -q '2.1'                    "${f}"
    grep -q '_shared/testing/'       "${f}"
    grep -qi 'test-touching'         "${f}"
}

@test "quality persona no longer double-votes test behaviour" {
    # The "tests express behaviour, not internals" checklist bullet moved to test-behaviorist.
    local f="${VAULT_ROOT}/personas/_shared/quality.md"
    ! grep -qE '^- \[ \] Tests express behaviour, not internals\.$' "${f}"
    # ...and the testing specialist now owns it.
    grep -qi 'behaviour\|behavior' "${TESTING_DIR}/test-behaviorist.md"
}

@test "testing group is indexed in README and indications" {
    grep -q '_shared/testing'        "${VAULT_ROOT}/README.md"
    grep -q 'testing-persona-group'  "${VAULT_ROOT}/vault/indications/_index.md"
    [ -f "${VAULT_ROOT}/vault/indications/testing-persona-group.md" ]
}
