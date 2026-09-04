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
    run "${GATE_SH}" all "${f}" --phase propose
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

@test "readers passes a plan whose lifecycle row is the none row" {
    local f
    f=$(mkplan_lifecycle nothing 'none')
    run "${GATE_SH}" readers "${f}"
    [ "$status" -eq 0 ]
}
