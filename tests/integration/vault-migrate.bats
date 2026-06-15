#!/usr/bin/env bats
# Tests for bin/vault-migrate.sh — de-submodule an existing project vault.

load "../helpers/setup.bash"

FLAGS="-c protocol.file.allow=always"

# Create a code repo at $1.
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

# Create a legacy vault at $1 with the framework attached as a _process/ submodule.
make_submodule_vault() {
    local vault="$1"
    mkdir -p "${vault}"
    # shellcheck disable=SC2086
    git ${FLAGS} -C "${vault}" init --quiet --initial-branch=main 2>/dev/null \
        || git ${FLAGS} -C "${vault}" init --quiet
    git -C "${vault}" config user.email "test@local"
    git -C "${vault}" config user.name  "test"
    # shellcheck disable=SC2086
    git ${FLAGS} -C "${vault}" submodule add --quiet /code _process
    mkdir -p "${vault}/sessions"
    cat > "${vault}/_moc.md" <<EOF
# myproject — Map of Contents

## Start Here
- [[_process/vault-guide]] — process documentation (framework submodule)
EOF
    # shellcheck disable=SC2086
    git ${FLAGS} -C "${vault}" add -A
    # shellcheck disable=SC2086
    git ${FLAGS} -C "${vault}" commit --quiet -m "init with submodule"
}

setup() {
    make_test_home
    export VAULT_HOME="${TEST_HOME}/vault"
    export VAULT_FRAMEWORK_PATH="/code"
    export VAULT_INIT_GIT_FLAGS="${FLAGS}"
    export CODE_REPO="${TEST_HOME}/work/myproject"
    make_code_repo "${CODE_REPO}"
    make_submodule_vault "${VAULT_HOME}/myproject"
}

teardown() {
    cleanup_test_home
}

@test "--help exits 0 and prints usage" {
    run "${VAULT_ROOT}/bin/vault-migrate.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"vault-migrate"* ]]
}

@test "fixture really has a _process submodule" {
    [ -f "${VAULT_HOME}/myproject/.gitmodules" ]
    [ -e "${VAULT_HOME}/myproject/_process" ]
}

@test "removes the _process submodule" {
    cd "${CODE_REPO}"
    run "${VAULT_ROOT}/bin/vault-migrate.sh" --yes
    [ "$status" -eq 0 ]
    [ ! -e "${VAULT_HOME}/myproject/_process" ]
    [ ! -f "${VAULT_HOME}/myproject/.gitmodules" ]
    [ ! -d "${VAULT_HOME}/myproject/.git/modules/_process" ]
}

@test "repoints the MOC pointer at the global framework" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-migrate.sh" --yes >/dev/null
    grep -q "vault-guide.md" "${VAULT_HOME}/myproject/_moc.md"
    ! grep -q "_process/vault-guide" "${VAULT_HOME}/myproject/_moc.md"
}

@test "writes VAULT.md to the code repo" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-migrate.sh" --yes >/dev/null
    [ -f "${CODE_REPO}/VAULT.md" ]
    grep -q "slug: myproject" "${CODE_REPO}/VAULT.md"
    grep -qE "^vault_path: .*vault/myproject" "${CODE_REPO}/VAULT.md"
}

@test "commits the migration in the vault repo" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-migrate.sh" --yes >/dev/null
    log="$(git -C "${VAULT_HOME}/myproject" log --oneline)"
    [[ "${log}" == *"de-submodule"* ]]
}

@test "is idempotent — second run is a clean no-op" {
    cd "${CODE_REPO}"
    "${VAULT_ROOT}/bin/vault-migrate.sh" --yes >/dev/null
    run "${VAULT_ROOT}/bin/vault-migrate.sh" --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"already"* ]]
}

@test "operates on an explicit --vault path" {
    cd "${TEST_HOME}"
    run "${VAULT_ROOT}/bin/vault-migrate.sh" --vault "${VAULT_HOME}/myproject" --slug myproject --yes
    [ "$status" -eq 0 ]
    [ ! -e "${VAULT_HOME}/myproject/_process" ]
}

@test "errors when the vault dir is not a git repo" {
    run "${VAULT_ROOT}/bin/vault-migrate.sh" --vault "${TEST_HOME}/nope" --slug nope --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"not a git repo"* ]]
}
