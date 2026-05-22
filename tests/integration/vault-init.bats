#!/usr/bin/env bats
# Tests for bin/vault-init.sh — project vault bootstrapper.

load "../helpers/setup.bash"

# Helper: create an isolated code repo at $1 and cd into it via subshell.
make_code_repo() {
    local dir="$1"
    mkdir -p "${dir}"
    git -C "${dir}" init --quiet --initial-branch=main 2>/dev/null \
        || git -C "${dir}" init --quiet
    git -C "${dir}" config user.email "test@local"
    git -C "${dir}" config user.name  "test"
    echo "hello" > "${dir}/README.md"
    git -C "${dir}" add README.md
    git -C "${dir}" commit --quiet -m "init"
}

setup() {
    make_test_home
    export VAULT_HOME="${TEST_HOME}/vault"
    # /code is mounted read-only; use it as the framework URL via file:// allowance.
    export VAULT_FRAMEWORK_URL="/code"
    export VAULT_INIT_GIT_FLAGS="-c protocol.file.allow=always"
    export CODE_REPO="${TEST_HOME}/work/myproject"
    make_code_repo "${CODE_REPO}"
}

teardown() {
    cleanup_test_home
}

@test "--help exits 0 and prints usage" {
    run "${VAULT_ROOT}/bin/vault-init.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"vault-init"* ]]
}

@test "fails when run outside a git repo" {
    cd "${TEST_HOME}"
    run "${VAULT_ROOT}/bin/vault-init.sh" --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"not a git repo"* ]]
}

@test "creates vault dir using basename of code repo as slug" {
    cd "${CODE_REPO}"
    run "${VAULT_ROOT}/bin/vault-init.sh" --yes
    [ "$status" -eq 0 ]
    [ -d "${VAULT_HOME}/myproject" ]
    [ -d "${VAULT_HOME}/myproject/.git" ]
}

@test "scaffolds the expected folder layout" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    for sub in sessions decisions features processes architecture; do
        [ -d "${VAULT_HOME}/myproject/${sub}" ]
    done
    [ -f "${VAULT_HOME}/myproject/_moc.md" ]
    [ -f "${VAULT_HOME}/myproject/_feature-index.md" ]
    [ -f "${VAULT_HOME}/myproject/decisions/_inventory.md" ]
    [ -f "${VAULT_HOME}/myproject/.gitignore" ]
}

@test "_moc.md substitutes the slug into the template" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    grep -q "myproject — Map of Contents" "${VAULT_HOME}/myproject/_moc.md"
    grep -q "_process/vault-guide" "${VAULT_HOME}/myproject/_moc.md"
}

@test "attaches framework as _process submodule" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    [ -f "${VAULT_HOME}/myproject/.gitmodules" ]
    grep -q "_process" "${VAULT_HOME}/myproject/.gitmodules"
    [ -d "${VAULT_HOME}/myproject/_process" ]
    [ -f "${VAULT_HOME}/myproject/_process/vault-guide.md" ]
}

@test "--no-submodule skips submodule entirely" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --no-submodule --yes >/dev/null
    [ ! -f "${VAULT_HOME}/myproject/.gitmodules" ]
    [ ! -d "${VAULT_HOME}/myproject/_process" ]
}

@test "--slug overrides the derived name" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --slug renamed --yes >/dev/null
    [ -d "${VAULT_HOME}/renamed" ]
    [ ! -d "${VAULT_HOME}/myproject" ]
}

@test "refuses to overwrite an existing vault dir" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    run "${VAULT_ROOT}/bin/vault-init.sh" --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
}

@test "appends entry to coupled-groups.md (idempotent on slug)" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    grep -qE "^- myproject$" "${VAULT_HOME}/_global/coupled-groups.md"
}

@test "appends Vault memory stack snippet to code repo CLAUDE.md" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    [ -f "${CODE_REPO}/CLAUDE.md" ]
    grep -q "Vault memory stack" "${CODE_REPO}/CLAUDE.md"
    grep -q "${VAULT_HOME}/myproject" "${CODE_REPO}/CLAUDE.md"
}

@test "--no-claude-md leaves code repo CLAUDE.md untouched" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --no-claude-md --yes >/dev/null
    [ ! -f "${CODE_REPO}/CLAUDE.md" ]
}

@test "preserves existing CLAUDE.md content; does not duplicate snippet" {
    echo "PRE-EXISTING CONTENT" > "${CODE_REPO}/CLAUDE.md"
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    grep -q "PRE-EXISTING CONTENT" "${CODE_REPO}/CLAUDE.md"
    grep -q "Vault memory stack" "${CODE_REPO}/CLAUDE.md"
    # Snippet appears exactly once.
    count="$(grep -c "Vault memory stack" "${CODE_REPO}/CLAUDE.md")"
    [ "${count}" -eq 1 ]
}

@test "makes an initial commit in the vault repo" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    log="$(git -C "${VAULT_HOME}/myproject" log --oneline)"
    [[ "${log}" == *"initialize project vault for myproject"* ]]
}
