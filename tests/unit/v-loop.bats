#!/usr/bin/env bats
# Tests for the /v-loop command, its rules file, and the campaign templates — file contracts only.
# The campaign loop itself is proven by running a campaign, not by a unit test.
#
# One case per enforcement row in vault/plans/2026-09-06-1053-v-loop-autonomous-campaign.md.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    CMD="${VAULT_ROOT}/commands/v-loop.md"
    RULES="${VAULT_ROOT}/commands/v-loop/campaign-rules.md"
}

@test "the command and its rules file exist" {
    [ -f "${CMD}" ]
    [ -f "${RULES}" ]
}

# --- E-1, E-2, E-4: evidence, injection, fixer is not verifier -----------------------------

@test "campaign-rules requires evidence from the running system" {
    grep -qi 'running system' "${RULES}"
    grep -qiE 'reading (code|source)' "${RULES}"
}

@test "every case must carry a failure shape, and the testing adapter still designs it up front" {
    # The shared rules demand that a case be able to fail; HOW is the adapter's answer.
    grep -qi 'failure shape' "${RULES}"
    ADAPTER="${VAULT_ROOT}/commands/v-loop/adapters/test-and-repair.md"
    grep -qi 'injection' "${ADAPTER}"
    grep -qi 'before the case runs' "${ADAPTER}"
    grep -q 'BLOCKED' "${ADAPTER}"
    # and the other adapter proves it a different way, or the split demonstrates nothing
    grep -qi 'control' "${VAULT_ROOT}/commands/v-loop/adapters/document-corpus.md"
}

@test "a model verifier always uses a second agent, and a command verifier need not" {
    CONTRACT="${VAULT_ROOT}/commands/v-loop/adapters.md"
    # the phrase wraps, so read the file as one line before matching it
    tr '\n' ' ' < "${CONTRACT}" | grep -qi 'skews *positive'
    grep -qi 'separate spawn' "${CONTRACT}"
    # the conditional is the point: a deterministic verifier spawns nobody
    grep -qi 'most deterministic thing available' "${CONTRACT}"
    grep -qi 'different agents' "${VAULT_ROOT}/commands/v-loop/adapters/test-and-repair.md"
}

@test "campaign-rules requires a defect to survive a check before it is filed" {
    grep -qi 'survive a check against current source\|survive a check against the shipped code' "${RULES}"
}

# --- E-3: concurrency, expressed so a session can decide it ---------------------------------

@test "the concurrency rule is disjoint conflict sets, not a count of agents" {
    grep -qi 'disjoint' "${RULES}"
    grep -qi 'conflicts_on' "${RULES}"
    # A bare "three agents at a time" is the count-shaped form this deliberately replaced.
    ! grep -qiE '(three|3) (campaign )?(agents|testers) at a time' "${RULES}"
}

# --- E-5: the caps, and a round count that survives a resume --------------------------------

@test "the command names both caps with a number" {
    grep -qE 'loop_max_rounds[^0-9]{0,40}[0-9]' "${CMD}"
    grep -qiE '(retry cap|max_fix_attempts)[^0-9]{0,40}[0-9]' "${CMD}"
}

@test "the round count is read back from state on resume" {
    grep -q 'rounds_used' "${CMD}"
    grep -q 'rounds_used' "${VAULT_ROOT}/templates/campaign/STATE.md"
    grep -qi 'resum' "${CMD}"
}

@test "a cap hit stops and escalates rather than continuing" {
    grep -qiE 'cap.{0,80}(escalat|stop)|(escalat|stop).{0,80}cap' "${CMD}"
}

# --- E-6: no rule restated from a shared module ---------------------------------------------

