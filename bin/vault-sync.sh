#!/usr/bin/env bash
# vault-sync.sh — keep an out-of-repo project vault in sync with its git remote.
#
# A project vault that lives outside the code repo (the global ~/vault/<slug>/ layout) is not
# covered by the code repo's commits. Without this, knowledge written by /v-capture is committed
# only when someone remembers and pushed only by hand. The lifecycle calls this script instead of
# hand-rolling git: see commands/_shared/vault-sync.md for when each subcommand fires.
#
# Usage:
#   vault-sync.sh pull <vault-dir> [--dry-run]
#   vault-sync.sh push <vault-dir> [--dry-run] [-m <subject>] [path...]
#
# `push` stages only the paths given (default: the vault dir itself) — never `git add -A` and never
# `git add .` from a parent, so a dirty parent tree is not swept into a vault commit. Paths are
# resolved against the vault dir and must live inside its git worktree.
#
# Exit codes — every one of them is non-fatal to the caller. A vault that cannot sync must never
# halt a lifecycle or block a capture:
#   0  synced (or nothing to do)
#   1  a git operation failed (conflict, rejected push, network). The worktree is left clean:
#      a conflicting rebase is aborted and the autostash restored before returning.
#   2  usage error
#   3  the vault dir is not inside a git worktree — caller notes it once; `git init` is NEVER run
#      here, that is the user's call
#   4  the vault dir is inside the code repo's own worktree (an in-repo `vault_path: ./vault`), so
#      the code commit already covers it — caller skips silently
#   5  a git repo with no upstream branch. `pull` has nothing to pull; `push` still commits locally
#      and reports that the commit did not leave the machine. Nothing is pushed to a remote this
#      script had to guess at, and no remote branch is created.
#
# Environment:
#   VAULT_SYNC_CODE_REPO   worktree to compare against for exit 4    default: $PWD
#   VAULT_SETUP_DRY_RUN=1  print every git command, change nothing   (same seam as setup.sh)

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VAULT_SETUP_DRY_RUN="${VAULT_SETUP_DRY_RUN:-0}"

# shellcheck source=../lib/installers.sh
. "${VAULT_ROOT}/lib/installers.sh"

readonly EXIT_OK=0
readonly EXIT_GIT_FAILED=1
readonly EXIT_USAGE=2
readonly EXIT_NOT_A_REPO=3
readonly EXIT_IN_REPO=4
readonly EXIT_NO_UPSTREAM=5

usage() {
    cat <<'EOF'
vault-sync.sh — keep an out-of-repo project vault in sync with its git remote.

  vault-sync.sh pull <vault-dir> [--dry-run]
  vault-sync.sh push <vault-dir> [--dry-run] [-m <subject>] [path...]

pull   rebase the vault onto its upstream, stashing local edits first
push   stage the given paths (default: the vault dir), commit, push to upstream

  -m <subject>  commit subject, prefixed with "docs(vault): "  (default: "sync session notes")
  --dry-run     print every git command, change nothing
  -h, --help    this text

Exit: 0 synced · 1 git failed · 2 usage · 3 not a git repo · 4 vault is in-repo · 5 no upstream.
No exit code is fatal to the caller — a vault that cannot sync never halts a lifecycle.
EOF
}

#------------------------------------------------------------------------------
# Preflight — shared by both subcommands
#------------------------------------------------------------------------------

