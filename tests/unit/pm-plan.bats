#!/usr/bin/env bats
# Tests for bin/pm-plan.sh — check, order and set on the fixture plan and on variants built from it.
# Contract: templates/feature-plan.md, templates/handoff.md, templates/master-plan.md.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    PP="${VAULT_ROOT}/bin/pm-plan.sh"
    T="$(mktemp -d)"
    cp -r "${VAULT_ROOT}/tests/fixtures/pm/valid" "${T}/p"
    sed -i "s#@DIR@#${T}/p#g" "${T}/p/plan.md" "${T}"/p/briefs/*.md
    PLAN="${T}/p/plan.md"
}

teardown() { rm -rf "${T}"; }

@test "check accepts the valid fixture" {
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"pm: ok"* ]]
}

@test "T-1 check refuses a row with no brief and names the id" {
    rm -f "${T}"/p/briefs/S2-*.md
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"S2 has no brief"* ]]
}

@test "check refuses two briefs for one id" {
    cp "${T}"/p/briefs/S2-*.md "${T}/p/briefs/S2-copy.md"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"S2 has 2 briefs"* ]]
}

@test "check refuses a brief with no run line" {
    sed -i '/^cd /d' "${T}"/p/briefs/S2-*.md
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no run line"* ]]
}

@test "T-2 check refuses a run line whose command or repo differs from its row" {
    sed -i 's#"/v-work#"/v-team#' "${T}"/p/briefs/S2-*.md
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"S2 run line runs /v-team, its row names /v-work"* ]]
    cp -r "${VAULT_ROOT}/tests/fixtures/pm/valid/briefs/." "${T}/p/briefs/"
    sed -i "s#@DIR@#${T}/p#g" "${T}"/p/briefs/*.md
    sed -i 's#^cd /tmp/demo/admin#cd /tmp/demo/other#' "${T}"/p/briefs/S2-*.md
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"S2 run line runs in /tmp/demo/other"* ]]
}

@test "T-4 check refuses empty success criteria and a criterion no session reaches" {
    cp "${PLAN}" "${T}/bak"
    sed -i '/^| SC-1 |/d' "${PLAN}"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Success criteria is empty"* ]]
    cp "${T}/bak" "${PLAN}"
    sed -i 's/^\(| SC-1 |[^|]*|\)[^|]*|/\1  |/' "${PLAN}"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"SC-1 names no session"* ]]
}

@test "T-5 check refuses a missing default done line and accepts blank states" {
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 0 ]
    sed -i '/^| DD-3 |/d' "${PLAN}"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"lacks default line DD-3"* ]]
}

@test "T-6 check refuses a contract whose consumer does not depend on its producer" {
    sed -i 's/^\(| S2 |[^|]*|[^|]*|[^|]*|[^|]*|\) S1 |/\1  |/' "${PLAN}"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"S2 does not list S1 in depends"* ]]
}

@test "T-7 check and order refuse a depends cycle" {
    sed -i 's/^\(| S1 |[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*|/\1 S2 |/' "${PLAN}"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"depends cycle"* ]]
    run "${PP}" order "${PLAN}"
    [ "$status" -eq 1 ]
}

@test "T-3 order prints waves and readiness from depends" {
    run "${PP}" order "${PLAN}"
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == 1$'\t'S1$'\t'todo$'\t'runnable* ]]
    [[ "${lines[1]}" == 2$'\t'S2$'\t'todo$'\t'waits:S1* ]]
    "${PP}" set "${PLAN}" S1 status=dropped
    run "${PP}" order "${PLAN}"
    [[ "${lines[1]}" == *$'\t'blocked:S1$'\t'* ]]
    "${PP}" set "${PLAN}" S1 status=done
    run "${PP}" order "${PLAN}"
    [[ "${lines[1]}" == *$'\t'runnable$'\t'* ]]
}

@test "set rewrites one row, escapes a pipe, and refuses an unknown id or column" {
    run "${PP}" set "${PLAN}" S1 status=doing 'evidence=a | b'
    [ "$status" -eq 0 ]
    grep -qF '| S1 | /tmp/demo/api | export endpoint | /v-team | doing |' "${PLAN}"
    grep -qF 'a \| b' "${PLAN}"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 0 ]
    run "${PP}" set "${PLAN}" S9 status=done
    [ "$status" -eq 1 ]
    run "${PP}" set "${PLAN}" S1 colour=red
    [ "$status" -eq 1 ]
}

@test "T-8 two concurrent set calls both land" {
    "${PP}" set "${PLAN}" S1 date=2026-01-01 & "${PP}" set "${PLAN}" S2 date=2026-01-02 & wait
    grep -q '^| S1 .*| 2026-01-01 |' "${PLAN}"
    grep -q '^| S2 .*| 2026-01-02 |' "${PLAN}"
}

@test "T-9 an appended row with its brief passes check" {
    sed -i '/^| S2 |/a | S3 | /tmp/demo/admin | export docs | /v-do | todo | S2 | | | | added by S2 |' "${PLAN}"
    sed -i 's/^| C-1 |.*/&\n| C-2 | export button | S2 | S3 | the button id export-csv |/' "${PLAN}"
    sed -e 's/^id: S2/id: S3/' -e 's#"/v-work \(.*\)\#S2"#"/v-do \1\#S3"#' "${T}"/p/briefs/S2-*.md > "${T}/p/briefs/S3-docs.md"
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 0 ]
}

@test "a ~ repo path is expanded before it is compared" {
    sed -i "s#| /tmp/demo/api |#| ~/demo-api |#" "${PLAN}"
    sed -i "s#^cd /tmp/demo/api#cd ${HOME}/demo-api#" "${T}"/p/briefs/S1-*.md
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 0 ]
}