@test "the shared owned-rule list covers every module under commands/_shared" {
    # The pattern list lives in lib/shared-module-rules.tsv so checks/v-loop-SC-3.sh and
    # checks/v-method-SC-5.sh read one copy. The check itself names no module any more.
    local check="${VAULT_ROOT}/checks/v-loop-SC-3.sh"
    local rules="${VAULT_ROOT}/lib/shared-module-rules.tsv"
    [ -x "${check}" ]
    [ -f "${rules}" ]
    for m in "${VAULT_ROOT}"/commands/_shared/*.md; do
        grep -q "$(basename "${m}")" "${rules}" \
            || { echo "lib/shared-module-rules.tsv names no owner in $(basename "${m}")"; return 1; }
    done
}

# The repo is mounted read-only in the test container, so a negative case builds a scratch tree and
# points the real check at it. The check resolves its root as `$(dirname $0)/..`.
scratch_root() {
    local r="${BATS_TEST_TMPDIR}/root"
    mkdir -p "${r}/checks" "${r}/commands/v-loop/adapters" "${r}/commands/_shared" "${r}/lib"
    cp "${VAULT_ROOT}"/checks/v-loop-SC-*.sh "${VAULT_ROOT}/checks/v-loop-adapter-slots.sh" "${r}/checks/"
    cp "${RULES}" "${r}/commands/v-loop/campaign-rules.md"
    # The checks now cover the whole read set an agent receives, so the scratch tree carries it.
    cp "${CMD}" "${r}/commands/v-loop.md"
    cp "${VAULT_ROOT}/commands/v-loop/adapters.md" "${r}/commands/v-loop/"
    cp "${VAULT_ROOT}"/commands/v-loop/adapters/*.md "${r}/commands/v-loop/adapters/"
    cp "${VAULT_ROOT}"/commands/_shared/*.md "${r}/commands/_shared/"
    # The check reads its pattern list from lib/, so the scratch tree carries it too.
    cp "${VAULT_ROOT}/lib/shared-module-rules.tsv" "${r}/lib/"
    printf '%s' "${r}"
}

@test "the duplication check fails on a restated shared-module rule" {
    local r; r="$(scratch_root)"
    printf '\nEvery agent writes its artifact to disk as it works.\n' \
        >> "${r}/commands/v-loop/campaign-rules.md"
    run "${r}/checks/v-loop-SC-3.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"agent-conduct.md"* ]]
}

@test "the duplication check passes on the shipped file" {
    run "${VAULT_ROOT}/checks/v-loop-SC-3.sh"
    [ "$status" -eq 0 ]
}

# --- E-7: requirement form -------------------------------------------------------------------

@test "requirements outnumber prohibitions in both rule files" {
    run "${VAULT_ROOT}/checks/v-loop-SC-4.sh"
    [ "$status" -eq 0 ]
}

# --- E-8: the safety rules survive the line cap ----------------------------------------------

@test "all twelve safety rules are present" {
    run "${VAULT_ROOT}/checks/v-loop-SC-5.sh"
    [ "$status" -eq 0 ]
}

@test "the safety check fails when a rule is dropped" {
    local r; r="$(scratch_root)"
    grep -v 'pathspec' "${RULES}" > "${r}/commands/v-loop/campaign-rules.md"
    run "${r}/checks/v-loop-SC-5.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"stage each file by name"* ]]
}

# --- the precondition, the intake, and the routing --------------------------------------------

@test "the command refuses without an arena the operator names as disposable" {
    grep -qiE 'disposable|willing to lose' "${CMD}"
    grep -qi 'arena' "${CMD}"
    grep -qiE 'operator|in words' "${CMD}"
}

@test "the command asks all six intake questions" {
    grep -qi 'feature' "${CMD}"
    grep -qi 'branch' "${CMD}"
    grep -qi 'specification' "${CMD}"
    grep -qi 'data' "${CMD}"
    grep -qi 'cadence' "${CMD}"
    grep -qiE 'already known broken|already \*\*known broken\*\*|known broken' "${CMD}"
}

@test "the command names a cheaper alternative, as ADR-015 requires" {
    grep -q '/v-work' "${CMD}"
    grep -q '/v-do' "${CMD}"
    grep -q '/v-team' "${CMD}"
}

@test "the command says the unattended runner is handed over, not installed" {
    grep -qi 'crontab' "${CMD}"
    grep -qi 'installs none of it\|hands the operator\|give the operator' "${CMD}"
}

# --- the spawn envelope and the templates ------------------------------------------------------

@test "the spawn envelope carries the rules, the brief and the conflict scope" {
    grep -qi 'envelope' "${CMD}"
    grep -q 'campaign-rules.md' "${CMD}"
    grep -q 'AGENT-BRIEF' "${CMD}"
    grep -q 'conflicts_on' "${CMD}"
}

@test "every campaign template the command names exists" {
    local missing=0
    while read -r t; do
        [ -n "${t}" ] || continue
        [ -f "${VAULT_ROOT}/${t}" ] || { echo "missing ${t}"; missing=1; }
    done < <(grep -oE 'templates/campaign/[A-Za-z0-9_.-]+' "${CMD}" | sort -u)
    [ "${missing}" -eq 0 ]
}

@test "the result template ends with the verdict line the orchestrator reads" {
    local f="${VAULT_ROOT}/templates/campaign/result.md"
    [ -f "${f}" ]
    [ "$(tail -n1 "${f}")" = "VERDICT: PASS | FAIL | BLOCKED" ]
}

@test "the ledger carries an injection field and a conflict scope" {
    local f="${VAULT_ROOT}/templates/campaign/ledger.md"
    grep -q '`injection`' "${f}"
    grep -q '`conflicts_on`' "${f}"
    grep -q 'blocked' "${f}"
}

@test "the defects template shares the defect-ledger column set" {
    local f="${VAULT_ROOT}/templates/campaign/defects.md"
    for col in id defect repair test recurrences; do
        grep -q "| ${col} " "${f}" || grep -qE "\\| *${col} *\\|" "${f}" \
            || { echo "no ${col} column"; return 1; }
    done
}

# --- the vault docs -----------------------------------------------------------------------------

@test "the indication is registered in the index" {
    grep -q 'campaign-evidence-from-the-running-system' "${VAULT_ROOT}/vault/indications/_index.md"
    [ -f "${VAULT_ROOT}/vault/indications/campaign-evidence-from-the-running-system.md" ]
}

@test "the gitignore template carries the results rule" {
    grep -q 'campaigns/\*/results/' "${VAULT_ROOT}/templates/vault.gitignore"
}

