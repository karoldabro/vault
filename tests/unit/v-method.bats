#!/usr/bin/env bats
# Contract tests for /v-method — the command that writes a method and runs no stage.
#
# Two of these are load-bearing. The routing checks are the only thing standing between a heuristic
# table and a table with a blank stopping rule, so each is planted with the violation it exists to
# catch and watched go red before it is trusted green. And the duplication check reads a shared
# pattern list, so a planted restatement proves the list is actually consulted.
#
# Absence is asserted with `run grep` and a status check. A command prefixed with `!` is exempt from
# set -e, so `! grep -q <present string>` returns success and the assertion is decorative.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    CMD="${VAULT_ROOT}/commands/v-method.md"
    REF="${VAULT_ROOT}/commands/v-method/routing.md"
    TPL="${VAULT_ROOT}/templates/method.md"
    SC3="${VAULT_ROOT}/checks/v-method-SC-3.sh"
    SC4="${VAULT_ROOT}/checks/v-method-SC-4.sh"
    SC5="${VAULT_ROOT}/checks/v-method-SC-5.sh"
    TMP="$(mktemp -d)"
}

teardown() {
    [ -n "${TMP:-}" ] && rm -rf "${TMP}"
    return 0
}

# ---------------------------------------------------------------- shipped files

@test "the command and its routing reference both exist" {
    [ -f "${CMD}" ]
    [ -f "${REF}" ]
    [ -f "${TPL}" ]
}

@test "install.sh links commands by glob, so a new command needs no installer edit" {
    # If this ever stops being true, /v-method silently fails to install.
    run grep -qE '\$\{?src_dir\}?"?/\*\.md' "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    run grep -qE '\$\{?src_dir\}?"?/\*/' "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    # And the command is not named anywhere in the installer, which is what "by glob" means.
    run grep -q 'v-method' "${VAULT_ROOT}/install.sh"
    [ "$status" -ne 0 ]
}

@test "the command has a frontmatter description, which the plugin picker reads" {
    run head -1 "${CMD}"
    [ "$status" -eq 0 ]
    [[ "$output" == "---" ]]
    run grep -qE '^description: .{40,}' "${CMD}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- the command's contract

@test "the command refuses without a problem statement, an observable criterion, or above the ladder" {
    run grep -qi 'problem statement' "${CMD}"
    [ "$status" -eq 0 ]
    run grep -q 'WHEN <trigger> THE SYSTEM SHALL' "${CMD}"
    [ "$status" -eq 0 ]
    run grep -q 'v-ask' "${CMD}"
    [ "$status" -eq 0 ]
}

@test "the command asks which of budget and criteria is fixed" {
    run grep -qiE 'budget fixed|which is fixed|budget, or are the criteria' "${CMD}"
    [ "$status" -eq 0 ]
}

@test "the command states that writing a methodology up front is unevidenced" {
    # The one claim this command could make and could not support. It says so instead.
    run grep -qiE 'no study shows' "${CMD}"
    [ "$status" -eq 0 ]
}

@test "the command writes a method and runs no stage" {
    run grep -qi 'runs no stage' "${CMD}"
    [ "$status" -eq 0 ]
}

@test "the template carries all five per-stage fields plus the routing record" {
    for field in command seats tools 'exit evidence' 'kill criterion'; do
        run grep -qi "${field}" "${TPL}"
        [ "$status" -eq 0 ]
    done
    run grep -q 'Routing record' "${TPL}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------- SC-3, planted

@test "SC-3 passes on the shipped routing table" {
    run "${SC3}"
    [ "$status" -eq 0 ]
}

@test "SC-3 goes red on a planted blank stopping rule" {
    local work="${TMP}/repo"
    mkdir -p "${work}/commands/v-method" "${work}/checks"
    cp "${SC3}" "${work}/checks/"
    sed 's/| the constraint moves, then re-identify |/|  |/' "${REF}" > "${work}/commands/v-method/routing.md"
    run grep -qE '\|[[:space:]]+\|$' "${work}/commands/v-method/routing.md"
    [ "$status" -eq 0 ]
    run "${work}/checks/$(basename "${SC3}")"
    [ "$status" -eq 1 ]
    [[ "$output" == *"blank cell"* ]]
}

@test "SC-3 goes red on a property phrased as a judgement" {
    local work="${TMP}/repo2"
    mkdir -p "${work}/commands/v-method" "${work}/checks"
    cp "${SC3}" "${work}/checks/"
    sed 's/| The bottleneck sits in one step |/| The task is complex |/' "${REF}" > "${work}/commands/v-method/routing.md"
    run "${work}/checks/$(basename "${SC3}")"
    [ "$status" -eq 1 ]
    [[ "$output" == *"judgement"* ]]
}

@test "SC-3 goes red when the heuristic admission is removed" {
    local work="${TMP}/repo3"
    mkdir -p "${work}/commands/v-method" "${work}/checks"
    cp "${SC3}" "${work}/checks/"
    sed 's/heuristic/approach/g; s/No validated instrument/An instrument/' "${REF}" > "${work}/commands/v-method/routing.md"
    run "${work}/checks/$(basename "${SC3}")"
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------- SC-4 and SC-5, planted

@test "SC-4 goes red on a prohibition-heavy file" {
    local work="${TMP}/repo4"
    mkdir -p "${work}/commands/v-method" "${work}/checks"
    cp "${SC4}" "${work}/checks/"
    cp "${REF}" "${work}/commands/v-method/routing.md"
    # The counter counts LINES, not occurrences, so the plant needs one prohibition per line and
    # enough of them to outnumber the shipped file's requirements.
    {
        cat "${CMD}"
        printf '\n'
        for i in $(seq 1 20); do printf 'Rule %s: never do the thing.\n' "$i"; done
    } > "${work}/commands/v-method.md"
    run "${work}/checks/$(basename "${SC4}")"
    [ "$status" -eq 1 ]
    [[ "$output" == *"prohibitions against"* ]]
}

@test "SC-5 goes red on a restated shared-module rule" {
    local work="${TMP}/repo5"
    mkdir -p "${work}/commands/v-method" "${work}/lib" "${work}/checks"
    cp "${SC5}" "${work}/checks/"
    cp "${VAULT_ROOT}/lib/shared-module-rules.tsv" "${work}/lib/"
    cp "${REF}" "${work}/commands/v-method/routing.md"
    {
        cat "${CMD}"
        printf '\nEvery agent writes its artifacts to disk before reporting them.\n'
    } > "${work}/commands/v-method.md"
    run "${work}/checks/$(basename "${SC5}")"
    [ "$status" -eq 1 ]
    [[ "$output" == *"RESTATED"* ]]
}

@test "SC-5 reads the shared pattern list, not a copy of its own" {
    # The list moved out of checks/v-loop-SC-3.sh so two checks could share it. If a check ever
    # inlines it again, this fails and the duplication is visible.
    run grep -q 'lib/shared-module-rules.tsv' "${SC5}"
    [ "$status" -eq 0 ]
    run grep -q 'lib/shared-module-rules.tsv' "${VAULT_ROOT}/checks/v-loop-SC-3.sh"
    [ "$status" -eq 0 ]
    run grep -qE "^owned=\\\$\(cat <<" "${VAULT_ROOT}/checks/v-loop-SC-3.sh"
    [ "$status" -ne 0 ]
}
