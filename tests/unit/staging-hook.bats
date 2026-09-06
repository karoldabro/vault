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

# `git add` was one verb of the action this hook names. `git commit -am` reaches the same outcome —
# a sibling agent's tracked edits swept into a commit the session did not write — and returned clean
# until these cases were added. `--amend` and `reset --hard` destroy work already committed.

@test "refuses git commit -a" { run fire 'git commit -a -m x'; [ "$status" -eq 2 ]; }
@test "refuses git commit -am" { run fire 'git commit -am "x"'; [ "$status" -eq 2 ]; }
@test "refuses git commit with no pathspec" { run fire 'git commit -m "x"'; [ "$status" -eq 2 ]; }
@test "refuses git commit --amend" { run fire 'git commit --amend --no-edit'; [ "$status" -eq 2 ]; }
@test "refuses git reset --hard" { run fire 'git reset --hard origin/main'; [ "$status" -eq 2 ]; }

@test "refuses a commit sweep inside a compound command" {
    run fire 'cd /repo && git commit -am wip && git push'
    [ "$status" -eq 2 ]
}

@test "allows a commit that names its paths" {
    run fire 'git commit bin/gate.sh tests/unit/gate.bats -m "fix"'
    [ "$status" -eq 0 ]
}

@test "allows a commit that names paths after the separator" {
    run fire 'git commit -m "fix" -- bin/gate.sh'
    [ "$status" -eq 0 ]
}

@test "allows a soft or mixed reset" {
    run fire 'git reset --soft HEAD~1'
    [ "$status" -eq 0 ]
    run fire 'git reset HEAD bin/gate.sh'
    [ "$status" -eq 0 ]
}

@test "the commit refusal names what to do instead" {
    run fire 'git commit -am x'
    [[ "$output" == *"git commit path/one path/two"* ]]
}

@test "GATE=off disables the commit refusal too" {
    GATE=off run fire 'git commit -am x'
    [ "$status" -eq 0 ]
}
