#!/usr/bin/env bats
# Behaviour and text guards for bin/probe-panel.sh. Rules: commands/_shared/critic-panel.md §(a).
#
# The graders under checks/probe-panel-SC-*.sh build fixture repos and decide each criterion; a case here
# runs one and prints its message when it fails. Run in the container: `./tests/run.sh tests/unit/probe-panel.bats`.

load "../helpers/setup.bash"

setup() { export VAULT_ROOT="${VAULT_ROOT:-/code}"; PANEL="${VAULT_ROOT}/bin/probe-panel.sh"; TMP="$(mktemp -d)"; }
teardown() { rm -rf "${TMP}"; }

@test "T-1 T-2 posture pr and own run no repo registry row by default, and run needs a base" {
    run "${VAULT_ROOT}/checks/probe-panel-SC-1.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-3 an absent, skipped or failed probe reads INCOMPLETE with the rows found and an operator line" {
    run "${VAULT_ROOT}/checks/probe-panel-SC-2.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-4 framework rows are confirmed, repo rows advisory, and cited says which" {
    run "${VAULT_ROOT}/checks/probe-panel-SC-3.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-5 T-6 the block is capped and no row can close its fence" {
    run "${VAULT_ROOT}/checks/probe-panel-SC-4.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-7 --paths keeps only the rows whose file is listed" {
    git init -q "${TMP}/r" && git -C "${TMP}/r" config user.email t@t && git -C "${TMP}/r" config user.name t
    printf '# ok\n' > "${TMP}/r/a.md"; git -C "${TMP}/r" add -A; git -C "${TMP}/r" commit -qm base
    base=$(git -C "${TMP}/r" rev-parse HEAD)
    printf '[x](gone.md)\n' > "${TMP}/r/b.md"; printf '[y](gone.md)\n' > "${TMP}/r/c.md"
    printf 'b.md\n' > "${TMP}/paths"
    run "${PANEL}" run --posture own --repo "${TMP}/r" --base "${base}" --paths "${TMP}/paths" --out "${TMP}/o"
    [[ "$output" == *"b.md"* ]]
    [[ "$output" != *"c.md"* ]]
}

@test "T-8 the v-work execute step runs the helper with posture own and refers to the panel module" {
    local f="${VAULT_ROOT}/commands/v-work/steps/04-execute.md"
    grep -q 'probe-panel.sh' "${f}"
    grep -q -- '--posture own' "${f}"
    grep -q 'critic-panel.md' "${f}"
    grep -q 'PROBE_BASE' "${f}"
}

@test "T-9 usage errors exit 2: no posture, an unknown posture, an out path that is a file, a bad cited id" {
    run "${PANEL}" run --repo "${TMP}" --base HEAD
    [ "$status" -eq 2 ]
    run "${PANEL}" run --posture sideways --repo "${TMP}" --base HEAD
    [ "$status" -eq 2 ]
    : > "${TMP}/file"
    run "${PANEL}" run --posture pr --repo "${TMP}" --base HEAD --out "${TMP}/file"
    [ "$status" -eq 2 ]
    run "${PANEL}" cited "${TMP}" 'BAD ID' a.md 1
    [ "$status" -eq 2 ]
    run "${PANEL}" cited "${TMP}/missing" md-links a.md 1
    [ "$status" -eq 2 ]
}

@test "the panel module owns the probe rules once and the commands refer to it" {
    grep -q 'Probe stage' "${VAULT_ROOT}/commands/_shared/critic-panel.md"
    run "${VAULT_ROOT}/checks/probe-panel-SC-6.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}