@test "install.sh links the command and its subdirectory" {
    make_test_home
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    assert_symlink_to "${HOME}/.claude/commands/v-loop.md" "${VAULT_ROOT}/commands/v-loop.md"
    assert_symlink_to "${HOME}/.claude/commands/v-loop"    "${VAULT_ROOT}/commands/v-loop"
    cleanup_test_home
}

# --- the engine is the loop; the task is an adapter ---------------------------
#
# The command was welded to testing in four places. These prove it is not any more, and that the
# adapter layer is a real extension point rather than a rename.

@test "the engine names no task vocabulary of its own" {
    ! grep -qiE 'executable test|(^|[^-])tester|browser' "${CMD}"
}

@test "the engine names its adapter contract and both shipped adapters" {
    grep -q 'commands/v-loop/adapters.md' "${CMD}"
    grep -q 'adapters/test-and-repair' "${CMD}"
    grep -q 'adapters/document-corpus' "${CMD}"
}

@test "both refusals are stated separately, and the restore is run rather than collected" {
    grep -qiE 'runs? (it )?once at intake|run once at intake' "${CMD}"
    grep -qiE 're-read|re.read the arena' "${CMD}"
    grep -qi 'untracked' "${CMD}"
}

@test "every adapter fills all six slots and two adapters exist" {
    run "${VAULT_ROOT}/checks/v-loop-adapter-slots.sh"
    [ "$status" -eq 0 ]
}

@test "the slot check refuses a single adapter" {
    tmp="$(mktemp -d)"
    cp -r "${VAULT_ROOT}" "${tmp}/repo" 2>/dev/null || skip "cannot copy the repo"
    rm -f "${tmp}/repo/commands/v-loop/adapters/document-corpus.md"
    run "${tmp}/repo/checks/v-loop-adapter-slots.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"two is the floor"* ]]
}

@test "the task-specific rules survive in the testing adapter, not in the shared rules" {
    ADAPTER="${VAULT_ROOT}/commands/v-loop/adapters/test-and-repair.md"
    grep -qi 'executable test' "${ADAPTER}"
    grep -qi 'textContent' "${ADAPTER}"
    grep -qi 'queue' "${ADAPTER}"
    ! grep -qi 'textContent' "${RULES}"
}
