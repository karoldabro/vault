#!/usr/bin/env bats
# Behaviour tests for the goal runs: `gate.sh goal baseline|close|last|failing` (lib/goal-run.sh) and
# `pm-plan.sh gap`. Contract: templates/master-plan.md `## Goal fit`, `## Goal cases`, `## Sessions`.
#
# Each test copies tests/fixtures/goal/complete.md into a git repo under $TMP, so `goal close` can
# compare against a committed copy, and writes the goal script the plan's `goal script` row names.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    GATE_SH="${VAULT_ROOT}/bin/gate.sh"
    PP="${VAULT_ROOT}/bin/pm-plan.sh"
    TMP="$(mktemp -d)"
    unset GATE
    export XDG_STATE_HOME="${TMP}/state"
    R="${TMP}/r"; mkdir -p "${R}/checks"
    PLAN="${R}/plan.md"
    cp "${VAULT_ROOT}/tests/fixtures/goal/complete.md" "${PLAN}"
    goal_script 1
    git -C "${R}" init -q
    commit
}

teardown() { [ -n "${TMP:-}" ] && rm -rf "${TMP}"; }

commit() { git -C "${R}" add -A && git -C "${R}" -c user.name=t -c user.email=t@t commit -qm x --allow-empty; }

# goal_script <exit code> [<output line>...] — the script the `goal script` row names.
goal_script() {
    local code=$1; shift
    { printf '#!/usr/bin/env bash\n'; local l; for l in "$@"; do printf 'echo %q\n' "$l"; done; printf 'exit %s\n' "$code"; } > "${R}/checks/report-all.sh"
    chmod +x "${R}/checks/report-all.sh"
}

# all_done — every session row of the fixture reads done.
all_done() { sed -i -E 's/^(\| S[23] \| [^|]+\| [^|]+\|) todo \|/\1 done |/' "${PLAN}"; }

row() { grep "^| $1 |" "${PLAN}"; }

@test "T21: a first goal run that passes is refused and writes nothing" {
    goal_script 0
    run "${GATE_SH}" goal baseline "${PLAN}"
    [ "$status" -eq 1 ]
    grep -q 'REFUSED goal .*passes before the open sessions' <<<"$output"
    [ "$(row baseline)" = "| baseline | | |" ]
}

@test "T22: a failing first run is written; exit 2, a set row, no script yet and no opt-in write nothing" {
    run "${GATE_SH}" goal baseline "${PLAN}"
    [ "$status" -eq 0 ]
    grep -Eq '^\| baseline \| [0-9]{4}-[0-9]{2}-[0-9]{2} exit 1 \| `checks/report-all.sh` \|$' "${PLAN}"
    goal_script 0
    run "${GATE_SH}" goal baseline "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q 'already recorded' <<<"$output"
    sed -i -E 's/^\| baseline \|.*$/| baseline | | |/' "${PLAN}"
    goal_script 2
    run "${GATE_SH}" goal baseline "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q 'exited 2' <<<"$output"
    [ "$(row baseline)" = "| baseline | | |" ]
    rm "${R}/checks/report-all.sh"
    run "${GATE_SH}" goal baseline "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q 'goal script is not written yet' <<<"$output"
    [ "$(row baseline)" = "| baseline | | |" ]
    cp "${PLAN}" "${TMP}/done.md"; PLAN="${TMP}/done.md" all_done
    run "${GATE_SH}" goal last "${TMP}/done.md"
    [ "$status" -eq 1 ]
    grep -q 'REFUSED goal .*no executable file' <<<"$output"
    run "${GATE_SH}" goal baseline /nonexistent/plan.md
    [ "$status" -eq 2 ]
    grep -q 'cannot read' <<<"$output"
    sed '/^goal_fit:/d' "${PLAN}" > "${R}/old.md"
    run "${GATE_SH}" goal baseline "${R}/old.md"
    [ "$status" -eq 0 ]
    grep -q 'no goal_fit: required' <<<"$output"
    sed -i 's/^| goal script |.*$/| goal script | | |/' "${PLAN}"
    run "${GATE_SH}" goal "${PLAN}"
    [ "$status" -eq 1 ]
    grep -q 'REFUSED goal .*goal script row is empty' <<<"$output"
}

