#!/usr/bin/env bats
# Behaviour tests for scripts/staging-hook.sh.
#
# This one exists because its prose form failed in the session that wrote it: `never git add -A` was
# in the framework, and a session used `git add -A bin/` twice in one afternoon and committed another
# session's file. The first case below is that exact command.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    HOOK="${VAULT_ROOT}/scripts/staging-hook.sh"
    unset GATE
}

fire() { printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" | "${HOOK}"; }

@test "refuses the scoped form that actually caused the defect" {
    run fire 'git add -A bin/'
    [ "$status" -eq 2 ]
    [[ "$output" == *"stages files you did not name"* ]]
}

@test "refuses git add -A" { run fire 'git add -A'; [ "$status" -eq 2 ]; }
@test "refuses git add ." { run fire 'git add .'; [ "$status" -eq 2 ]; }
@test "refuses git add --all" { run fire 'git add --all'; [ "$status" -eq 2 ]; }

@test "refuses it inside a compound command" {
    run fire 'cd /repo && git add -A vault/ && git commit -m x'
    [ "$status" -eq 2 ]
}

@test "allows named files" {
    run fire 'git add bin/gate.sh tests/unit/gate.bats'
    [ "$status" -eq 0 ]
}

@test "allows a file named after the -- separator" {
    run fire 'git add -- ./one/file.md'
    [ "$status" -eq 0 ]
}

@test "ignores commands that are not git add" {
    run fire 'git status --short'
    [ "$status" -eq 0 ]
    run fire 'ls -A'
    [ "$status" -eq 0 ]
}

@test "ignores tools other than Bash" {
    run bash -c 'printf %s "{\"tool_name\":\"Write\",\"tool_input\":{\"command\":\"git add -A\"}}" | "'"${HOOK}"'"'
    [ "$status" -eq 0 ]
}

@test "GATE=off disables the refusal" {
    GATE=off run fire 'git add -A'
    [ "$status" -eq 0 ]
}

@test "the refusal names what to do instead" {
    run fire 'git add -A'
    [[ "$output" == *"git add path/one path/two"* ]]
    [[ "$output" == *"git status --short"* ]]
}
