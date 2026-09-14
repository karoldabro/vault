#!/usr/bin/env bats
# Contract tests for /v-handoff and /v-report.
#
# The four check scripts carry the real contract; these tests run them and then assert the two things
# a check script cannot see about itself. The first is that a check still goes red on a planted
# violation — a check trusted green without that has only proved it can print OK. The second is that
# doc-lint grades each type at its own cap, which is invisible on a clean file because doc-lint prints
# its header only alongside a finding.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    HANDOFF_CMD="${VAULT_ROOT}/commands/v-handoff.md"
    REPORT_CMD="${VAULT_ROOT}/commands/v-report.md"
    HANDOFF_TPL="${VAULT_ROOT}/templates/handoff.md"
    REPORT_TPL="${VAULT_ROOT}/templates/report.md"
    LINT="${VAULT_ROOT}/bin/doc-lint.sh"
    TMP="$(mktemp -d)"
}

teardown() {
    [ -n "${TMP:-}" ] && rm -rf "${TMP}"
    return 0
}

# ---------------------------------------------------------------- shipped files

@test "both commands and both templates exist" {
    [ -f "${HANDOFF_CMD}" ]
    [ -f "${REPORT_CMD}" ]
    [ -f "${HANDOFF_TPL}" ]
    [ -f "${REPORT_TPL}" ]
}

@test "each command has a frontmatter description, which the plugin picker reads" {
    for cmd in "${HANDOFF_CMD}" "${REPORT_CMD}"; do
        run head -1 "${cmd}"
        [ "$status" -eq 0 ]
        [[ "$output" == "---" ]]
        run grep -qE '^description: .{40,}' "${cmd}"
        [ "$status" -eq 0 ]
    done
}

@test "install.sh links commands by glob, so neither command needs an installer edit" {
    run grep -q 'v-handoff' "${VAULT_ROOT}/install.sh"
    [ "$status" -ne 0 ]
    run grep -q 'v-report' "${VAULT_ROOT}/install.sh"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------- the four checks

@test "handoff-SC-1 passes: /v-handoff carries its core sections, modes and refusals" {
    run "${VAULT_ROOT}/checks/handoff-SC-1.sh"
    [ "$status" -eq 0 ]
}

@test "handoff-SC-2 passes: /v-report carries its fields and modes" {
    run "${VAULT_ROOT}/checks/handoff-SC-2.sh"
    [ "$status" -eq 0 ]
}

@test "handoff-SC-3 passes: every framework surface names both commands" {
    run "${VAULT_ROOT}/checks/handoff-SC-3.sh"
    [ "$status" -eq 0 ]
}

@test "handoff-SC-4 passes: doc-lint registers both types" {
    run "${VAULT_ROOT}/checks/handoff-SC-4.sh"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- the checks go red

@test "handoff-SC-1 refuses a template that puts an optional section above a core one" {
    # A copy of the repo layout the check reads, with the section order inverted.
    mkdir -p "${TMP}/checks" "${TMP}/commands" "${TMP}/templates"
    cp "${VAULT_ROOT}/checks/handoff-SC-1.sh" "${TMP}/checks/"
    cp "${HANDOFF_CMD}" "${TMP}/commands/"
    awk '/^## Notes/{print "## Notes"; print ""; print "## Left to do"; next} {print}' \
        "${HANDOFF_TPL}" > "${TMP}/templates/handoff.md"
    run "${TMP}/checks/handoff-SC-1.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"optional section above a core one"* ]]
}

@test "handoff-SC-2 refuses a report template naming the finder in its body" {
    mkdir -p "${TMP}/checks" "${TMP}/commands" "${TMP}/templates"
    cp "${VAULT_ROOT}/checks/handoff-SC-2.sh" "${TMP}/checks/"
    cp "${REPORT_CMD}" "${TMP}/commands/"
    cp "${REPORT_TPL}" "${TMP}/templates/report.md"
    printf 'found_by: whoever\n' >> "${TMP}/templates/report.md"
    run "${TMP}/checks/handoff-SC-2.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"found_by as a key in its body"* ]]
}

@test "handoff-SC-4 refuses when a type is dropped from is_known_type" {
    mkdir -p "${TMP}/checks" "${TMP}/bin"
    cp "${VAULT_ROOT}/checks/handoff-SC-4.sh" "${TMP}/checks/"
    cp -r "${VAULT_ROOT}/lib" "${TMP}/lib"
    sed 's/^        handoff|report) return 0 ;;/        report) return 0 ;;/' "${LINT}" > "${TMP}/bin/doc-lint.sh"
    chmod +x "${TMP}/bin/doc-lint.sh"
    run "${TMP}/checks/handoff-SC-4.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"is_known_type does not list handoff"* ]]
}

# ---------------------------------------------------------------- doc-lint grading

@test "doc-lint lists a cap for both new types" {
    run "${LINT}" --list-caps
    [ "$status" -eq 0 ]
    [[ "$output" == *"handoff"* ]]
    [[ "$output" == *"150"* ]]
    [[ "$output" == *"report"* ]]
    [[ "$output" == *"120"* ]]
}

@test "a handoff is graded at cap 150 and is not reported as an unknown type" {
    # doc-lint prints its header only beside a finding, so the probe plants one on purpose.
    {
        printf -- '---\ntype: handoff\nproject: probe\nstatus: open\ntags: [handoff]\n---\n\n# Probe\n\n## Goal\n\n'
        printf 'This one sentence is written past the thirty word ceiling the standard sets for a specification, purely so that doc-lint emits a finding and therefore prints the header line this test reads back.\n'
    } > "${TMP}/probe.md"
    run "${LINT}" "${TMP}/probe.md"
    [[ "$output" == *"cap 150"* ]]
    [[ "$output" != *"unknown type"* ]]
}

@test "a report is graded at cap 120 and is not reported as an unknown type" {
    {
        printf -- '---\ntype: report\nproject: probe\nstatus: open\ntags: [report]\n---\n\n# Probe\n\n## What is wrong\n\n'
        printf 'This one sentence is written past the thirty word ceiling the standard sets for a specification, purely so that doc-lint emits a finding and therefore prints the header line this test reads back.\n'
    } > "${TMP}/probe.md"
    run "${LINT}" "${TMP}/probe.md"
    [[ "$output" == *"cap 120"* ]]
    [[ "$output" != *"unknown type"* ]]
}

@test "a file in handoffs/ with no frontmatter is still treated as a document" {
    mkdir -p "${TMP}/handoffs"
    printf '# Untyped\n\nThis one sentence is written past the thirty word ceiling the standard sets for a specification, purely so that doc-lint emits a finding and therefore prints the header line this test reads back.\n' \
        > "${TMP}/handoffs/untyped.md"
    run "${LINT}" "${TMP}/handoffs/untyped.md"
    [[ "$output" == *"cap 150"* ]]
}

# ---------------------------------------------------------------- the two templates

@test "the handoff template declares its type and carries a Left to do table" {
    run grep -q '^type: handoff' "${HANDOFF_TPL}"
    [ "$status" -eq 0 ]
    run grep -q '^## Left to do' "${HANDOFF_TPL}"
    [ "$status" -eq 0 ]
}

@test "the report template declares its type and keeps found_by in frontmatter" {
    run grep -q '^type: report' "${REPORT_TPL}"
    [ "$status" -eq 0 ]
    run grep -q '^found_by:' "${REPORT_TPL}"
    [ "$status" -eq 0 ]
}

@test "both templates lint clean" {
    run "${LINT}" "${HANDOFF_TPL}" "${REPORT_TPL}"
    [ "$status" -eq 0 ]
}
