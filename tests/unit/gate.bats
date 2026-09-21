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
    printf '#!/usr/bin/env bash\nprintf "ok\\n"\nexit 0\n' > "${TMP}/ok.sh"
    printf '#!/usr/bin/env bash\nprintf "bad\\n"\nexit 1\n' > "${TMP}/bad.sh"
    chmod +x "${TMP}/ok.sh" "${TMP}/bad.sh"
}

teardown() {
    [ -n "${TMP:-}" ] && rm -rf "${TMP}"
}

# mkcheck <name> <exit-code> — write an executable check beside the plan, which is what a
# `how: command` criterion must now name. An inline command is refused by design.
mkcheck() {
    local name=$1 code=${2:-0}
    printf '#!/usr/bin/env bash\nprintf "%s ran\\n"\nexit %s\n' "${name}" "${code}" > "${TMP}/${name}"
    chmod +x "${TMP}/${name}"
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

# ---------------------------------------------------------------- criteria: the delivery rule

@test "criteria refuses when no criterion runs the real system" {
    local f
    f=$(mkplan no_e2e "" \
        '| SC-1 | WHEN the parser runs THE SYSTEM SHALL accept the row | unit | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"kind 'delivery'"* ]]
    [[ "$output" == *"never arrives"* ]]
}

@test "criteria accepts a plan with no delivery row when it declares no-runtime" {
    local f
    f=$(mkplan no_runtime "no-runtime: documentation only, nothing executes" \
        '| SC-1 | WHEN the doc is linted THE SYSTEM SHALL exit clean | unit | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"no-runtime"* ]]
}

@test "criteria accepts a well-formed plan carrying a delivery row" {
    local f
    f=$(mkplan good "" \
        '| SC-1 | WHEN the pipeline runs THE SYSTEM SHALL emit the file | delivery | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- criteria: the how column

@test "criteria refuses a row with no how" {
    local f
    f=$(mkplan no_how "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery |  | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no 'how'"* ]]
}

@test "criteria refuses an unknown how value" {
    local f
    f=$(mkplan bad_how "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | vibes | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"how='vibes'"* ]]
}

@test "criteria refuses a command typed into the plan instead of a committed script" {
    local f
    f=$(mkplan inline "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `pytest -q && echo done` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a committed executable"* ]]
    [[ "$output" == *"authored by the same session"* ]]
}

@test "criteria refuses a check naming a script that does not exist" {
    local f
    f=$(mkplan missing_script "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `checks/absent.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a committed executable"* ]]
}

@test "criteria refuses a check file that is not executable" {
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/inert.sh"
    local f
    f=$(mkplan not_exec "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `inert.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a committed executable"* ]]
}

# ---------------------------------------------------------------- criteria: observed rows

@test "criteria accepts an observed row carrying its failure condition and its no-command reason" {
    local f
    f=$(mkplan obs_ok "" \
        '| SC-1 | WHEN the cut plays THE SYSTEM SHALL hold the plate under the sentence | delivery | observed | open the render and watch the first minute; no-command: no detector reads plate-to-sentence fit | it fails when a plate plays under a sentence it does not illustrate | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
}

@test "criteria refuses an observed row with no condition that would make it fail" {
    local f
    f=$(mkplan obs_nofail "" \
        '| SC-1 | WHEN the cut plays THE SYSTEM SHALL look right | delivery | observed | watch the render; no-command: no detector exists | the operator is satisfied | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no condition that would make it fail"* ]]
}

@test "criteria refuses an observed row that does not say why no detector exists" {
    local f
    f=$(mkplan obs_noreason "" \
        '| SC-1 | WHEN the cut plays THE SYSTEM SHALL hold the plate | delivery | observed | watch the render | it fails when the plate does not match the sentence | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no-command:"* ]]
}

# ---------------------------------------------------------------- criteria: the EARS note

@test "criteria notes a criterion written as a statement but does not refuse it" {
    local f
    f=$(mkplan shape "" \
        '| SC-1 | the pipeline emits the file | delivery | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"reads as a statement"* ]]
}

# ---------------------------------------------------------------- verdict: honesty checks

@test "verdict refuses a criterion with no verdict" {
    local f
    f=$(mkplan open_verdict "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no verdict"* ]]
}

@test "verdict refuses a MET row with no evidence" {
    local f
    f=$(mkplan met_bare "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | MET | |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"MET with no evidence"* ]]
}

@test "verdict refuses evidence that names no command and no path:line" {
    local f
    f=$(mkplan met_prose "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | MET | I checked and it was fine |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"names no command and no path:line"* ]]
}

@test "verdict refuses a NOT MET row" {
    local f
    f=$(mkplan notmet "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | NOT MET | `true` returned 1 |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"NOT MET"* ]]
}

@test "verdict accepts a MET row whose evidence names a command" {
    local f
    f=$(mkplan met_ok "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | MET | `ok.sh` exited 0 |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 0 ]
}

@test "verdict accepts evidence given as a path and line" {
    local f
    f=$(mkplan met_path "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | artifact | `bin/gate.sh` | the dispatcher exists | MET | bin/gate.sh:12 |')
    run "${GATE_SH}" verdict "${f}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- verdict --run: the real check

@test "verdict --run refuses when the real exit code contradicts a MET verdict" {
    local f
    f=$(mkplan run_lies "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `bad.sh` | exit 0 | MET | `bad.sh` exited 0 |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 1 ]
    [[ "$output" == *"exited 1, expected 0"* ]]
}

@test "verdict --run accepts when the command really passes" {
    local f
    f=$(mkplan run_true "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | MET | `ok.sh` exited 0 |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 0 ]
}

@test "verdict --run honours an expected non-zero exit code" {
    local f
    f=$(mkplan run_expect_one "" \
        '| SC-1 | WHEN the gate refuses THE SYSTEM SHALL exit 1 | delivery | command | `bad.sh` | exit 1 | MET | `bad.sh` exited 1 |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 0 ]
}

@test "verdict --run writes the verdict into a blank cell, so the session never authors it" {
    local f
    f=$(mkplan run_writes "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 0 ]
    grep -q 'MET' "${f}"
    grep -q 'ok.sh` exited 0' "${f}"
}

@test "verdict --run overwrites a MET the session wrote when the check really fails" {
    local f
    f=$(mkplan run_overwrites "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `bad.sh` | exit 0 | MET | `bad.sh` exited 0 |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 1 ]
    grep -q 'NOT MET' "${f}"
    [[ "$output" == *"recorded NOT MET"* ]]
}

@test "verdict --run captures the check output as the evidence" {
    printf '#!/usr/bin/env bash\nprintf "saw the thing\\n"\nexit 0\n' > "${TMP}/talky.sh"
    chmod +x "${TMP}/talky.sh"
    local f
    f=$(mkplan run_captures "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `talky.sh` | exit 0 | | |')
    run "${GATE_SH}" verdict "${f}" --run
    [ "$status" -eq 0 ]
    grep -q 'saw the thing' "${f}"
}

# ---------------------------------------------------------------- failing closed

@test "a table with a missing column exits 2, never 0" {
    local f="${TMP}/malformed.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | check |"
        echo "|----|-----------|------|-------|"
        echo '| SC-1 | it works | delivery | `true` |'
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
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | unit | command | `ok.sh` | exit 0 | | |')
    GATE=off run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------- phases

@test "all --phase close runs both criteria and verdict" {
    local f
    f=$(mkplan phase_close "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" all "${f}" --phase close
    [ "$status" -eq 1 ]
    [[ "$output" == *"no verdict"* ]]
}

@test "all --phase propose passes a plan whose verdicts are still empty" {
    local f
    f=$(mkplan phase_propose "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |')
    # An unprofiled repo: the working directory's own VAULT.md declares a profile, and a plan that
    # names no spec is refused there by design.
    run "${GATE_SH}" all "${f}" --phase propose --repo "${TMP}"
    [ "$status" -eq 0 ]
}

@test "all rejects an unknown phase" {
    local f
    f=$(mkplan phase_bad "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |')
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
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | MET | `ok.sh` exited 0 |'
        echo '| SC-2 | WHEN phase two lands THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
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
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
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

# ---------------------------------------------------------------- coverage
#
# `criteria` proves a plan states a target. `coverage` proves the plan contains work that reaches it.
# The two exit codes are load-bearing and must not merge: exit 1 says the plan cannot reach a goal it
# set, which FAILS the session, and exit 2 says the plan could not be read, which is a document
# defect. `coverage` and `due_criteria` read the same `covers` column and take a missing one in
# OPPOSITE directions, so the pair of tests below is what keeps the shared helper honest.

@test "coverage passes when every criterion is named by a work item" {
    local f
    f=$(mkplan_scoped covered TODO)
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 0 ]
}

@test "coverage counts an unfinished work item as covering its criterion" {
    # Coverage asks whether the work EXISTS, not whether it finished. A TODO row still covers.
    local f
    f=$(mkplan_scoped stilltodo TODO)
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 0 ]
    run grep -q "is named in no work item" <<<"$output"
    [ "$status" -ne 0 ]
}

@test "coverage reads a covers cell that separates ids by space, comma, or both" {
    # The masked bug: splitting on the comma alone and deleting spaces welds `SC-1 SC-2` into one
    # token that matches nothing, which surfaces as an uncovered criterion. It hid because plans
    # also carry single-id cells, so every criterion happened to appear alone somewhere too.
    local f="${TMP}/separators.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN a runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
        echo '| SC-2 | WHEN b runs THE SYSTEM SHALL work | unit | command | `ok.sh` | exit 0 | | |'
        echo '| SC-3 | WHEN c runs THE SYSTEM SHALL work | unit | command | `ok.sh` | exit 0 | | |'
        echo '| SC-4 | WHEN d runs THE SYSTEM SHALL work | unit | command | `ok.sh` | exit 0 | | |'
        echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | tool | constraint | covers | verification | status |"
        echo "|----|-------------------|--------|------|------------|--------|--------------|--------|"
        # No criterion appears alone anywhere, so a comma-only split refuses all four.
        echo "| W-01 | \`bin/x.sh\` | create | Write | none | SC-1 SC-2 | none | TODO |"
        echo "| W-02 | \`bin/y.sh\` | create | Write | none | SC-3, SC-4 | none | TODO |"
        echo
    } > "${f}"
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 0 ]
}

@test "coverage refuses a criterion no work item covers, and names it" {
    local f="${TMP}/uncovered.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
        echo '| SC-9 | WHEN nothing reaches it THE SYSTEM SHALL refuse | unit | command | `ok.sh` | exit 0 | | |'
        echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | tool | constraint | covers | verification | status |"
        echo "|----|-------------------|--------|------|------------|--------|--------------|--------|"
        echo "| W-01 | \`bin/x.sh\` | create | Write | none | SC-1 | none | TODO |"
        echo
    } > "${f}"
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"SC-9"* ]]
    # SC-1 is covered, so it must NOT appear as a refusal.
    run grep -q "SC-1 is named in no work item" <<<"$output"
    [ "$status" -ne 0 ]
}

@test "coverage exits 2 on a work-items table with no covers column" {
    # The decorrelated half of "a work-items table with no covers column leaves every criterion due".
    # `verdict` treats the same plan as all-due; `coverage` refuses to guess.
    local f="${TMP}/cov-nocovers.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
        echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | status |"
        echo "|----|-------------------|--------|--------|"
        echo "| W-01 | \`bin/x.sh\` | create | TODO |"
        echo
    } > "${f}"
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 2 ]
}

@test "coverage exits 2 on a plan with no work-items table at all" {
    local f="${TMP}/cov-notable.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
        echo
    } > "${f}"
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 2 ]
}

@test "coverage exits 2 on a plan with no success-criteria table" {
    local f="${TMP}/cov-nocrit.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | tool | constraint | covers | verification | status |"
        echo "|----|-------------------|--------|------|------------|--------|--------------|--------|"
        echo "| W-01 | \`bin/x.sh\` | create | Write | none | SC-1 | none | TODO |"
        echo
    } > "${f}"
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 2 ]
}

@test "the approve phase runs coverage, so an uncovered criterion stops the gate" {
    # The wiring is the point: cmd_coverage existing while no phase calls it gates nothing.
    local f="${TMP}/cov-phase.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
        echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | tool | constraint | covers | verification | status |"
        echo "|----|-------------------|--------|------|------------|--------|--------------|--------|"
        echo "| W-01 | \`bin/x.sh\` | create | Write | none |  | none | TODO |"
        echo
    } > "${f}"
    run "${GATE_SH}" all "${f}" --phase approve
    [ "$status" -eq 1 ]
    [[ "$output" == *"SC-1"* ]]
}

@test "coverage refuses a plan already marked status: failed" {
    # `status: failed` has exactly one code reader, and this is it. Without it the marker is a note
    # to a model, and a failed plan passes the approval gate by being run again.
    local f="${TMP}/already-failed.md"
    {
        echo "---"; echo "type: plan"; echo "status: failed"; echo "---"; echo
        echo "## Success criteria"; echo
        echo "| id | criterion | kind | how | check | expect | verdict | evidence |"
        echo "|----|-----------|------|-----|-------|--------|---------|----------|"
        echo '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |'
        echo
        echo "## Work items"; echo
        echo "| id | file (exact path) | action | tool | constraint | covers | verification | status |"
        echo "|----|-------------------|--------|------|------------|--------|--------------|--------|"
        echo "| W-01 | \`bin/x.sh\` | create | Write | none | SC-1 | none | TODO |"
        echo
    } > "${f}"
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"status: failed"* ]]
}

@test "coverage passes the same plan once it is no longer marked failed" {
    # The planted-violation pair: the refusal above must come from the marker, not the fixture.
    local f
    f=$(mkplan_scoped notfailed TODO)
    run grep -q 'status: failed' "${f}"
    [ "$status" -ne 0 ]
    run "${GATE_SH}" coverage "${f}"
    [ "$status" -eq 0 ]
}

@test "the close phase does not run coverage, so a plan with no work items still reaches verdict" {
    # A close-phase coverage run exits 2 on any plan without a `## Work items` table, which is what
    # /v-do writes. That short-circuits the close and every /v-do session dies at exit 2.
    local f
    f=$(mkplan cov_not_at_close "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `ok.sh` | exit 0 | | |')
    run "${GATE_SH}" all "${f}" --phase close
    [ "$status" -eq 1 ]
    [[ "$output" == *"no verdict"* ]]
}

@test "session-gates.md documents coverage and session-gates-unbuilt.md no longer does" {
    run grep -qE '^\| `coverage <plan>`' "${VAULT_ROOT}/vault/architecture/session-gates.md"
    [ "$status" -eq 0 ]
    run grep -qE '^\| U-2 ' "${VAULT_ROOT}/vault/architecture/session-gates-unbuilt.md"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------- readers
#
# A declared key that nothing reads is worse than one that does not exist: the next session finds
# it, believes the question is settled, and has no way to discover otherwise. No mainstream tool
# detects this, so these cases are the whole specification.

mkplan_lifecycle() {
    local name=$1 artifact=$2
    local f="${TMP}/${name}.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Artifact lifecycles"; echo
        echo "| artifact | what requires it | who writes it | who reads it | missing or wrong |"
        echo "|---|---|---|---|---|"
        echo "| ${artifact} | a step | this plan | a reader | it fails |"
        echo
    } > "${f}"
    echo "${f}"
}

@test "readers refuses an identifier no code reads" {
    local f
    f=$(mkplan_lifecycle orphan '`effects_duck_under_narration`')
    run "${GATE_SH}" readers "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no code reads it"* ]]
    [[ "$output" == *"believe the question is settled"* ]]
}

@test "readers accepts an identifier a file references" {
    printf 'effects_duck_under_narration = true\n' > "${TMP}/config.toml"
    local f
    f=$(mkplan_lifecycle wired '`effects_duck_under_narration`')
    run "${GATE_SH}" readers "${f}"
    [ "$status" -eq 0 ]
}

@test "readers ignores markdown, so a key mentioned only in prose still refuses" {
    printf 'we should add effects_duck_under_narration one day\n' > "${TMP}/notes.md"
    local f
    f=$(mkplan_lifecycle prose_only '`effects_duck_under_narration`')
    run "${GATE_SH}" readers "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no code reads it"* ]]
}

@test "readers notes a declared path that does not exist rather than refusing" {
    local f
    f=$(mkplan_lifecycle planned_path '`bin/not-built-yet.sh`')
    run "${GATE_SH}" readers "${f}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"does not exist yet"* ]]
}

@test "readers never exits nonzero without naming what it refused" {
    # The loop's last statement is a test, so a row whose artifact cell carries no backticked
    # identifier used to leak its false branch out as an unexplained exit 1. A silent refusal is the
    # one thing this program may not do: the caller stops the lifecycle and can say nothing about why.
    local f="${TMP}/no-ident.md"
    {
        echo "---"; echo "type: plan"; echo "---"; echo
        echo "## Artifact lifecycles"; echo
        echo "| artifact | what requires it | who writes it | who reads it | missing or wrong |"
        echo "|---|---|---|---|---|"
        echo "| the thing itself | a step | a session | the operator | it is absent |"
        echo
    } > "${f}"
    run "${GATE_SH}" readers "${f}"
    [ "$status" -eq 0 ]
}

@test "readers passes a plan whose lifecycle row is the none row" {
    local f
    f=$(mkplan_lifecycle nothing 'none')
    run "${GATE_SH}" readers "${f}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- config
#
# An OMITTED key is the refusal; `absent: <reason>` is legal. That distinction is the point: a tool
# this repo does not have is a fact worth recording, and a silently skipped line is how the next
# session comes to believe a question was settled.

mkrepo() {
    local body=$1
    printf '%s\n' "$body" > "${TMP}/VAULT.md"
    echo "${TMP}"
}

@test "config refuses a repo with no VAULT.md" {
    rm -f "${TMP}/VAULT.md"
    run "${GATE_SH}" config "${TMP}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no VAULT.md"* ]]
}

@test "config refuses a VAULT.md that omits a done key" {
    mkrepo 'dod_profile: code
test_command: pytest
lint_command: ruff check .' >/dev/null
    run "${GATE_SH}" config "${TMP}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"omits delivery_command"* ]]
    [[ "$output" == *"reads as settled"* ]]
}

@test "config accepts a key marked absent with a reason" {
    mkrepo 'dod_profile: code
test_command: pytest
lint_command: absent: no linter in this repo
delivery_command: absent: nothing runs end to end yet' >/dev/null
    run "${GATE_SH}" config "${TMP}"
    [ "$status" -eq 0 ]
}

@test "config refuses a key marked absent with no reason" {
    mkrepo 'dod_profile: code
test_command: pytest
lint_command: absent:
delivery_command: make ship' >/dev/null
    run "${GATE_SH}" config "${TMP}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"absent with no reason"* ]]
}

@test "config refuses a VAULT.md with no profile" {
    mkrepo 'test_command: pytest
lint_command: ruff check .
delivery_command: make ship' >/dev/null
    run "${GATE_SH}" config "${TMP}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no dod_profile"* ]]
}