@test "T23: a named or hand-edited pass on another session's case is refused; an own case flips" {
    run "${GATE_SH}" goal close "${PLAN}" S2 G-1 G-2
    [ "$status" -eq 1 ]
    grep -q 'G-2 is owned by S3, so S2 may not mark it pass' <<<"$output"
    [ "$(row G-1)" = "| G-1 | flat specs | 10 | S2 | todo |" ]
    [ "$(row G-2)" = "| G-2 | nested specs | 18 | S3 | todo |" ]
    run "${GATE_SH}" goal close "${PLAN}" S2 G-1
    [ "$status" -eq 0 ]
    [ "$(row G-1)" = "| G-1 | flat specs | 10 | S2 | pass |" ]
    sed -i 's/^| G-2 | nested specs | 18 | S3 | todo |/| G-2 | nested specs | 18 | S3 | pass |/' "${PLAN}"
    run "${GATE_SH}" goal close "${PLAN}" S2
    [ "$status" -eq 1 ]
    grep -q 'G-2 reads pass, the committed copy reads todo' <<<"$output"
    cp "${PLAN}" "${TMP}/loose.md"
    sed -i 's/^| G-2 | nested specs | 18 | S3 | pass |/| G-2 | nested specs | 18 | S3 | todo |/' "${TMP}/loose.md"
    run "${GATE_SH}" goal close "${TMP}/loose.md" S3 G-2
    [ "$status" -eq 0 ]
    grep -q 'no committed copy' <<<"$output"
    grep -q '^| G-2 | nested specs | 18 | S3 | pass |$' "${TMP}/loose.md"
    run "${GATE_SH}" goal close "${PLAN}" S9
    [ "$status" -eq 1 ]
    grep -q 'has no row S9' <<<"$output"
}

@test "T23: a close by a parallel session that is not committed yet does not block another close" {
    run "${GATE_SH}" goal close "${PLAN}" S2 G-1
    [ "$status" -eq 0 ]
    run "${GATE_SH}" goal close "${PLAN}" S3 G-2
    [ "$status" -eq 0 ]
    [ "$(row G-2)" = "| G-2 | nested specs | 18 | S3 | pass |" ]
    printf -- '---\nsession_of: plan.md#S2\n---\n# s\n' > "${R}/s2.md"
    run "${GATE_SH}" goal close "${R}/s2.md" S3
    [ "$status" -eq 1 ]
    grep -q 'is session S2, so it may not close S3' <<<"$output"
}

@test "T23: a CRLF master is refused by every goal writer, set and gap, by name" {
    sed -i 's/$/\r/' "${PLAN}"
    cp "${PLAN}" "${TMP}/before.md"
    for cmd in "${GATE_SH} goal baseline" "${GATE_SH} goal last" "${PP} gap"; do
        run $cmd "${PLAN}" $( [ "${cmd##* }" = gap ] && echo G-1 )
        [ "$status" -eq 1 ]
        grep -q 'CRLF line endings' <<<"$output"
    done
    run "${GATE_SH}" goal close "${PLAN}" S2 G-1
    [ "$status" -eq 1 ]
    grep -q 'CRLF line endings' <<<"$output"
    run "${PP}" set "${PLAN}" S2 status=done
    [ "$status" -eq 1 ]
    grep -q 'CRLF line endings' <<<"$output"
    cmp "${PLAN}" "${TMP}/before.md"
}

@test "T24: a close after an unowned row is appended is refused; the last run runs only when every row is done" {
    sed -i 's/^| G-3 | signed release check | 2 | operator | todo |/&\n| G-4 | deferred specs | 5 | | todo |/' "${PLAN}"
    run "${GATE_SH}" goal close "${PLAN}" S2 G-1
    [ "$status" -eq 1 ]
    grep -q 'REFUSED goal .*owned 30/35' <<<"$output"
    [ "$(row G-1)" = "| G-1 | flat specs | 10 | S2 | todo |" ]
    sed -i '/^| G-4 |/d' "${PLAN}"
    run "${GATE_SH}" goal last "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q 'goal: last run waits; open rows: S2 S3' <<<"$output"
    all_done
    goal_script 1 "fail nested specs n04"
    run "${GATE_SH}" goal last "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q 'goal: last run failed' <<<"$output"
    grep -Eq '^\| last run \| [0-9-]+ exit 1 \| `.*/state/vault/goal-run/r-plan-[0-9]+\.log` \|$' "${PLAN}"
    LOG=$(ls "${XDG_STATE_HOME}"/vault/goal-run/r-plan-*.log)
    grep -q 'fail nested specs n04' "${LOG}"
    goal_script 2
    run "${GATE_SH}" goal last "${PLAN}"
    grep -q 'goal: last run not run' <<<"$output"
    grep -Eq '^\| last run \| [0-9-]+ not run \|' "${PLAN}"
    sed -i 's/^| runtime limit | 2 h |/| runtime limit | 0.02 min |/' "${PLAN}"
    printf '#!/usr/bin/env bash\nsleep 5\n' > "${R}/checks/report-all.sh"
    run "${GATE_SH}" goal last "${PLAN}"
    grep -q 'goal: last run failed .*exit 124' <<<"$output"
    grep -Eq '^\| last run \| [0-9-]+ exit 124 \|' "${PLAN}"
    saved=$(row 'last run'); stamp=$(stat -c %Y "${LOG}"); sleep 1
    exec 7>"${LOG%.log}.lock"; flock 7
    run "${GATE_SH}" goal last "${PLAN}"
    grep -q 'goal: last run already running' <<<"$output"
    exec 7>&-
    [ "$(row 'last run')" = "$saved" ]
    [ "$(stat -c %Y "${LOG}")" = "$stamp" ]
    sed -i 's/^| runtime limit | 0.02 min |/| runtime limit | 2 h |/' "${PLAN}"
    printf '#!/usr/bin/env bash\nsleep 5 >/dev/null 2>&1 3>&- &\nexit 1\n' > "${R}/checks/report-all.sh"
    "${GATE_SH}" goal last "${PLAN}"
    run "${GATE_SH}" goal last "${PLAN}"
    grep -q 'goal: last run failed' <<<"$output"
}

