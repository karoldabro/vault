#!/usr/bin/env bats
# Tests for the /v-cr review group (personas/_shared/review/) — file contracts, the map key, the evidence
# table and the boundary lines. Backlog ids T13-T16 of vault/plans/2026-10-24-1903-v-cr-abstract-review.md.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    DIR="${VAULT_ROOT}/personas/_shared/review"
    SEATS="change-impact test-gap architecture-fit pattern-conformance intent-trace"
    RELATIONS=" referenced-by references caller test co-change sibling "
}

# map_names <file> — the relation names of the frontmatter map: key, one per line
map_names() {
    awk 'NR > 1 && $0 == "---" { exit } /^map:/ { sub(/^map:[[:space:]]*\[/, ""); sub(/\].*$/, ""); gsub(/,/, " "); print }' "$1" \
        | tr ' ' '\n' | grep -v '^$' || true
}

@test "T13: the review README has the group key and each lens has persona frontmatter" {
    grep -qE '^group: review$' "${DIR}/README.md"
    grep -qE '^type: persona-group$' "${DIR}/README.md"
    for p in ${SEATS}; do
        local f="${DIR}/${p}.md"
        [ -f "${f}" ] || { echo "missing lens: ${f}"; return 1; }
        grep -qE '^type: persona$' "${f}"
        grep -qE "^id: ${p}$" "${f}"
        grep -qE '^base_agent: [a-z-]+$' "${f}"
        grep -q 'tags: \[persona, shared, review\]' "${f}"
    done
}

@test "T14: each lens has the template sections in order and stays within 80 lines" {
    for p in ${SEATS}; do
        local f="${DIR}/${p}.md"
        [ "$(wc -l < "${f}")" -le 80 ] || { echo "${f} over 80 lines"; return 1; }
        grep -E '^## ' "${f}" | tr '\n' '|' \
            | grep -q '^## base_agent|## Mandate|## Bound analyzer|## Severity rubric|## Checklist|## Output|$' \
            || { echo "${f}: sections out of order"; return 1; }
    done
}

@test "T15: each lens and correctness has a known map key, the README holds one evidence row per seat, and no lens restates it" {
    local f n
    for f in "${DIR}"/{change-impact,test-gap,architecture-fit,pattern-conformance,intent-trace}.md \
             "${VAULT_ROOT}/personas/_shared/correctness.md"; do
        grep -qE '^map: \[.*\]$' "${f}" || { echo "no map key: ${f}"; return 1; }
        for n in $(map_names "${f}"); do
            [[ "${RELATIONS}" == *" ${n} "* ]] || { echo "${f}: unknown relation ${n}"; return 1; }
        done
    done
    for p in ${SEATS}; do
        grep -qE "^\| ${p} \| " "${DIR}/README.md" || { echo "no evidence row for ${p}"; return 1; }
        ! grep -qi 'confirmed only' "${DIR}/${p}.md" || { echo "${p} restates an evidence rule"; return 1; }
        tr '\n' ' ' < "${DIR}/${p}.md" | grep -q "the \`${p}\` row of \`personas/_shared/review/README.md\`" \
            || { echo "${p} does not point at its evidence row"; return 1; }
    done
    grep -q 'review/intent-trace' "${VAULT_ROOT}/personas/_shared/correctness.md"
    grep -q 'review/pattern-conformance' "${VAULT_ROOT}/personas/_shared/quality.md"
}

@test "T16: the persona template documents the map key and the testing README names test-gap" {
    local t="${VAULT_ROOT}/personas/_persona-template.md"
    grep -q '`map: \[' "${t}"
    grep -q 'bin/change-map.sh' "${t}"
    for n in ${RELATIONS}; do grep -q "\`${n}\`" "${t}" || { echo "template lacks ${n}"; return 1; }; done
    grep -q 'review/test-gap' "${VAULT_ROOT}/personas/_shared/testing/README.md"
}
