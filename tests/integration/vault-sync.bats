#!/usr/bin/env bats
# Tests for bin/vault-sync.sh — git sync for an out-of-repo project vault.
#
# Real git against real repos, all inside $TEST_HOME with a local bare remote. No network.
# The exit codes are the contract every v-* command branches on (commands/_shared/vault-sync.md),
# so each one gets a test — and so does the promise that a failure leaves the worktree clean.

load "../helpers/setup.bash"

SYNC() { "${VAULT_ROOT}/bin/vault-sync.sh" "$@"; }

git_init() {
    local dir="$1"
    mkdir -p "${dir}"
    git -C "${dir}" init --quiet --initial-branch=main 2>/dev/null \
        || git -C "${dir}" init --quiet
    git -C "${dir}" config user.email "test@local"
    git -C "${dir}" config user.name  "test"
}

# A vault repo wired to a bare remote, with one commit on both sides.
make_vault_with_remote() {
    local vault="$1" remote="$2"
    git init --quiet --bare "${remote}"
    git_init "${vault}"
    echo "seed" > "${vault}/seed.md"
    git -C "${vault}" add seed.md
    git -C "${vault}" commit --quiet -m "init"
    git -C "${vault}" remote add origin "${remote}"
    git -C "${vault}" push --quiet -u origin HEAD
}

# A second clone of the same remote, to create divergence from "somewhere else".
make_peer() {
    local peer="$1" remote="$2"
    git_init "${peer}"
    git -C "${peer}" remote add origin "${remote}"
    git -C "${peer}" fetch --quiet origin
    git -C "${peer}" checkout --quiet -B main origin/HEAD 2>/dev/null \
        || git -C "${peer}" checkout --quiet -B main origin/main
    git -C "${peer}" branch --quiet --set-upstream-to=origin/main main 2>/dev/null || true
}

setup() {
    make_test_home
    export GIT_AUTHOR_NAME="test"      GIT_AUTHOR_EMAIL="test@local"
    export GIT_COMMITTER_NAME="test"   GIT_COMMITTER_EMAIL="test@local"

    VAULT="${TEST_HOME}/vault/myproject"
    REMOTE="${TEST_HOME}/remotes/myproject.git"
    PEER="${TEST_HOME}/peer"
    # The code repo the vault is compared against for the "vault is in-repo" case.
    CODE_REPO="${TEST_HOME}/work/myproject"
    git_init "${CODE_REPO}"
    echo "code" > "${CODE_REPO}/README.md"
    git -C "${CODE_REPO}" add README.md
    git -C "${CODE_REPO}" commit --quiet -m "init"
    export VAULT_SYNC_CODE_REPO="${CODE_REPO}"
}

teardown() {
    cleanup_test_home
}

# --- usage -------------------------------------------------------------------------------

@test "--help exits 0 and prints usage" {
    run SYNC --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"vault-sync.sh"* ]]
}

@test "a missing subcommand is a usage error" {
    run SYNC "${TEST_HOME}"
    [ "$status" -eq 2 ]
}

# --- pull --------------------------------------------------------------------------------

@test "pull fast-forwards a clean vault when the remote is ahead" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    make_peer "${PEER}" "${REMOTE}"
    echo "from elsewhere" > "${PEER}/peer.md"
    git -C "${PEER}" add peer.md
    git -C "${PEER}" commit --quiet -m "peer"
    git -C "${PEER}" push --quiet origin HEAD:main

    run SYNC pull "${VAULT}"
    [ "$status" -eq 0 ]
    [ -f "${VAULT}/peer.md" ]
}

@test "pull rebases local edits over an advanced remote without losing them" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    make_peer "${PEER}" "${REMOTE}"
    echo "from elsewhere" > "${PEER}/peer.md"
    git -C "${PEER}" add peer.md
    git -C "${PEER}" commit --quiet -m "peer"
    git -C "${PEER}" push --quiet origin HEAD:main

    echo "local work" > "${VAULT}/local.md"
    git -C "${VAULT}" add local.md
    git -C "${VAULT}" commit --quiet -m "local"

    run SYNC pull "${VAULT}"
    [ "$status" -eq 0 ]
    [ -f "${VAULT}/peer.md" ]
    [ -f "${VAULT}/local.md" ]
}

@test "a conflicting pull exits 1 and leaves no rebase in progress" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    make_peer "${PEER}" "${REMOTE}"
    echo "THEIRS" > "${PEER}/seed.md"
    git -C "${PEER}" commit --quiet -am "theirs"
    git -C "${PEER}" push --quiet origin HEAD:main

    echo "OURS" > "${VAULT}/seed.md"
    git -C "${VAULT}" commit --quiet -am "ours"

    run SYNC pull "${VAULT}"
    [ "$status" -eq 1 ]

    # The worktree must be usable afterwards: our commit intact, nothing half-applied.
    git_dir="$(git -C "${VAULT}" rev-parse --absolute-git-dir)"
    [ ! -d "${git_dir}/rebase-merge" ]
    [ ! -d "${git_dir}/rebase-apply" ]
    [ "$(cat "${VAULT}/seed.md")" = "OURS" ]
    run git -C "${VAULT}" status --porcelain
    [ -z "$output" ]
}

@test "pull on a repo with no upstream exits 5 and changes nothing" {
    git_init "${VAULT}"
    echo "seed" > "${VAULT}/seed.md"
    git -C "${VAULT}" add seed.md
    git -C "${VAULT}" commit --quiet -m "init"
    before="$(git -C "${VAULT}" rev-parse HEAD)"

    run SYNC pull "${VAULT}"
    [ "$status" -eq 5 ]
    [ "$(git -C "${VAULT}" rev-parse HEAD)" = "${before}" ]
}