@test "T24: goal failing names a group with one failing line, a group never printed, and operator cases" {
    all_done
    goal_script 1 "pass flat specs f01" "pass nested specs n01" "fail nested specs n04"
    sed -i 's/^| G-1 | flat specs | 10 |/| G-1 | flat specs | 1 |/; s/^| G-2 | nested specs | 18 |/| G-2 | nested specs | 1 |/' "${PLAN}"
    "${GATE_SH}" goal last "${PLAN}"
    run "${GATE_SH}" goal failing "${PLAN}"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf 'G-2\noperator G-3')" ]
    goal_script 1 "pass flat specs f01" "pass nested specs n01" "pass signed release check" "pass signed release check"
    "${GATE_SH}" goal last "${PLAN}"
    run "${GATE_SH}" goal failing "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q 'every goal case passing' <<<"$output"
    grep -q 'pass signed release check' <<<"$output"
    rm -rf "${XDG_STATE_HOME}"
    run "${GATE_SH}" goal failing "${PLAN}"
    [ "$status" -eq 1 ]
    grep -q 'no saved goal log' <<<"$output"
}

@test "T25: gap appends one row per repo, re-owns the cases, passes gate.sh master, and order reads no repo" {
    all_done
    sed -i 's/^| G-2 | nested specs | 18 | S3 | todo |/| G-2 | nested specs | 18 | S3 | pass |/' "${PLAN}"
    run timeout 10 "${PP}" gap "${PLAN}" G-1 G-2 G-1
    [ "$status" -eq 0 ]
    grep -q 'pm: gap round 1: S4 owns G-1, G-2' <<<"$output"
    [ "$(row S4)" = "| S4 | gap round 1: G-1, G-2; split: gap round | /v-team | todo |  |  |  |" ]
    [ "$(row G-1)" = "| G-1 | flat specs | 10 | S4 | todo |" ]
    [ "$(row G-2)" = "| G-2 | nested specs | 18 | S4 | todo |" ]
    run "${GATE_SH}" master "${PLAN}"
    [ "$status" -eq 0 ]
    sed -i 's/^tags:/tier: small\ntags:/' "${PLAN}"
    run "${GATE_SH}" master "${PLAN}"
    [ "$status" -eq 0 ]
    run "${PP}" order "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q "$(printf '\tS4\ttodo\trunnable\t-\t-')" <<<"$output"
    run timeout 10 "${PP}" set "${PLAN}" S4 evidence='a|b'
    [ "$status" -eq 0 ]
    [ "$(row S4)" = '| S4 | gap round 1: G-1, G-2; split: gap round | /v-team | todo |  |  | a\|b |' ]
    run "${PP}" check "${PLAN}"
    [ "$status" -eq 1 ]
    grep -q 'no repo column' <<<"$output"
}

@test "T25: gap on a plan with a repo column appends one row per repo of the owners" {
    all_done
    awk 'BEGIN{FS=OFS="|"} /^## Sessions/{s=1} /^## Cross/{s=0}
         s && /^\| id /{print "| id | repo | scope | command | status | depends | date | evidence |"; next}
         s && /^\|----/{print "|----|------|-------|---------|--------|---------|------|----------|"; next}
         s && /^\| S/{r = ($2 ~ /S3/) ? " /b " : " /a "; $2 = $2 "|" r; print; next} {print}' "${PLAN}" > "${TMP}/x" && cat "${TMP}/x" > "${PLAN}"
    run "${PP}" gap "${PLAN}" G-1 G-2
    [ "$status" -eq 0 ]
    [ "$(row S4)" = "| S4 | /a | gap round 1: G-1; split: gap round | /v-team | todo |  |  |  |" ]
    [ "$(row S5)" = "| S5 | /b | gap round 1: G-2; split: gap round | /v-team | todo |  |  |  |" ]
    [ "$(row G-1)" = "| G-1 | flat specs | 10 | S4 | todo |" ]
    [ "$(row G-2)" = "| G-2 | nested specs | 18 | S5 | todo |" ]
}