# ---------------------------------------------------------------- check ownership
#
# checks/ is flat and keyed by criterion id, so two plans that both number a criterion SC-2 would
# share one script and each would grade itself against the other's check. A second plan running in
# parallel hit this and worked around it by inventing a filename prefix — a convention nothing
# enforced. These cases enforce it.

@test "criteria refuses a check script another plan already claims" {
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/shared.sh"; chmod +x "${TMP}/shared.sh"
    mkplan first "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `shared.sh` | exit 0 | | |' >/dev/null
    local f
    f=$(mkplan second "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `shared.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"already claims"* ]]
    [[ "$output" == *"grades itself against the other"* ]]
}

@test "criteria accepts a check only this plan names" {
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/mine.sh"; chmod +x "${TMP}/mine.sh"
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/theirs.sh"; chmod +x "${TMP}/theirs.sh"
    mkplan other "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `theirs.sh` | exit 0 | | |' >/dev/null
    local f
    f=$(mkplan ours "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `mine.sh` | exit 0 | | |')
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
}

@test "a plan's own brief and trail sidecars do not count as another claimant" {
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/solo.sh"; chmod +x "${TMP}/solo.sh"
    local f
    f=$(mkplan solo "" \
        '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `solo.sh` | exit 0 | | |')
    cp "${f}" "${TMP}/solo.trail.md"; cp "${f}" "${TMP}/solo.brief.md"
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------- arch
#
# `arch` checks a plan's architecture spec. Contract: commands/_shared/architecture-spec.md. Each
# defect below is derived from one of two complete fixtures, so the assertion sits beside the edit.

FX() { printf '%s' "${VAULT_ROOT}/tests/fixtures/arch/$1.arch.md"; }

# mkarchrepo <name> [VAULT.md line...] — a repo root holding the two files the harness fixture lists as
# existing, so its `new: no` rows resolve. Prints the directory.
mkarchrepo() {
    local d="${TMP}/$1"; shift
    mkdir -p "${d}/bin"; : > "${d}/bin/gate.sh"; : > "${d}/bin/doc-lint.sh"
    if [ $# -gt 0 ]; then printf '%s\n' "$@" > "${d}/VAULT.md"; fi
    printf '%s' "${d}"
}

# variant <fixture> <from> <to> <out> — one literal replacement, so the defect is visible in the test.
variant() {
    local c; c=$(<"$1")
    printf '%s\n' "${c/"$2"/"$3"}" > "$4"
}

# arch_ok <spec> [--repo <dir>] — the gate accepts the spec and prints the one success line.
arch_ok() {
    run "${GATE_SH}" arch "$@"
    [ "$status" -eq 0 ]
    [ "$output" = "arch: ok $1" ]
}

# arch_refused <problem-substring> <row-substring> <spec> [--repo <dir>]
arch_refused() {
    local problem=$1 row=$2; shift 2
    run "${GATE_SH}" arch "$@"
    [ "$status" -eq 1 ]
    [[ "$output" == *"REFUSED arch "* ]]
    [[ "$output" == *"${problem}"* ]]
    [[ "$output" == *"[${row}]"* ]] || [ -z "${row}" ]
}

@test "arch: an unreadable or missing file exits 2 with nothing on stdout" {
    run "${GATE_SH}" arch "${TMP}/absent.arch.md"
    [ "$status" -eq 2 ]
    [[ "$output" == *"cannot read"* ]]
    run "${GATE_SH}" arch "${TMP}"
    [ "$status" -eq 2 ]
}

@test "arch: both complete fixtures pass and print exactly one line" {
    local r; r=$(mkarchrepo r1 "arch_profile: code")
    arch_ok "$(FX code-complete)" --repo "${r}"
    r=$(mkarchrepo r2 "arch_profile: harness")
    arch_ok "$(FX harness-complete)" --repo "${r}"
}

@test "arch: a profiled repo refuses a plan that names no spec, whether the key is absent or empty" {
    local r p
    for prof in code harness; do
        r=$(mkarchrepo "p-${prof}" "arch_profile: ${prof}")
        printf -- '---\ntype: plan\n---\n# p\n' > "${TMP}/absent.md"
        run "${GATE_SH}" arch "${TMP}/absent.md" --repo "${r}"
        [ "$status" -eq 1 ]
        [[ "$output" == *"names no arch_spec"* ]]
        printf -- '---\ntype: plan\narch_spec:\n---\n# p\n' > "${TMP}/empty.md"
        run "${GATE_SH}" arch "${TMP}/empty.md" --repo "${r}"
        [ "$status" -eq 1 ]
        [[ "$output" == *"names no arch_spec"* ]]
    done
}

@test "arch: all --phase propose and approve run the arch check, close does not" {
    local r; r=$(mkarchrepo r3 "arch_profile: code")
    mkcheck c1.sh 0
    local f
    f=$(mkplan noarch "" '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `c1.sh` | exit 0 | | |')
    run "${GATE_SH}" all "${f}" --phase propose --repo "${r}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"names no arch_spec"* ]]
    run "${GATE_SH}" all "${f}" --phase approve --repo "${r}"
    [ "$status" -ne 0 ]
    [[ "$output" == *"names no arch_spec"* ]]
    run "${GATE_SH}" all "${f}" --phase close --repo "${r}"
    [[ "$output" != *"names no arch_spec"* ]]
}

@test "arch: a repo with no profile, no key, or no VAULT.md skips a plan that names no spec" {
    printf -- '---\ntype: plan\n---\n# p\n' > "${TMP}/nospec.md"
    for setup_line in "arch_profile: none" "dod_profile: code" ""; do
        local r
        if [ -n "${setup_line}" ]; then r=$(mkarchrepo "u-$RANDOM" "${setup_line}"); else r=$(mkarchrepo "u-$RANDOM"); fi
        run "${GATE_SH}" arch "${TMP}/nospec.md" --repo "${r}"
        [ "$status" -eq 0 ]
        [ -z "$output" ]
    done
}

@test "arch: a repo with no profile still validates a spec that is named" {
    local r; r=$(mkarchrepo r4 "dod_profile: code")
    arch_ok "$(FX code-complete)" --repo "${r}"
    variant "$(FX code-complete)" "| orderId: string, qty: int |" "| orderId, qty: int |" "${TMP}/x.arch.md"
    arch_refused "param orderId has no type" "OrderService.place" "${TMP}/x.arch.md" --repo "${r}"
}

@test "arch: a spec beside a plan is not read as a plan by the claimed-elsewhere check" {
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/solo2.sh"; chmod +x "${TMP}/solo2.sh"
    local f
    f=$(mkplan solo2 "" '| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | `solo2.sh` | exit 0 | | |')
    cp "${f}" "${TMP}/solo2.arch.md"
    run "${GATE_SH}" criteria "${f}"
    [ "$status" -eq 0 ]
}

@test "arch: profile equal passes; differing, missing or invalid is refused, on a spec and through a plan" {
    local r; r=$(mkarchrepo r5 "arch_profile: harness")
    arch_refused "profile differs" "" "$(FX code-complete)" --repo "${r}"
    r=$(mkarchrepo r6 "arch_profile: code")
    variant "$(FX code-complete)" "profile: code" "profile: python" "${TMP}/bad.arch.md"
    arch_refused "profile differs" "" "${TMP}/bad.arch.md" --repo "${r}"
    grep -v '^profile:' "$(FX code-complete)" > "${TMP}/nop.arch.md"
    arch_refused "profile differs" "" "${TMP}/nop.arch.md" --repo "${r}"
    cp "$(FX code-complete)" "${TMP}/good.arch.md"
    printf -- '---\ntype: plan\narch_spec: good.arch.md\n---\n# p\n' > "${TMP}/viaplan.md"
    run "${GATE_SH}" arch "${TMP}/viaplan.md" --repo "${r}"
    [ "$status" -eq 0 ]
    [ "$output" = "arch: ok ${TMP}/good.arch.md" ]
    cd /
    run "${GATE_SH}" arch "${TMP}/viaplan.md" --repo "${r}"
    [ "$status" -eq 0 ]
}

@test "arch: a plan naming a spec that does not exist is refused with the path" {
    local r; r=$(mkarchrepo r7 "arch_profile: code")
    printf -- '---\ntype: plan\narch_spec: gone.arch.md\n---\n# p\n' > "${TMP}/dangling.md"
    arch_refused "does not exist" "gone.arch.md" "${TMP}/dangling.md" --repo "${r}"
}

@test "arch: an invalid arch_profile value is refused; a comment, CRLF and a prefix key read correctly" {
    local r
    r=$(mkarchrepo r8 "arch_profile: python")
    arch_refused "invalid value" "python" "$(FX code-complete)" --repo "${r}"
    r=$(mkarchrepo r9 "arch_profile: harness   # this repo ships instructions")
    arch_ok "$(FX harness-complete)" --repo "${r}"
    r=$(mkarchrepo r10); printf 'arch_profile: harness\r\n' > "${r}/VAULT.md"
    arch_ok "$(FX harness-complete)" --repo "${r}"
    r=$(mkarchrepo r11 "x_arch_profile: harness")
    printf -- '---\ntype: plan\n---\n# p\n' > "${TMP}/nospec2.md"
    run "${GATE_SH}" arch "${TMP}/nospec2.md" --repo "${r}"
    [ "$status" -eq 0 ]
    r=$(mkarchrepo r12 "arch_profile:")
    arch_refused "invalid value" "" "$(FX code-complete)" --repo "${r}"
}

@test "arch: the wrong type, a missing frontmatter and status are refused" {
    local r; r=$(mkarchrepo r13 "dod_profile: code")
    for t in "type: arch_spec" "type: Arch-Spec" 'type: "arch-spec"' "type: decision"; do
        variant "$(FX code-complete)" "type: arch-spec" "${t}" "${TMP}/t.arch.md"
        arch_refused "frontmatter needs type: arch-spec" "" "${TMP}/t.arch.md" --repo "${r}"
    done
    tail -n +6 "$(FX code-complete)" > "${TMP}/nofm.arch.md"
    arch_refused "frontmatter needs type: arch-spec" "" "${TMP}/nofm.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "tags: [arch-spec]" "status: approved" "${TMP}/st.arch.md"
    arch_refused "must not carry status" "" "${TMP}/st.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "plan: fixture" "plan:" "${TMP}/np.arch.md"
    arch_refused "non-empty plan" "" "${TMP}/np.arch.md" --repo "${r}"
}

@test "arch: a missing required section is named, for both profiles" {
    local r; r=$(mkarchrepo r14 "dod_profile: code")
    awk '/^## Data model$/{s=1;next} /^## /{s=0} !s' "$(FX code-complete)" > "${TMP}/a.arch.md"
    arch_refused "missing section Data model" "" "${TMP}/a.arch.md" --repo "${r}"
    r=$(mkarchrepo r15 "arch_profile: harness")
    awk '/^## Load order$/{s=1;next} /^## /{s=0} !s' "$(FX harness-complete)" > "${TMP}/b.arch.md"
    arch_refused "missing section Load order" "" "${TMP}/b.arch.md" --repo "${r}"
}

@test "arch: a table needs a primary key, and a second valid table does not mask it" {
    local r; r=$(mkarchrepo r16 "dod_profile: code")
    variant "$(FX code-complete)" "| order_lines | id | uuid | no | PK |" "| order_lines | id | uuid | no | |" "${TMP}/a.arch.md"
    arch_refused "table has no primary key" "order_lines" "${TMP}/a.arch.md" --repo "${r}"
    [[ "$output" != *"[orders]"* ]]
    variant "$(FX code-complete)" "| orders | status | text | no | |" "| orders | status | text | no | PK |" "${TMP}/b.arch.md"
    arch_ok "${TMP}/b.arch.md" --repo "${r}"
}

@test "arch: a foreign key needs an index and a references target" {
    local r; r=$(mkarchrepo r17 "dod_profile: code")
    variant "$(FX code-complete)" "| ix_order_lines_order_id |" "| - |" "${TMP}/a.arch.md"
    arch_refused "foreign key has no index" "order_lines.order_id" "${TMP}/a.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| ix_order_lines_order_id | orders.id |" "| ix_order_lines_order_id | |" "${TMP}/b.arch.md"
    arch_refused "foreign key names no references" "order_lines.order_id" "${TMP}/b.arch.md" --repo "${r}"
}

@test "arch: identifiers, key, and null values are checked" {
    local r; r=$(mkarchrepo r18 "dod_profile: code")
    variant "$(FX code-complete)" "| orders | status |" "| Order Lines | status |" "${TMP}/a.arch.md"
    arch_refused "is not an identifier" "" "${TMP}/a.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| orders | status |" "| 1orders | status |" "${TMP}/b.arch.md"
    arch_refused "is not an identifier" "" "${TMP}/b.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| text | no | |" "| text | maybe | |" "${TMP}/c.arch.md"
    arch_refused "null must be yes or no" "" "${TMP}/c.arch.md" --repo "${r}"
}

@test "arch: n/a is legal under Data model only with a reason and without a table" {
    local r; r=$(mkarchrepo r19 "dod_profile: code")
    for body in "n/a: no database" ; do
        awk -v b="${body}" '/^## Data model$/{print; print ""; print b; print ""; s=1; next} /^## /{s=0} !s' "$(FX code-complete)" > "${TMP}/a.arch.md"
        arch_ok "${TMP}/a.arch.md" --repo "${r}"
    done
    for body in "n/a:" "n/a"; do
        awk -v b="${body}" '/^## Data model$/{print; print ""; print b; print ""; s=1; next} /^## /{s=0} !s' "$(FX code-complete)" > "${TMP}/b.arch.md"
        arch_refused "n/a needs a reason" "Data model" "${TMP}/b.arch.md" --repo "${r}"
    done
    awk '/^## Data model$/{print; print ""; print "n/a: no database"; next} {print}' "$(FX code-complete)" > "${TMP}/c.arch.md"
    arch_refused "holds n/a and a table" "" "${TMP}/c.arch.md" --repo "${r}"
}

@test "arch: interface params — valid forms pass, malformed ones are refused naming the row" {
    local r; r=$(mkarchrepo r20 "dod_profile: code")
    local good bad
    for good in "-" " - " "a: int" "m: Map<string, int>" "s: ?string" "l: string[]" 'u: int\|string' "f: fn(a: int, b: int), z: int"; do
        variant "$(FX code-complete)" "| orderId: string, qty: int |" "| ${good} |" "${TMP}/g.arch.md"
        arch_ok "${TMP}/g.arch.md" --repo "${r}"
    done
    for bad in "" "a" "a:" ": int" "a: int," "a: int,, b: int" "-, a: int" "a: int = 1" "1a: int"; do
        variant "$(FX code-complete)" "| orderId: string, qty: int |" "| ${bad} |" "${TMP}/b.arch.md"
        run "${GATE_SH}" arch "${TMP}/b.arch.md" --repo "${r}"
        [ "$status" -eq 1 ]
        [[ "$output" == *"[OrderService.place]"* ]]
    done
}

@test "arch: reuse map rules" {
    local r; r=$(mkarchrepo r21 "dod_profile: code")
    variant "$(FX code-complete)" "| app/Repositories/BaseRepository.php | extend |" "| - | extend |" "${TMP}/a.arch.md"
    arch_refused "extend row names no symbol" "transactional save" "${TMP}/a.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| app/Repositories/BaseRepository.php | extend |" "|  | reuse |" "${TMP}/b.arch.md"
    arch_refused "reuse row names no symbol" "transactional save" "${TMP}/b.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| new | searched app/ for \`Number\`; no generator exists |" "| new | |" "${TMP}/c.arch.md"
    arch_refused "new reuse row has no reason" "order number" "${TMP}/c.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| extend | shares" "| replace | shares" "${TMP}/d.arch.md"
    arch_refused "decision must be reuse, extend or new" "transactional save" "${TMP}/d.arch.md" --repo "${r}"
}

@test "arch: files rules resolve against --repo, and a new file may not exist yet" {
    local r; r=$(mkarchrepo r22 "arch_profile: harness")
    variant "$(FX harness-complete)" "| bin/gate.sh | no |" "| bin/missing.sh | no |" "${TMP}/a.arch.md"
    arch_refused "path does not exist" "bin/missing.sh" "${TMP}/a.arch.md" --repo "${r}"
    variant "$(FX harness-complete)" "| bin/gate.sh | no |" "| bin/gate.sh | maybe |" "${TMP}/b.arch.md"
    arch_refused "new must be yes or no" "bin/gate.sh" "${TMP}/b.arch.md" --repo "${r}"
    variant "$(FX harness-complete)" "| bin/gate.sh | no | refuses a session that skipped a required step | on-demand |" "| bin/gate.sh | no | refuses a session that skipped a required step | sometimes |" "${TMP}/c.arch.md"
    arch_refused "loaded must be" "bin/gate.sh" "${TMP}/c.arch.md" --repo "${r}"
    variant "$(FX harness-complete)" "| bin/gate.sh | no |" "| ../outside.sh | no |" "${TMP}/d.arch.md"
    arch_refused "relative to the repo" "../outside.sh" "${TMP}/d.arch.md" --repo "${r}"
    variant "$(FX harness-complete)" "| checks/arch-SC-9.sh | yes |" "| checks/not-yet.sh | yes |" "${TMP}/e.arch.md"
    arch_ok "${TMP}/e.arch.md" --repo "${r}"
}

@test "arch: a heading inside a fenced block does not truncate its section" {
    local r; r=$(mkarchrepo r23 "dod_profile: code")
    awk '/^## Interfaces$/{print; print ""; print "```text"; print "## Fake"; print "```"; next} {print}' "$(FX code-complete)" > "${TMP}/a.arch.md"
    arch_ok "${TMP}/a.arch.md" --repo "${r}"
}

@test "arch: CRLF changes no verdict, in either direction" {
    local r; r=$(mkarchrepo r24 "dod_profile: code")
    sed 's/$/\r/' "$(FX code-complete)" > "${TMP}/crlf.arch.md"
    arch_ok "${TMP}/crlf.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| order_lines | id | uuid | no | PK |" "| order_lines | id | uuid | no | |" "${TMP}/nopk.arch.md"
    sed 's/$/\r/' "${TMP}/nopk.arch.md" > "${TMP}/crlf2.arch.md"
    arch_refused "table has no primary key" "order_lines" "${TMP}/crlf2.arch.md" --repo "${r}"
}

@test "arch: a repeated section heading is refused, so a later bad row cannot hide" {
    local r; r=$(mkarchrepo r25 "dod_profile: code")
    { cat "$(FX code-complete)"; printf '\n## Interfaces\n\n| interface | method | params | returns | throws | layer |\n|---|---|---|---|---|---|\n| X | y | z | int | - | http |\n'; } > "${TMP}/a.arch.md"
    arch_refused "duplicate section Interfaces" "" "${TMP}/a.arch.md" --repo "${r}"
}

@test "arch: an unclosed fence is refused" {
    local r; r=$(mkarchrepo r26 "dod_profile: code")
    { cat "$(FX code-complete)"; printf '\n```text\nnever closed\n'; } > "${TMP}/a.arch.md"
    arch_refused "unclosed code fence" "" "${TMP}/a.arch.md" --repo "${r}"
}

@test "arch: a row with the wrong cell count, or a missing column, is refused" {
    local r; r=$(mkarchrepo r27 "dod_profile: code")
    variant "$(FX code-complete)" "| orders | id | uuid | no | PK | pk_orders | |" "| orders | id | uuid | no | PK | pk_orders |" "${TMP}/a.arch.md"
    arch_refused "row has 6 cells, header has 7" "orders" "${TMP}/a.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| index | references |" "| index |" "${TMP}/b.arch.md"
    run "${GATE_SH}" arch "${TMP}/b.arch.md" --repo "${r}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"lacks column references"* ]]
    variant "$(FX code-complete)" "| shares transaction handling |" "| shares | transaction handling |" "${TMP}/c.arch.md"
    arch_refused "cells" "" "${TMP}/c.arch.md" --repo "${r}"
}

@test "arch: row order and column order do not change the verdict" {
    local r; r=$(mkarchrepo r28 "dod_profile: code")
    awk '/^\| order_lines \| order_id /{fk=$0; next} {print} /^\|-------\|--------\|------\|------\|-----\|-------\|------------\|$/{print "@@FK@@"}' "$(FX code-complete)" > "${TMP}/t.md"
    local fk; fk=$(grep '^| order_lines | order_id ' "$(FX code-complete)")
    local c; c=$(<"${TMP}/t.md"); printf '%s\n' "${c/@@FK@@/${fk}}" > "${TMP}/a.arch.md"
    arch_ok "${TMP}/a.arch.md" --repo "${r}"
    run "${GATE_SH}" arch "$(FX code-complete)" --repo "${r}"
    [ "$status" -eq 0 ]
}

@test "arch: size budgets and load order numbers are integers in range" {
    local r v; r=$(mkarchrepo r29 "dod_profile: code")
    for v in 0 -1 1.5 abc "" 99999999999999999999; do
        variant "$(FX code-complete)" "| app/Services/OrderService.php | 200 | 30 |" "| app/Services/OrderService.php | ${v} | 30 |" "${TMP}/a.arch.md"
        run "${GATE_SH}" arch "${TMP}/a.arch.md" --repo "${r}"
        [ "$status" -eq 1 ]
        [[ "$output" == *"max lines must be an integer"* ]]
    done
    r=$(mkarchrepo r30 "arch_profile: harness")
    variant "$(FX harness-complete)" "| PROPOSE finalise | bin/gate.sh | 0 |" "| PROPOSE finalise | bin/gate.sh | lots |" "${TMP}/b.arch.md"
    arch_refused "tokens-max must be an integer" "PROPOSE finalise" "${TMP}/b.arch.md" --repo "${r}"
}

@test "arch: the output contract holds — success is one exact line, a refusal names path, problem and row" {
    local r; r=$(mkarchrepo r31 "dod_profile: code")
    run "${GATE_SH}" arch "$(FX code-complete)" --repo "${r}"
    [ "$output" = "arch: ok $(FX code-complete)" ]
    variant "$(FX code-complete)" "| orderId: string, qty: int |" "| orderId, qty: int |" "${TMP}/a.arch.md"
    run "${GATE_SH}" arch "${TMP}/a.arch.md" --repo "${r}"
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" =~ ^REFUSED\ arch\ ${TMP}/a\.arch\.md:\ .+\ \[.+\]$ ]]
    [[ "$output" == *"gate: 1 refusal(s)"* ]]
}

@test "arch: two runs give identical output, the spec is not modified, and the working directory does not matter" {
    local r; r=$(mkarchrepo r32 "dod_profile: code")
    variant "$(FX code-complete)" "| orderId: string, qty: int |" "| orderId, qty: int |" "${TMP}/a.arch.md"
    local before; before=$(cksum < "${TMP}/a.arch.md")
    run "${GATE_SH}" arch "${TMP}/a.arch.md" --repo "${r}"; local one="$output" s1="$status"
    cd /
    run "${GATE_SH}" arch "${TMP}/a.arch.md" --repo "${r}"
    [ "$output" = "$one" ]
    [ "$status" -eq "$s1" ]
    [ "$(cksum < "${TMP}/a.arch.md")" = "$before" ]
}

@test "arch: --help lists the arch subcommand" {
    run "${GATE_SH}" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"gate.sh arch"* ]]
}

@test "arch: arrow types are legal, unbalanced brackets are refused, and an untyped param after an arrow is caught" {
    local r; r=$(mkarchrepo r36 "dod_profile: code")
    variant "$(FX code-complete)" "| orderId: string, qty: int |" "| cb: (x: int) => void, qty: int |" "${TMP}/a.arch.md"
    arch_ok "${TMP}/a.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| orderId: string, qty: int |" "| cb: fn(i32) -> i32, qty: int |" "${TMP}/b.arch.md"
    arch_ok "${TMP}/b.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| orderId: string, qty: int |" "| cb: fn(i32) -> i32, qty |" "${TMP}/c.arch.md"
    arch_refused "param qty has no type" "OrderService.place" "${TMP}/c.arch.md" --repo "${r}"
    variant "$(FX code-complete)" "| orderId: string, qty: int |" "| orderId: fn(a, qty: int |" "${TMP}/d.arch.md"
    arch_refused "unbalanced brackets" "OrderService.place" "${TMP}/d.arch.md" --repo "${r}"
}

@test "arch: a data row made only of dashes is validated, not dropped as a separator" {
    local r; r=$(mkarchrepo r37 "dod_profile: code")
    variant "$(FX code-complete)" "| app/Services/OrderService.php | 200 | 30 |" "| - | - | - |" "${TMP}/a.arch.md"
    run "${GATE_SH}" arch "${TMP}/a.arch.md" --repo "${r}"
    [ "$status" -eq 1 ]
    variant "$(FX code-complete)" "| order number | - | new | searched app/ for \`Number\`; no generator exists |" "| - | - | - | - |" "${TMP}/b.arch.md"
    arch_refused "decision must be reuse, extend or new" "" "${TMP}/b.arch.md" --repo "${r}"
}

@test "arch: an unclosed frontmatter block, a repeated --repo, a VAULT.md that is a directory, and a missing option value are refused" {
    local r; r=$(mkarchrepo r38 "dod_profile: code")
    variant "$(FX code-complete)" "tags: [arch-spec]
---" "tags: [arch-spec]" "${TMP}/a.arch.md"
    arch_refused "frontmatter is not closed" "" "${TMP}/a.arch.md" --repo "${r}"
    run "${GATE_SH}" arch "$(FX code-complete)" --repo "${r}" --repo "${r}"
    [ "$status" -eq 2 ]
    [[ "$output" == *"--repo given twice"* ]]
    mkdir -p "${TMP}/r39/VAULT.md"
    run "${GATE_SH}" arch "$(FX code-complete)" --repo "${TMP}/r39"
    [ "$status" -eq 2 ]
    run "${GATE_SH}" all "$(FX code-complete)" --phase propose --repo
    [ "$status" -eq 2 ]
    [[ "$output" == *"--repo needs a directory"* ]]
}

@test "arch: a repo adds its own project type as data, and the framework code is not touched" {
    local r; r=$(mkarchrepo r40 "arch_profile: docs")
    mkdir -p "${r}/arch-profiles"
    printf '# profile: docs\n# section\tkind\tcolumns\trules\nOutline\ttable\theading:nonempty audience:enum(dev|ops)\nDiagram\tfence:mermaid\n' > "${r}/arch-profiles/docs.tsv"
    printf -- '---\ntype: arch-spec\nprofile: docs\nplan: x\n---\n\n# t\n\n## Outline\n\n| heading | audience |\n|---|---|\n| Intro | dev |\n\n## Diagram\n\n```mermaid\nflowchart LR\n  A --> B\n```\n' > "${TMP}/d.arch.md"
    arch_ok "${TMP}/d.arch.md" --repo "${r}"
    variant "${TMP}/d.arch.md" "| Intro | dev |" "| Intro | qa |" "${TMP}/e.arch.md"
    arch_refused "audience must be dev or ops" "Intro" "${TMP}/e.arch.md" --repo "${r}"
    awk '/^## Diagram$/{s=1;next} /^## /{s=0} !s' "${TMP}/d.arch.md" > "${TMP}/f.arch.md"
    arch_refused "missing section Diagram" "" "${TMP}/f.arch.md" --repo "${r}"
    # the framework's own profiles are not consulted for a spec that names the repo's
    variant "${TMP}/d.arch.md" "profile: docs" "profile: code" "${TMP}/g.arch.md"
    arch_refused "profile differs" "" "${TMP}/g.arch.md" --repo "${r}"
}

@test "arch: a repo's profile of the same name replaces the framework's" {
    local r; r=$(mkarchrepo r41 "arch_profile: code")
    mkdir -p "${r}/arch-profiles"
    printf 'Notes\ttable\ttopic:nonempty\n' > "${r}/arch-profiles/code.tsv"
    printf -- '---\ntype: arch-spec\nprofile: code\nplan: x\n---\n\n## Notes\n\n| topic |\n|---|\n| one |\n' > "${TMP}/a.arch.md"
    arch_ok "${TMP}/a.arch.md" --repo "${r}"
    arch_refused "missing section Notes" "" "$(FX code-complete)" --repo "${r}"
}

@test "arch: a malformed profile name, a missing profile file and a broken profile line are refused" {
    local r
    r=$(mkarchrepo r42 "arch_profile: ../code")
    arch_refused "invalid value" "../code" "$(FX code-complete)" --repo "${r}"
    r=$(mkarchrepo r43 "arch_profile: nosuch")
    arch_refused "invalid value" "nosuch" "$(FX code-complete)" --repo "${r}"
    r=$(mkarchrepo r44 "arch_profile: code")
    mkdir -p "${r}/arch-profiles"
    printf 'Notes\ttable\ttopic:shiny\n' > "${r}/arch-profiles/code.tsv"
    printf -- '---\ntype: arch-spec\nprofile: code\nplan: x\n---\n\n## Notes\n\n| topic |\n|---|\n| one |\n' > "${TMP}/a.arch.md"
    arch_refused "unknown validator shiny" "" "${TMP}/a.arch.md" --repo "${r}"
    printf 'Notes\tlist\ttopic:nonempty\n' > "${r}/arch-profiles/code.tsv"
    arch_refused "unknown section kind list" "" "${TMP}/a.arch.md" --repo "${r}"
}

@test "arch: only the profile a spec names is loaded, so another profile's file may be broken" {
    local r; r=$(mkarchrepo r45 "arch_profile: code")
    mkdir -p "${r}/arch-profiles"
    printf 'this line is not a profile\n' > "${r}/arch-profiles/other.tsv"
    arch_ok "$(FX code-complete)" --repo "${r}"
}

@test "arch: a spec that still holds a template placeholder is refused, and both templates are" {
    local r; r=$(mkarchrepo r33 "dod_profile: code")
    arch_refused "template placeholder" "" "${VAULT_ROOT}/arch-profiles/code.md" --repo "${r}"
    arch_refused "template placeholder" "" "${VAULT_ROOT}/arch-profiles/harness.md" --repo "${r}"
    variant "$(FX code-complete)" "| app/Services/OrderService.php | 200 | 30 |" "| path/to/Service.ext | 200 | 30 |" "${TMP}/a.arch.md"
    arch_refused "template placeholder" "" "${TMP}/a.arch.md" --repo "${r}"
}

@test "arch: a trailing comment on the plan's arch_spec value is ignored, as the template writes it" {
    local r; r=$(mkarchrepo r34 "arch_profile: code")
    cp "$(FX code-complete)" "${TMP}/good.arch.md"
    printf -- '---\ntype: plan\narch_spec: good.arch.md   # file name only\n---\n# p\n' > "${TMP}/commented.md"
    run "${GATE_SH}" arch "${TMP}/commented.md" --repo "${r}"
    [ "$status" -eq 0 ]
    [ "$output" = "arch: ok ${TMP}/good.arch.md" ]
    grep -q '^arch_spec:.*#' "${VAULT_ROOT}/templates/plan.md"
    sed 's/{{[a-z]*}}/x/g' "${VAULT_ROOT}/templates/plan.md" > "${TMP}/fromtemplate.md"
    r=$(mkarchrepo r35 "dod_profile: code")
    run "${GATE_SH}" arch "${TMP}/fromtemplate.md" --repo "${r}"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
