#!/usr/bin/env bats
# Drift detector for the PROPOSE layer-1 output contract (ADR-018).
#
# HONEST SCOPE: this compares the committed field set in tests/fixtures/propose-output.txt against
# the two step files that define it. It is a stricter file contract — NOT a behavioural test. It
# cannot detect that a real run was verbose, only that the contract text drifted from the fixture.
#
# Re-recording: edit tests/fixtures/propose-output.txt in the same commit as the contract change.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    GOLDEN="${VAULT_ROOT}/tests/fixtures/propose-output.txt"
    PROPOSE="${VAULT_ROOT}/commands/v-work/steps/03-propose.md"
    PROPOSE_LOOP="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
}

# Extract the entries under a "## <name>" heading in the golden file, ignoring comments/blanks.
# Fails loudly on an empty result: a renamed or emptied fixture heading would otherwise make every
# caller's `while read` loop iterate zero times and pass green.
golden_section() {
    local out
    out="$(awk -v want="$1" '
        /^## / { inside = (index($0, want) > 0); next }
        inside && !/^#/ && NF { print }
    ' "${GOLDEN}")"
    if [ -z "${out}" ]; then
        echo "golden_section '$1' returned nothing — fixture heading renamed or section emptied?" >&2
        return 1
    fi
    printf '%s\n' "${out}"
}

# The layer-1 block of a step file: from the "Layer 1" heading to the "Layer 2" heading.
layer1() {
    awk '/^### Layer 1/{inside=1} /^### Layer 2/{inside=0} inside' "$1"
}

@test "golden fixture exists and documents how to re-record it" {
    [ -f "${GOLDEN}" ]
    grep -qi 'Re-recording:' "${GOLDEN}"
    # It must not overclaim — this is a drift detector, not proof of behaviour.
    grep -qi 'drift detector' "${GOLDEN}"
    tr '\n' ' ' < "${GOLDEN}" | grep -qi 'nothing here proves'
}

@test "every ALLOWED field appears as a real field in the v-work layer-1 contract" {
    local field fields
    # Anchored: an unanchored substring match is satisfied by surrounding prose ("the `Impact` line",
    # "any open blocker"), so deleting the actual template field would go undetected.
    fields="$(golden_section "ALLOWED")" || return 1
    while IFS= read -r field; do
        layer1 "${PROPOSE}" | grep -qiE "^ *\**${field}\**:" \
            || { echo "layer-1 contract is missing allowed field: ${field}"; return 1; }
    done <<< "${fields}"
}

@test "no FORBIDDEN artifact field is printed in EITHER layer-1 block" {
    local field file
    # Both files must be checked: `Converged plan` and `Proposed test backlog` only ever existed in
    # v-team's block, so checking v-work alone would miss exactly the regression they guard.
    for file in "${PROPOSE}" "${PROPOSE_LOOP}"; do
        while IFS= read -r field; do
            if layer1 "${file}" | grep -qi "^ *${field}:"; then
                echo "artifact-only field leaked into the user layer of ${file}: ${field}"
                return 1
            fi
        done < <(golden_section "FORBIDDEN — moved to the plan artifact")
    done
}

@test "the omit rule cannot delete the always-emitted exceptions" {
    # Driven from the fixture so it stays the single source of truth. Each token must survive in at
    # least one of the two step files — these are the warnings the omit-when-empty rule must spare.
    local token tokens
    tokens="$(golden_section "ALWAYS-EMITTED")" || return 1
    while IFS= read -r token; do
        grep -qi "${token}" "${PROPOSE}" || grep -qi "${token}" "${PROPOSE_LOOP}" \
            || { echo "always-emitted exception dropped from both step files: ${token}"; return 1; }
    done <<< "${tokens}"
}

@test "panel vocabulary never appears as an emitted field in the v-team layer-1 block" {
    # Polarity matters. Asserting these terms are PRESENT in the file proves nothing — they all
    # legitimately occur in the machine-read finding schema. The regression to catch is a panel term
    # being handed to the user, so assert ABSENCE from the layer-1 block, with one narrow carve-out
    # for the translation rule itself (which must name the terms in order to ban them).
    # A leak looks like an emitted template field (`Convergence: <clean|capped>`), which is exactly
    # what the old block printed. The ban list names the same words in backticks to forbid them —
    # that is the rule, not a leak — so match the field-label form only.
    local field file
    for file in "${PROPOSE}" "${PROPOSE_LOOP}"; do
        while IFS= read -r field; do
            if layer1 "${file}" | grep -qiE "^ *\**${field}\**:"; then
                echo "panel vocabulary emitted as a user-facing field in ${file}: ${field}"
                return 1
            fi
        done < <(golden_section "FORBIDDEN — panel vocabulary")
    done
}

@test "the translation rule itself cannot be deleted silently" {
    grep -qi 'Translate, never transcribe' "${PROPOSE_LOOP}"
    # and it must name replacements, not just forbid
    tr '\n' ' ' < "${PROPOSE_LOOP}" | grep -qi 'must fix before this ships'
    tr '\n' ' ' < "${PROPOSE_LOOP}" | grep -qi 'reviewer'
}

@test "both step files declare the two-layer split" {
    grep -qi 'Required output — two layers' "${PROPOSE}"
    grep -qi 'Required output — two layers' "${PROPOSE_LOOP}"
    grep -q  '### Layer 1'                  "${PROPOSE}"
    grep -q  '### Layer 2'                  "${PROPOSE}"
}
