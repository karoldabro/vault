#!/usr/bin/env bats
# Contract tests for the /v-work step files that a session follows at pickup and close: they must
# name the goal runs, the background start and the push, so a session cannot skip them by reading.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    PICKUP="${VAULT_ROOT}/commands/_shared/feature-pickup.md"
    CLOSE="${VAULT_ROOT}/commands/v-work/steps/05-commit-capture.md"
}

# section <file> <heading prefix>: the lines of one section, up to the next heading of its level.
section() { awk -v h="$2" 'index($0, h) == 1 {f=1; next} f && /^## / {exit} f' "$1"; }

@test "T28: pickup runs the goal baseline in the background, pushes it, and names the repair on a refusal" {
    S=$(section "${PICKUP}" '## 0.4a Goal baseline')
    [ -n "$S" ]
    grep -qF 'bin/gate.sh goal baseline <plan>' <<<"$S"
    grep -qF 'run_in_background' <<<"$S"
    grep -qF -- '-m "goal baseline"' <<<"$S"
    grep -q 'Exit 1\*\* ends the session' <<<"$S"
    grep -q 'the operator repairs the script named in the `goal script`' <<<"$S"
    grep -q 'not written yet' <<<"$S"
}

@test "T28: pickup orders a /v-team master that has no repo column" {
    grep -q 'A `/v-team` master has no `repo` column' <<<"$(section "${PICKUP}" '## 0.2 ')"
}

@test "T29: the close marks own cases before done, runs the last goal run after it, and routes a failure to reconcile" {
    S=$(section "${CLOSE}" '## 5.1a ')
    [ -n "$S" ]
    grep -qF 'bin/gate.sh goal close <master> <id> <case id>...' <<<"$S"
    grep -q 'Exit 1 stops the close' <<<"$S"
    grep -qF 'bin/gate.sh goal last <master>' <<<"$S"
    grep -qF -- '-m "goal last run" <master>' <<<"$S"
    grep -qF 'run_in_background' <<<"$S"
    grep -q 'never skip it on your own reading' <<<"$S"
    grep -qF '`goal: last run failed` — put `/v-pm reconcile <master>`' <<<"$S"
    grep -qF '`goal: last run not run`' <<<"$S"
    grep -q 'nothing was written; go on' <<<"$S"
    awk '/goal close <master>/{c=NR} /pm-plan.sh set <master> <id> status=done/{d=NR} /goal last <master>/{l=NR} END{exit !(c && d && l && c < d && d < l)}' <<<"$S"
}