# --- push --------------------------------------------------------------------------------

@test "push commits the given paths and advances the remote" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    mkdir -p "${VAULT}/sessions"
    echo "notes" > "${VAULT}/sessions/today.md"

    run SYNC push "${VAULT}" -m "capture today" "${VAULT}/sessions/today.md"
    [ "$status" -eq 0 ]

    run git -C "${VAULT}" log --oneline -1
    [[ "$output" == *"docs(vault): capture today"* ]]

    # The remote must actually hold that commit — a local-only commit is exit 5, not exit 0.
    # The bare repo's own HEAD is unborn, so name the branch rather than relying on it.
    branch="$(git -C "${VAULT}" rev-parse --abbrev-ref HEAD)"
    [ "$(git -C "${REMOTE}" rev-parse "${branch}")" = "$(git -C "${VAULT}" rev-parse HEAD)" ]
}

@test "push with nothing to stage makes no empty commit" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    before="$(git -C "${VAULT}" rev-parse HEAD)"

    run SYNC push "${VAULT}"
    [ "$status" -eq 0 ]
    [ "$(git -C "${VAULT}" rev-parse HEAD)" = "${before}" ]
}

@test "push defaults to the vault dir when no paths are given" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    echo "notes" > "${VAULT}/new.md"

    run SYNC push "${VAULT}" -m "sweep"
    [ "$status" -eq 0 ]
    run git -C "${VAULT}" show --name-only --format= HEAD
    [[ "$output" == *"new.md"* ]]
}

@test "push on a repo with no remote exits 5 but the commit exists locally" {
    git_init "${VAULT}"
    echo "seed" > "${VAULT}/seed.md"
    git -C "${VAULT}" add seed.md
    git -C "${VAULT}" commit --quiet -m "init"
    echo "notes" > "${VAULT}/new.md"

    run SYNC push "${VAULT}" -m "offline"
    [ "$status" -eq 5 ]

    run git -C "${VAULT}" log --oneline -1
    [[ "$output" == *"docs(vault): offline"* ]]
}

@test "push never stages gitignored local-only mounts" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    printf 'memory/\ngraphify/\n' > "${VAULT}/.gitignore"
    mkdir -p "${VAULT}/memory" "${VAULT}/graphify"
    echo "local only" > "${VAULT}/memory/parent.md"
    echo "local only" > "${VAULT}/graphify/graph.json"
    echo "real" > "${VAULT}/keep.md"

    run SYNC push "${VAULT}" -m "sweep"
    [ "$status" -eq 0 ]

    run git -C "${VAULT}" show --name-only --format= HEAD
    [[ "$output" == *"keep.md"* ]]
    [[ "$output" != *"memory/parent.md"* ]]
    [[ "$output" != *"graphify/graph.json"* ]]
}

@test "push does not sweep in a dirty parent directory" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    # A sibling vault under the same parent must not be dragged into this commit.
    mkdir -p "${TEST_HOME}/vault/othervault"
    echo "not mine" > "${TEST_HOME}/vault/othervault/stray.md"
    echo "mine" > "${VAULT}/mine.md"

    run SYNC push "${VAULT}" -m "sweep"
    [ "$status" -eq 0 ]
    run git -C "${VAULT}" show --name-only --format= HEAD
    [[ "$output" == *"mine.md"* ]]
    [[ "$output" != *"stray.md"* ]]
}

# --- repo classification -----------------------------------------------------------------

@test "a vault dir that is not a git repo exits 3 and is not git-initialised" {
    mkdir -p "${VAULT}"
    run SYNC pull "${VAULT}"
    [ "$status" -eq 3 ]
    [ ! -d "${VAULT}/.git" ]

    run SYNC push "${VAULT}"
    [ "$status" -eq 3 ]
    [ ! -d "${VAULT}/.git" ]
}

@test "a missing vault dir exits 3" {
    run SYNC pull "${TEST_HOME}/nope"
    [ "$status" -eq 3 ]
}

@test "an in-repo vault exits 4 and stages nothing" {
    mkdir -p "${CODE_REPO}/vault"
    echo "in repo" > "${CODE_REPO}/vault/notes.md"

    run SYNC push "${CODE_REPO}/vault" -m "should not happen"
    [ "$status" -eq 4 ]

    run git -C "${CODE_REPO}" diff --cached --name-only
    [ -z "$output" ]
    run git -C "${CODE_REPO}" log --oneline -1
    [[ "$output" != *"should not happen"* ]]
}

# --- dry run -----------------------------------------------------------------------------

@test "--dry-run prints the git commands and changes nothing" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    before="$(git -C "${VAULT}" rev-parse HEAD)"
    echo "notes" > "${VAULT}/new.md"

    run SYNC push "${VAULT}" --dry-run -m "nope"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"commit"* ]]
    [[ "$output" == *"push"* ]]

    [ "$(git -C "${VAULT}" rev-parse HEAD)" = "${before}" ]
    run git -C "${VAULT}" status --porcelain
    [[ "$output" == *"new.md"* ]]
}

@test "--dry-run pull leaves the vault untouched" {
    make_vault_with_remote "${VAULT}" "${REMOTE}"
    make_peer "${PEER}" "${REMOTE}"
    echo "from elsewhere" > "${PEER}/peer.md"
    git -C "${PEER}" add peer.md
    git -C "${PEER}" commit --quiet -m "peer"
    git -C "${PEER}" push --quiet origin HEAD:main

    run SYNC pull "${VAULT}" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [ ! -f "${VAULT}/peer.md" ]
}
