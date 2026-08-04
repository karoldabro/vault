#!/usr/bin/env bats
# Contracts for the vault git-sync wiring (commands/_shared/vault-sync.md).
#
# These are FILE CONTRACTS, in the same spirit as communication-contract.bats: they prove the
# instructions are present and mutually consistent. They do NOT prove the model calls the script at
# runtime. The behaviour of the script itself is proven in tests/integration/vault-sync.bats.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    CONTRACT="${VAULT_ROOT}/commands/_shared/vault-sync.md"
    SCRIPT="${VAULT_ROOT}/bin/vault-sync.sh"
}

flat() { tr '\n' ' ' < "$1"; }

# --- the contract ------------------------------------------------------------------------

@test "the vault-sync contract exists and documents every exit code" {
    [ -f "${CONTRACT}" ]
    for code in "| 0 |" "| 1 |" "| 3 |" "| 4 |" "| 5 |"; do
        grep -qF "${code}" "${CONTRACT}" || { echo "missing exit code row: ${code}"; return 1; }
    done
}

@test "the contract states that a sync failure never halts the lifecycle" {
    run bash -c "flat() { tr '\n' ' ' < \"\$1\"; }; flat '${CONTRACT}'"
    [[ "$output" == *"never halts the lifecycle"* ]]
    [[ "$output" == *"never blocks a capture"* ]]
}

@test "the contract forbids git init on the user's behalf" {
    run bash -c "tr '\n' ' ' < '${CONTRACT}'"
    [[ "$output" == *"Never \`git init\` a vault"* ]]
}

@test "the contract excludes /v-ask, which promises no git write" {
    run bash -c "tr '\n' ' ' < '${CONTRACT}'"
    [[ "$output" == *"/v-ask"* ]]
    [[ "$output" == *"excluded"* ]]
}

@test "v-ask still declares itself read-only and never calls the sync script" {
    run grep -c "vault-sync.sh" "${VAULT_ROOT}/commands/v-ask.md"
    [ "$output" -eq 0 ]
    run bash -c "tr '\n' ' ' < '${VAULT_ROOT}/commands/v-ask.md'"
    [[ "$output" == *"No file in any repo or vault changes"* ]]
}

# --- wiring ------------------------------------------------------------------------------

@test "every command that reads or writes a vault calls the sync script" {
    for f in \
        "commands/v-work/steps/02-load-context.md" \
        "commands/v-work/steps/05-commit-capture.md" \
        "commands/v-capture.md" \
        "commands/v-do.md" \
        "commands/v-pm/steps/02-load-context.md" \
        "commands/v-pm/steps/05-capture.md"
    do
        grep -q "bin/vault-sync.sh" "${VAULT_ROOT}/${f}" \
            || { echo "no vault-sync.sh call in ${f}"; return 1; }
    done
}

@test "every wired command points at the shared contract" {
    for f in \
        "commands/v-work/steps/02-load-context.md" \
        "commands/v-work/steps/05-commit-capture.md" \
        "commands/v-capture.md" \
        "commands/v-do.md" \
        "commands/v-pm/steps/02-load-context.md" \
        "commands/v-pm/steps/05-capture.md"
    do
        grep -q "_shared/vault-sync.md" "${VAULT_ROOT}/${f}" \
            || { echo "no contract reference in ${f}"; return 1; }
    done
}

@test "the commit step no longer hand-rolls git for the vault" {
    STEP="${VAULT_ROOT}/commands/v-work/steps/05-commit-capture.md"
    # §5.1 still commits the CODE repo by hand; the vault section must not.
    run bash -c "sed -n '/## 5.2/,/## 5.3/p' '${STEP}' | grep -c '^git '"
    [ "$output" -eq 0 ]
}

@test "the autosync toggle is documented in the template and the guide" {
    grep -q "vault_autosync" "${VAULT_ROOT}/templates/VAULT.md"
    grep -q "vault_autosync" "${VAULT_ROOT}/vault-guide.md"
    grep -q "vault_autosync" "${CONTRACT}"
}

# --- the script's own safety rules --------------------------------------------------------

@test "the script is executable and syntactically valid" {
    [ -x "${SCRIPT}" ]
    run bash -n "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "the script never uses a blanket git add" {
    # Comments explain WHY these are banned, so only real command lines are checked.
    run bash -c "grep -v '^[[:space:]]*#' '${SCRIPT}' | grep -E 'git .*add (-A|--all|\\.([[:space:]]|\$))'"
    [ "$status" -ne 0 ]
}

@test "the script never runs git init" {
    run bash -c "grep -v '^[[:space:]]*#' '${SCRIPT}' | grep -E 'git .*init'"
    [ "$status" -ne 0 ]
}

@test "the script routes mutating git through the dry-run seam" {
    for cmd in "pull --rebase" "commit -m" "push"; do
        grep -qE "run git -C .* ${cmd}" "${SCRIPT}" \
            || { echo "not routed through run(): ${cmd}"; return 1; }
    done
}
