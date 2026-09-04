#!/usr/bin/env bats
# Behaviour tests for bin/gate.sh — the checks that refuse a session.
#
# Three of these are load-bearing:
#
#   * a table gate.sh cannot parse must exit 2, never 0. A parser that fails open turns every gate
#     into a no-op the moment a plan's columns drift.
#   * `verdict --run` must refuse when the real exit code contradicts the plan. Everything else in
#     this file checks that a document is internally honest; this is the only check that compares
#     the claim to the world.
#   * an `observed` criterion must stay legal. Forcing every criterion to be a command produces a
#     worse check than admitting a judgement is a judgement.
#
# Fixtures are written per test rather than committed, so the defect each one carries sits beside
# the assertion about it.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    GATE_SH="${VAULT_ROOT}/bin/gate.sh"
    TMP="$(mktemp -d)"
    unset GATE
}

teardown() {
    [ -n "${TMP:-}" ] && rm -rf "${TMP}"
}

# mkplan <name> <frontmatter-extra> <criteria-rows...>
# Writes a plan whose only content is the success-criteria table.
mkplan() {
    local name=$1 extra=$2; shift 2
    local f="${TMP}/${name}.md"
    {
        echo "---"
        echo "type: plan"
        [ -n "${extra}" ] && echo "${extra}"
        echo "---"
        echo
        echo "## Success criteria"
        echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        printf '%s\n' "$@"
        echo
    } > "${f}"
    echo "${f}"
}

# ---------------------------------------------------------------- criteria: existence

@test "criteria refuses a plan with no success-criteria table" {
    local f="${TMP}/bare.md"
    printf -- '---\ntype: plan\n---\n\n## Task\n\nsomething\n' > "${f}"
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no '## Success criteria' table"* ]]
}

@test "criteria refuses a success-criteria table with no rows" {
    local f
    f=$(mkplan empty "")
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no rows"* ]]
}

# ---------------------------------------------------------------- criteria: the e2e rule

