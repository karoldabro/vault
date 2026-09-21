#!/usr/bin/env bats
# Behaviour and text guards for the sandbox probe stage. Contract: commands/v-cr/sandbox.md section S8.
#
# The graders under checks/sandbox-probe-SC-*.sh build fixture repos and decide each criterion; a case here
# runs one and prints its message when it fails. Run in the container: `./tests/run.sh tests/unit/sandbox-probe.bats`.

load "../helpers/setup.bash"

setup() { export VAULT_ROOT="${VAULT_ROOT:-/code}"; }

@test "T-6 probe.sh reads --changed-list without git and honours PROBE_TOOLS_FROM=image" {
    run "${VAULT_ROOT}/checks/sandbox-probe-SC-1.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-3 the driver builds the envelope, the mounts and the four files" {
    run "${VAULT_ROOT}/checks/sandbox-probe-SC-2.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-4 no forged row, hand-written row or container failure runs anything on the host" {
    run "${VAULT_ROOT}/checks/sandbox-probe-SC-3.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-5 posture sandbox tags rows from the files and reads missing status as INCOMPLETE" {
    run "${VAULT_ROOT}/checks/sandbox-probe-SC-4.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-9 the real docker delivery grader is skipped with a message when docker is unusable" {
    if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
        skip "docker is not usable inside this container; run checks/sandbox-probe-SC-5.sh on the host"
    fi
    run "${VAULT_ROOT}/checks/sandbox-probe-SC-5.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "T-7 the sandbox posture never calls probe.sh, and the driver runs it only inside a container" {
    # the panel branch for the sandbox posture is the call to sandbox_rows; the host call sits in the else branch
    awk '/if \[ "\$posture" = sandbox \]; then sandbox_rows/{f=1} f && /^    else$/{exit} f && /probe\.sh/{bad=1} END{exit bad}' "${VAULT_ROOT}/bin/probe-panel.sh"
    # every mention of probe.sh in the driver is a comment or the container command
    run grep -n 'probe\.sh' "${VAULT_ROOT}/bin/probe-sandbox.sh"
    ! printf '%s\n' "$output" | grep -v '^[0-9]*:#' | grep -v '/framework/bin/probe.sh' | grep -q .
}

@test "T-8 the no-fallback sentence has one home and the probe image is not set by any indication template" {
    [ "$(grep -rl 'never falls back to the host' "${VAULT_ROOT}/commands" "${VAULT_ROOT}/vault/decisions" | wc -l)" -eq 1 ]
    ! grep -rq 'probe-image' "${VAULT_ROOT}/templates"
}

# --- regressions found in review ---------------------------------------------------------------------------------

drive() { # drive <extra env assignments...> — runs the driver on the fixture repo with the fake docker
    local tmp=$1; shift
    . "${VAULT_ROOT}/tests/fixtures/sandbox-probe/mk-repo.sh"
    sp_mk_repo "$tmp/r" "$tmp/marker"
    mkdir -p "$tmp/bin"; cp "${VAULT_ROOT}/tests/fixtures/sandbox-probe/fake-docker.sh" "$tmp/bin/docker"
    export VCR_SANDBOX_ROOT=$tmp/sb VCR_SANDBOX_MAP="probe-image=fake-probes:1" FAKE_DOCKER_LOG=$tmp/log PATH="$tmp/bin:$PATH"
}

@test "T-12 every status line of a container reaches framework.status on its own line" {
    local tmp; tmp=$(mktemp -d); drive "$tmp"
    FAKE_DOCKER_MODE=lines run "${VAULT_ROOT}/bin/probe-sandbox.sh" run --repo "$tmp/r" --base "$SP_BASE" --sandbox-name vcr-t-1 --out "$tmp/out"
    [ "$status" -eq 0 ]
    [ "$(grep -c '^failed: dead-files: boom$' "$tmp/out/framework.status")" -eq 1 ]
    [ "$(grep -c '^absent: token-size: none$' "$tmp/out/framework.status")" -eq 1 ]
    rm -rf "$tmp"
}

@test "T-13 a tracked file named like an option cannot hide the size of the tree" {
    local tmp; tmp=$(mktemp -d); drive "$tmp"
    head -c 3000 /dev/zero > "$tmp/r/-rf"; head -c 3000 /dev/zero > "$tmp/r/--help"
    git -C "$tmp/r" add -A -- . ; git -C "$tmp/r" -c user.name=t -c user.email=t@t commit -qm big
    FAKE_DOCKER_MODE=exec PROBE_SANDBOX_BYTES_MAX=1000 run "${VAULT_ROOT}/bin/probe-sandbox.sh" run --repo "$tmp/r" --base "$SP_BASE" --sandbox-name vcr-t-1 --out "$tmp/out"
    [ "$status" -eq 3 ]
    [[ "$output" == *"bytes, over the limit"* ]]
    rm -rf "$tmp"
}

@test "T-14 the last row of a base registry without a trailing newline still runs, and a rule named all keeps the framework-id guard" {
    local tmp; tmp=$(mktemp -d); drive "$tmp"
    git -C "$tmp/r" checkout -q "$SP_BASE"
    { "${VAULT_ROOT}/bin/rule-check.sh" row --slug all --stack any; printf '%s' "$("${VAULT_ROOT}/bin/rule-check.sh" row --slug md-links --stack any)"; } >> "$tmp/r/probes/registry.tsv"
    printf 'glob: *.php\npattern: TODO\nseverity: warn\nmessage: all\n' > "$tmp/r/probes/rules/all.grep"
    git -C "$tmp/r" add -A; git -C "$tmp/r" -c user.name=t -c user.email=t@t commit -qm more; local b; b=$(git -C "$tmp/r" rev-parse HEAD)
    git -C "$tmp/r" checkout -q main
    FAKE_DOCKER_MODE=exec run "${VAULT_ROOT}/bin/probe-sandbox.sh" run --repo "$tmp/r" --base "$b" --sandbox-name vcr-t-1 --out "$tmp/out"
    [ "$status" -eq 0 ]
    grep -q '^skipped: md-links: the id also names a framework probe$' "$tmp/out/rules.status"
    rm -rf "$tmp"
}
