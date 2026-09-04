#!/usr/bin/env bats
# Behaviour tests for scripts/completion-hook.sh — the one hook in this framework that blocks.
#
# Four of these are load-bearing:
#
#   * it must exit 2 on an unproven completion claim. Any other nonzero lets the turn end, which
#     makes the hook advisory — the thing it exists not to be.
#   * it must exit 0 when stop_hook_active is true. Without that a session which cannot satisfy the
#     gate can never stop, and the hook becomes a trap the operator has to kill.
#   * it must exit 0 when nothing was marked DONE. A hook that fires on a question or a discussion
#     is a false positive, and a check firing wrongly above one time in ten gets switched off.
#   * it must make no model call. The whole point is a process that reads state independently.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    HOOK="${VAULT_ROOT}/scripts/completion-hook.sh"
    TMP="$(mktemp -d)"
    mkdir -p "${TMP}/vault/plans"
    printf 'vault_path: ./vault\n' > "${TMP}/VAULT.md"
    unset COMPLETION COMPLETION_HOOK_RUN
}

teardown() {
    [ -n "${TMP:-}" ] && rm -rf "${TMP}"
}

# write_plan <work-item-status> [verdict] [evidence]
write_plan() {
    local status=$1 verdict=${2:-} evidence=${3:-}
    cat > "${TMP}/vault/plans/p.md" <<PLAN
---
type: plan
status: approved
---

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN it runs THE SYSTEM SHALL work | delivery | command | \`true\` | exit 0 | ${verdict} | ${evidence} |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-01 | \`x.sh\` | create | Write | none | SC-1 | none | ${status} |
PLAN
}

fire() {
    local active=${1:-false}
    printf '{"stop_hook_active":%s,"cwd":"%s"}' "${active}" "${TMP}" | "${HOOK}"
}

@test "blocks with exit 2 when work is DONE and the criterion has no verdict" {
    write_plan DONE
    run fire false
    [ "$status" -eq 2 ]
    [[ "$output" == *"marked work done and recorded no verdict"* ]]
    [[ "$output" == *"SC-1"* ]]
}

@test "names the plan path so the block is actionable" {
    write_plan DONE
    run fire false
    [[ "$output" == *"vault/plans/p.md"* ]]
}

@test "does not block a second time on the same stop" {
    write_plan DONE
    run fire true
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "does not block when no work item is DONE" {
    write_plan TODO
    run fire false
    [ "$status" -eq 0 ]
}

@test "does not block when the verdict is recorded with evidence" {
    write_plan DONE MET '`true` exited 0'
    run fire false
    [ "$status" -eq 0 ]
}

@test "does not block a repo with no plans directory" {
    rm -rf "${TMP}/vault"
    run fire false
    [ "$status" -eq 0 ]
}

@test "does not block when no plan is approved" {
    write_plan DONE
    sed -i 's/^status: approved/status: proposed/' "${TMP}/vault/plans/p.md"
    run fire false
    [ "$status" -eq 0 ]
}

@test "COMPLETION=off disables the block" {
    write_plan DONE
    COMPLETION=off run fire false
    [ "$status" -eq 0 ]
}

@test "a plan the gate cannot parse is reported without blocking" {
    cat > "${TMP}/vault/plans/p.md" <<'BROKEN'
---
type: plan
status: approved
---

## Success criteria

| id | criterion | kind |
|----|-----------|------|
| SC-1 | it works | delivery |
BROKEN
    run fire false
    [ "$status" -eq 0 ]
    [[ "$output" == *"could not read"* ]]
}

@test "makes no model call — it invokes only the gate" {
    grep -qvE 'curl|anthropic|api\.|claude -p' "${HOOK}"
    run grep -cE '(^|[^a-z])(curl|wget)( |$)' "${HOOK}"
    [ "$output" = "0" ]
}

@test "resolves an absolute vault_path" {
    write_plan DONE
    mkdir -p "${TMP}/elsewhere/plans"
    mv "${TMP}/vault/plans/p.md" "${TMP}/elsewhere/plans/p.md"
    printf 'vault_path: %s\n' "${TMP}/elsewhere" > "${TMP}/VAULT.md"
    run fire false
    [ "$status" -eq 2 ]
}

@test "an in-repo vault with no VAULT.md still resolves to ./vault" {
    write_plan DONE
    rm -f "${TMP}/VAULT.md"
    run fire false
    [ "$status" -eq 2 ]
}