@test "criteria refuses when no criterion is end-to-end" {
    local f
    f=$(mkplan no_e2e "" \
        '| SC-1 | WHEN the parser runs THE SYSTEM SHALL accept the row | unit | command | `true` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"kind 'e2e'"* ]]
    [[ "$output" == *"never integrated"* ]]
}

@test "criteria accepts a plan with no e2e row when it declares no-runtime" {
    local f
    f=$(mkplan no_runtime "no-runtime: documentation only, nothing executes" \
        '| SC-1 | WHEN the doc is linted THE SYSTEM SHALL exit clean | unit | command | `true` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"no-runtime"* ]]
}

@test "criteria accepts a well-formed plan with an e2e row" {
    local f
    f=$(mkplan good "" \
        '| SC-1 | WHEN the pipeline runs THE SYSTEM SHALL emit the file | e2e | command | `true` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- criteria: the how column

@test "criteria refuses a row with no how" {
    local f
    f=$(mkplan no_how "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e |  | `true` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no 'how'"* ]]
}

@test "criteria refuses an unknown how value" {
    local f
    f=$(mkplan bad_how "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | vibes | `true` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"how='vibes'"* ]]
}

@test "criteria refuses a command row whose check names no command and no path" {
    local f
    f=$(mkplan vague "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | it should look right | fine | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"names no command and no path"* ]]
}

# ---------------------------------------------------------------- criteria: observed rows

@test "criteria accepts an observed row carrying its failure condition and its no-command reason" {
    local f
    f=$(mkplan obs_ok "" \
        '| SC-1 | WHEN the cut plays THE SYSTEM SHALL hold the plate under the sentence | e2e | observed | open the render and watch the first minute; no-command: no detector reads plate-to-sentence fit | it fails when a plate plays under a sentence it does not illustrate | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
}

@test "criteria refuses an observed row with no condition that would make it fail" {
    local f
    f=$(mkplan obs_nofail "" \
        '| SC-1 | WHEN the cut plays THE SYSTEM SHALL look right | e2e | observed | watch the render; no-command: no detector exists | the operator is satisfied | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no condition that would make it fail"* ]]
}

@test "criteria refuses an observed row that does not say why no detector exists" {
    local f
    f=$(mkplan obs_noreason "" \
        '| SC-1 | WHEN the cut plays THE SYSTEM SHALL hold the plate | e2e | observed | watch the render | it fails when the plate does not match the sentence | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no-command:"* ]]
}

# ---------------------------------------------------------------- criteria: the EARS note

@test "criteria notes a criterion written as a statement but does not refuse it" {
    local f
    f=$(mkplan shape "" \
        '| SC-1 | the pipeline emits the file | e2e | command | `true` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"reads as a statement"* ]]
}

# ---------------------------------------------------------------- verdict: honesty checks

@test "verdict refuses a criterion with no verdict" {
    local f
    f=$(mkplan open_verdict "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | | |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no verdict"* ]]
}

@test "verdict refuses a MET row with no evidence" {
    local f
    f=$(mkplan met_bare "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | MET | |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"MET with no evidence"* ]]
}

@test "verdict refuses evidence that names no command and no path:line" {
    local f
    f=$(mkplan met_prose "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | MET | I checked and it was fine |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"names no command and no path:line"* ]]
}

@test "verdict refuses a NOT MET row" {
    local f
    f=$(mkplan notmet "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | NOT MET | `true` returned 1 |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"NOT MET"* ]]
}

@test "verdict accepts a MET row whose evidence names a command" {
    local f
    f=$(mkplan met_ok "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | MET | `true` exited 0 |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 0 ]
}

@test "verdict accepts evidence given as a path and line" {
    local f
    f=$(mkplan met_path "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | artifact | `bin/gate.sh` | the dispatcher exists | MET | bin/gate.sh:12 |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- verdict --run: the real check

@test "verdict --run refuses when the real exit code contradicts a MET verdict" {
    local f
    f=$(mkplan run_lies "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `false` | exit 0 | MET | `false` exited 0 |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 1 ]
    [[ "$output" == *"exited 1, expected 0"* ]]
}

@test "verdict --run accepts when the command really passes" {
    local f
    f=$(mkplan run_true "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | MET | `true` exited 0 |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 0 ]
}

@test "verdict --run honours an expected non-zero exit code" {
    local f
    f=$(mkplan run_expect_one "" \
        '| SC-1 | WHEN the gate refuses THE SYSTEM SHALL exit 1 | e2e | command | `false` | exit 1 | MET | `false` exited 1 |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 0 ]
}

@test "verdict --run refuses a command row the plan marked MET without running clean" {
    local f
    f=$(mkplan run_unmarked "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | | |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not say MET"* ]]
}

# ---------------------------------------------------------------- failing closed

@test "a table with a missing column exits 2, never 0" {
    local f="${TMP}/malformed.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | check |"
        echo "|----|-----------|------|-------|"
        echo '| SC-1 | it works | e2e | `true` |'
    } > "${f}"
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 2 ]
    [[ "$output" == *"no 'how' column"* ]]
}

@test "an unreadable plan exits 2, never 0" {
    run "${GATE_SH}" criteria "${TMP}/does-not-exist.md"
    [ "$status" -eq 2 ]
    [[ "$output" == *"cannot read plan"* ]]
}

@test "an unknown subcommand exits 2" {
    run "${GATE_SH}" frobnicate "${TMP}/x.md"
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------- the escape hatch

@test "GATE=off skips every check and exits 0 on a plan that otherwise refuses" {
    local f
    f=$(mkplan escape "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | unit | command | `true` | exit 0 | | |')
    GATE=off run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------- phases

@test "all --phase close runs both criteria and verdict" {
    local f
    f=$(mkplan phase_close "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | | |')
    run "${GATE_SH}" all "${f}" --phase close
    [ "$status" -eq 1 ]
    [[ "$output" == *"no verdict"* ]]
}

@test "all --phase propose passes a plan whose verdicts are still empty" {
    local f
    f=$(mkplan phase_propose "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | | |')
    run "${GATE_SH}" all "${f}" --phase propose
    [ "$status" -eq 0 ]
}

@test "all rejects an unknown phase" {
    local f
    f=$(mkplan phase_bad "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | | |')
    run "${GATE_SH}" all "${f}" --phase later
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------- multi-session scoping
#
# A plan that spans sessions carries criteria most of its checkpoints cannot yet meet. Refusing on
# those would make the first checkpoint impossible, and an unusable gate is a disabled gate. A
# criterion is due only when every work item naming it in `covers` is DONE.

mkplan_scoped() {
    local name=$1 wstatus=$2
    local f="${TMP}/${name}.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | MET | `true` exited 0 |'
        echo '| SC-2 | WHEN phase two lands THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | | |'
        echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | tool | constraint | covers | verification | status |"
        echo "|----|-------------------|--------|------|------------|--------|--------------|--------|"
        echo "| W-01 | \`bin/x.sh\` | create | Write | none | SC-1 | none | DONE |"
        echo "| W-02 | \`bin/y.sh\` | create | Write | none | SC-2 | none | ${wstatus} |"
        echo
    } > "${f}"
    echo "${f}"
}

@test "verdict passes a checkpoint whose undue criteria are still open" {
    local f
    f=$(mkplan_scoped checkpoint TODO)
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"SC-2 is not due yet"* ]]
}

@test "verdict refuses once the work items covering a criterion are done" {
    local f
    f=$(mkplan_scoped finished DONE)
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"SC-2 has no verdict"* ]]
}

@test "a work-items table with no covers column leaves every criterion due" {
    local f="${TMP}/nocovers.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | e2e | command | `true` | exit 0 | | |'
        echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | status |"
        echo "|----|-------------------|--------|--------|"
        echo "| W-01 | \`bin/x.sh\` | create | TODO |"
        echo
    } > "${f}"
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"SC-1 has no verdict"* ]]
}