# Echoes the vault's git toplevel. Returns EXIT_NOT_A_REPO / EXIT_IN_REPO instead of printing.
vault_toplevel() {
    local dir="$1" top code_top

    [ -d "$dir" ] || return "$EXIT_NOT_A_REPO"
    top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || return "$EXIT_NOT_A_REPO"

    code_top="$(git -C "${VAULT_SYNC_CODE_REPO:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$code_top" ] && [ "$top" = "$code_top" ]; then
        return "$EXIT_IN_REPO"
    fi

    printf '%s\n' "$top"
}

# A vault caught mid-rebase or mid-merge is not ours to finish.
assert_no_operation_in_progress() {
    local top="$1" git_dir
    # --absolute-git-dir so this also holds for a linked worktree, whose git dir is not $top/.git.
    git_dir="$(git -C "$top" rev-parse --absolute-git-dir)"
    if [ -d "${git_dir}/rebase-merge" ] || [ -d "${git_dir}/rebase-apply" ] \
        || [ -f "${git_dir}/MERGE_HEAD" ]; then
        warn "vault at ${top} has a rebase or merge in progress — resolve it by hand, skipping sync"
        return 1
    fi
    return 0
}

has_upstream() {
    git -C "$1" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1
}

# Restore the worktree after a failed rebase so the vault is never left mid-operation.
abort_rebase() {
    local top="$1"
    git -C "$top" rebase --abort >/dev/null 2>&1 || true
}

#------------------------------------------------------------------------------
# pull
#------------------------------------------------------------------------------

cmd_pull() {
    local dir="$1" top rc=0

    top="$(vault_toplevel "$dir")" || return $?
    assert_no_operation_in_progress "$top" || return "$EXIT_GIT_FAILED"

    if ! has_upstream "$top"; then
        info "vault at ${top} has no upstream branch — nothing to pull"
        return "$EXIT_NO_UPSTREAM"
    fi

    run git -C "$top" pull --rebase --autostash || rc=$?
    if [ "$rc" -ne 0 ]; then
        abort_rebase "$top"
        warn "could not rebase the vault at ${top} onto its upstream — continuing without it"
        return "$EXIT_GIT_FAILED"
    fi

    ok "vault at ${top} is up to date with its upstream"
    return "$EXIT_OK"
}

#------------------------------------------------------------------------------
# push
#------------------------------------------------------------------------------

cmd_push() {
    local dir="$1" subject="$2"; shift 2
    local top rc=0 staged=1
    local -a paths=("$@")

    top="$(vault_toplevel "$dir")" || return $?
    assert_no_operation_in_progress "$top" || return "$EXIT_GIT_FAILED"

    # Default to the vault dir as an explicit absolute path. Never `.` and never `-A`: an explicit
    # pathspec keeps a dirty parent (or an unrelated sibling vault) out of this commit, and gitignore
    # still excludes the local-only mounts (memory/, graphify/, serena/).
    if [ "${#paths[@]}" -eq 0 ]; then
        paths=("$(cd "$dir" && pwd -P)")
    fi

    run git -C "$top" add -- "${paths[@]}" || {
        warn "could not stage ${#paths[@]} path(s) in the vault at ${top}"
        return "$EXIT_GIT_FAILED"
    }

    # Under dry-run nothing was actually staged, so the emptiness check would always short-circuit.
    if ! _dry && git -C "$top" diff --cached --quiet; then
        staged=0
    fi

    if [ "$staged" -eq 1 ]; then
        run git -C "$top" commit -m "docs(vault): ${subject}" || {
            warn "could not commit the vault at ${top}"
            return "$EXIT_GIT_FAILED"
        }
    fi

    if ! has_upstream "$top"; then
        if [ "$staged" -eq 1 ]; then
            info "committed locally — vault at ${top} has no upstream, nothing was pushed"
        fi
        return "$EXIT_NO_UPSTREAM"
    fi

    # Nothing new and nothing ahead of upstream: no push to make.
    if [ "$staged" -eq 0 ] && ! _dry \
        && [ -z "$(git -C "$top" rev-list '@{u}..HEAD' 2>/dev/null)" ]; then
        return "$EXIT_OK"
    fi

    run git -C "$top" push || rc=$?
    if [ "$rc" -ne 0 ]; then
        warn "could not push the vault at ${top} — the commit is safe locally, push it by hand"
        return "$EXIT_GIT_FAILED"
    fi

    ok "vault at ${top} pushed to its upstream"
    return "$EXIT_OK"
}

#------------------------------------------------------------------------------
# Argument parsing
#------------------------------------------------------------------------------

main() {
    local subcmd="" dir="" subject="sync session notes"
    local -a paths=()

    while [ $# -gt 0 ]; do
        case "$1" in
            pull|push)   subcmd="$1"; shift ;;
            -m)          subject="$2"; shift 2 ;;
            --dry-run)   VAULT_SETUP_DRY_RUN=1; shift ;;
            -h|--help)   usage; return "$EXIT_OK" ;;
            -*)          warn "unknown flag: $1"; usage >&2; return "$EXIT_USAGE" ;;
            *)
                if [ -z "$dir" ]; then dir="$1"; else paths+=("$1"); fi
                shift ;;
        esac
    done

    if [ -z "$subcmd" ] || [ -z "$dir" ]; then
        usage >&2
        return "$EXIT_USAGE"
    fi

    case "$subcmd" in
        pull) cmd_pull "$dir" ;;
        push) cmd_push "$dir" "$subject" "${paths[@]+"${paths[@]}"}" ;;
    esac
}

main "$@"
