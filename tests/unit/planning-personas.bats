#!/usr/bin/env bats
# Tests for the planning critic group (personas/_shared/planning/) — file contracts, the scale tiers,
# the grounding rule, the selection rule and the session sizing rules the group now owns.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    DIR="${VAULT_ROOT}/personas/_shared/planning"
    LENSES="solution-architect codebase-fit lazy-dev future-scope system-integration security-architect harness-engineer delivery-planner"
}

@test "planning group has a README with the group key" {
    [ -f "${DIR}/README.md" ]
    grep -qE '^group: planning$' "${DIR}/README.md"
}

@test "every planning lens exists with persona frontmatter and a base agent" {
    for p in ${LENSES}; do
        local f="${DIR}/${p}.md"
        [ -f "${f}" ] || { echo "missing lens: ${f}"; return 1; }
        grep -qE '^type: persona$' "${f}"
        grep -qE "^id: ${p}$" "${f}"
        grep -qE '^base_agent: ' "${f}"
        grep -q 'tags: \[persona, shared, planning\]' "${f}"
    done
}

@test "every planning lens is at most 150 lines with the six sections in order" {
    for p in ${LENSES}; do
        local f="${DIR}/${p}.md"
        [ "$(wc -l < "${f}")" -le 150 ] || { echo "${p}: over 150 lines"; return 1; }
        local got
        got=$(grep -E '^## (Mandate|Bound analyzer|Severity rubric|Checklist|Scale|Output)$' "${f}" | tr '\n' '|')
        [ "${got}" = "## Mandate|## Bound analyzer|## Severity rubric|## Checklist|## Scale|## Output|" ] \
            || { echo "${p}: sections are ${got}"; return 1; }
    done
}

@test "every lens checklist has 10 to 12 items and links the README grounding rule" {
    for p in ${LENSES}; do
        local f="${DIR}/${p}.md" n
        n=$(grep -c '^- \[ \]' "${f}")
        [ "${n}" -ge 10 ] && [ "${n}" -le 12 ] || { echo "${p}: ${n} checklist items"; return 1; }
        grep -q 'personas/_shared/planning/README.md' "${f}" || { echo "${p}: no link to the grounding rule"; return 1; }
    done
}

@test "the README lists every lens and holds the one grounding rule" {
    for p in ${LENSES}; do grep -q "\[\[${p}\]\]" "${DIR}/README.md" || { echo "README lacks ${p}"; return 1; }; done
    grep -q '^## Grounding rule' "${DIR}/README.md"
    grep -q 'A fetched URL alone keeps a finding `advisory`' "${DIR}/README.md"
}

@test "the README tier table states thresholds and caps" {
    grep -q '^## Scale tiers' "${DIR}/README.md"
    grep -qE '^\| small \| 1 repo.* \| 3 \| 1 \|$' "${DIR}/README.md"
    grep -qE '^\| medium \| .* \| 4 \| 2 \|$' "${DIR}/README.md"
    grep -qE '^\| large \| 3 or more repos.* \| 5 \| 2 \|$' "${DIR}/README.md"
}

@test "resolution names the planning selection with three always-seated lenses" {
    local r="${VAULT_ROOT}/personas/_resolution.md"
    grep -q '^### 2.3 Planning-group selection' "${r}"
    grep -q 'planning/solution-architect`, `planning/lazy-dev`, `consumer`' "${r}"
}

@test "delivery-planner owns the session sizing rules" {
    local f="${DIR}/delivery-planner.md"
    grep -q '~9' "${f}"
    grep -q '~15' "${f}"
    grep -q '/v-ask' "${f}"
    grep -q '/v-do' "${f}" && grep -q '/v-work' "${f}" && grep -q '/v-team' "${f}"
}