@test "T26: gap_rounds rises by one; an unknown id, an operator case and a plan not opted in are refused" {
    run "${PP}" gap "${PLAN}" G-1
    [ "$status" -eq 0 ]
    grep -q '^gap_rounds: 1$' "${PLAN}"
    run "${PP}" gap "${PLAN}" G-2
    grep -q '^gap_rounds: 2$' "${PLAN}"
    cp "${PLAN}" "${TMP}/before.md"
    run "${PP}" gap "${PLAN}" G-1 G-9
    [ "$status" -eq 1 ]
    grep -q 'has no row G-9' <<<"$output"
    cmp "${PLAN}" "${TMP}/before.md"
    run "${PP}" gap "${PLAN}" G-1 G-3
    [ "$status" -eq 1 ]
    grep -q "G-3 is the operator's case" <<<"$output"
    cmp "${PLAN}" "${TMP}/before.md"
    sed -i 's/^| G-3 | signed release check | 2 | operator | todo |/&\n| G-4 | loose | 1 |  | todo |/' "${PLAN}"
    cp "${PLAN}" "${TMP}/before.md"
    run "${PP}" gap "${PLAN}" G-4
    [ "$status" -eq 1 ]
    grep -q 'G-4 has no owner' <<<"$output"
    cmp "${PLAN}" "${TMP}/before.md"
    sed '/^goal_fit:/d' "${PLAN}" > "${R}/old.md"
    cp "${R}/old.md" "${TMP}/old-before.md"
    run "${PP}" gap "${R}/old.md" G-1
    [ "$status" -eq 1 ]
    grep -q 'no goal_fit: required' <<<"$output"
    cmp "${R}/old.md" "${TMP}/old-before.md"
}

@test "T27: a fourth gap round is refused and writes nothing" {
    sed -i 's/^| S3 | the reader for nested specs |/| S09 | the reader for nested specs |/; s/^| C-2 | flat reader | S2 | S3 |/| C-2 | flat reader | S2 | S09 |/; s/| S2, S3 |/| S2, S09 |/' "${PLAN}"
    run "${PP}" gap "${PLAN}" G-1
    [ "$status" -eq 0 ]
    grep -q 'S10 owns G-1' <<<"$output"
    for _ in 1 2; do "${PP}" gap "${PLAN}" G-1 >/dev/null; done
    grep -q '^gap_rounds: 3$' "${PLAN}"
    cp "${PLAN}" "${TMP}/before.md"
    run "${PP}" gap "${PLAN}" G-1
    [ "$status" -eq 1 ]
    grep -q 'gap_rounds is 3; the loop stops at 3' <<<"$output"
    cmp "${PLAN}" "${TMP}/before.md"
}

@test "T24: a group needs count passing lines; a passing last run reads passed; a dropped row does not hold it back" {
    sed -i 's/^| S2 | the reader for flat specs | \/v-team | todo |/| S2 | the reader for flat specs | \/v-team | done |/; s/^| S3 | the reader for nested specs | \/v-team | todo |/| S3 | the reader for nested specs | \/v-team | dropped |/' "${PLAN}"
    goal_script 0
    run "${GATE_SH}" goal last "${PLAN}"
    [ "$status" -eq 0 ]
    grep -q 'goal: last run passed' <<<"$output"
    grep -Eq '^\| last run \| [0-9-]+ exit 0 \|' "${PLAN}"
    goal_script 1 "ok 1 flat specs f01"
    "${GATE_SH}" goal last "${PLAN}"
    run "${GATE_SH}" goal failing "${PLAN}"
    grep -qx 'G-1' <<<"$output"
}

@test "T25: close, set and gap wait for the master's lock, then write" {
    exec 7<"${PLAN}"; flock 7
    run timeout 3 "${GATE_SH}" goal close "${PLAN}" S2 G-1
    [ "$status" -eq 124 ]
    run timeout 3 "${PP}" set "${PLAN}" S2 date=2026-01-01
    [ "$status" -eq 124 ]
    run timeout 3 "${PP}" gap "${PLAN}" G-1
    [ "$status" -eq 124 ]
    [ "$(row G-1)" = "| G-1 | flat specs | 10 | S2 | todo |" ]
    exec 7<&-
    run "${GATE_SH}" goal close "${PLAN}" S2 G-1
    [ "$status" -eq 0 ]
    [ "$(row G-1)" = "| G-1 | flat specs | 10 | S2 | pass |" ]
}

@test "T25: a gap row escapes a pipe in its case ids" {
    sed -i 's/^| G-1 | flat specs |/| G-1\\|a | flat specs |/' "${PLAN}"
    run "${PP}" gap "${PLAN}" 'G-1|a'
    [ "$status" -eq 0 ]
    grep -qF '| S4 | gap round 1: G-1\|a; split: gap round |' "${PLAN}"
}
