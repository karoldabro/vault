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
    # The framework is read globally; /code is the mounted framework install.
    export VAULT_FRAMEWORK_PATH="/code"
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
    for sub in sessions decisions features indications processes architecture; do
        [ -d "${VAULT_HOME}/myproject/${sub}" ]
    done
    [ -f "${VAULT_HOME}/myproject/_moc.md" ]
    [ -f "${VAULT_HOME}/myproject/_feature-index.md" ]
    [ -f "${VAULT_HOME}/myproject/decisions/_inventory.md" ]
    [ -f "${VAULT_HOME}/myproject/indications/_index.md" ]
    [ -f "${VAULT_HOME}/myproject/.gitignore" ]
}

@test "_moc.md substitutes the slug and points at the global framework guide" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    grep -q "myproject — Map of Contents" "${VAULT_HOME}/myproject/_moc.md"
    grep -q "vault-guide.md" "${VAULT_HOME}/myproject/_moc.md"
    # The framework is global now — no submodule pointer.
    ! grep -q "_process/vault-guide" "${VAULT_HOME}/myproject/_moc.md"
}

@test "does NOT create a _process submodule" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    [ ! -f "${VAULT_HOME}/myproject/.gitmodules" ]
    [ ! -e "${VAULT_HOME}/myproject/_process" ]
}

@test "writes VAULT.md to the code repo with slug and global vault_path" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --yes >/dev/null
    [ -f "${CODE_REPO}/VAULT.md" ]
    grep -q "slug: myproject" "${CODE_REPO}/VAULT.md"
    grep -qE "^vault_path: .*vault/myproject" "${CODE_REPO}/VAULT.md"
}

@test "--no-vault-md skips writing VAULT.md" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --no-vault-md --yes >/dev/null
    [ ! -f "${CODE_REPO}/VAULT.md" ]
}

@test "--in-repo keeps the vault inside the code repo, not a nested git repo" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-init.sh" --in-repo --yes >/dev/null
    [ -d "${CODE_REPO}/vault/sessions" ]
    [ -d "${CODE_REPO}/vault/indications" ]
    # In-repo vault is tracked by the code repo — no nested .git.
    [ ! -e "${CODE_REPO}/vault/.git" ]
    # No global vault dir was created.
    [ ! -d "${VAULT_HOME}/myproject" ]
    grep -q "vault_path: ./vault" "${CODE_REPO}/VAULT.md"
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
