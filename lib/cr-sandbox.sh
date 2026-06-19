#!/usr/bin/env bash
# lib/cr-sandbox.sh — PURE helpers for /v-cr's optional --sandbox (isolated execution) path.
#
# No network, no docker, no git invocation, no filesystem side effects: source it and call the
# functions. The I/O-bound parts of the sandbox path (free-port allocation, recipe-file discovery,
# the actual clone/build/run/teardown) live in commands/v-cr/sandbox.md and are exercised by the
# opt-in e2e suite — NOT here. This file is the offline-unit-tested core (tests/unit/cr-sandbox.bats),
# kept pure for the same reason lib/forge-detect.sh + lib/cr-helpers.sh are (arch-5).
#
# Written to behave identically under bash and zsh (no reliance on IFS word-splitting). Functions are
# `set -u`-safe: an unset/empty critical input fails closed rather than degrading to a dangerous default.
#
# Public functions:
#   cr_sandbox_root                                  -> the root dir all sandboxes live under
#   cr_sandbox_name <host> <owner> <repo> <pr> <sha> <nonce>
#                                                    -> deterministic slug (dir name + docker GC label)
#   cr_sandbox_path_is_safe <path>                   -> rc 0 ONLY for a well-formed path under the root
#                                                       (the data-loss guard before any rm / worktree rm)
#   cr_is_envelope_key <key>                         -> rc 0 if <key> is an ISOLATION-envelope key that
#                                                       must NEVER come from a repo/indication (sec-2)
#   cr_recipe_resolve <indication> <vault> <repo> <stackdefault>
#                                                    -> prints "<source>\t<value>" of the winning recipe
#                                                       source by precedence (project indication first)
#   cr_stack_default_recipe <stack>                  -> prints "image\tinstall\ttest\tlint" for a stack
#   cr_redact_runtime                                -> stdin -> stdout, secret-shapes + CR_REDACT_VALUES
#                                                       scrubbed (runtime output is untrusted; sec-1)
#
# SECURITY CARVE-OUT (sec-2): the isolation envelope (network/caps/cpus/memory/pids/mounts/volumes/
# privileged/env passthrough/proxy/registry) is framework-owned and sourced ONLY from per-stack defaults
# + user/global config (VCR_SANDBOX_MAP). cr_is_envelope_key is the predicate callers use to strip those
# keys out of any repo- or indication-supplied recipe before merging it.

# The root directory every sandbox (clone + container + volumes) is created under. Default lives in the
# temp tree so it is obviously throwaway; override with the user/global env VCR_SANDBOX_ROOT.
cr_sandbox_root() {
    printf '%s\n' "${VCR_SANDBOX_ROOT:-${TMPDIR:-/tmp}/v-cr-sandbox}"
}

# Lowercase + collapse anything outside [a-z0-9] to a single '-', trim leading/trailing '-'.
# Internal helper (prefixed _cr_) — keeps the public slug deterministic and shell-safe.
_cr_slug() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# Deterministic sandbox name from PR identity + a run nonce. Same inputs -> same name (so a re-run can
# find/clean its own objects), but the nonce lets concurrent runs over the same PR coexist (skeptic-4).
# Used both as the clone directory leaf name and as the docker label `com.vault.v-cr.sandbox=<name>`
# that --sandbox-gc reaps by. The sha is truncated to 8 chars; the nonce is caller-supplied (e.g. $$).
cr_sandbox_name() {
    local host="${1:-}" owner="${2:-}" repo="${3:-}" pr="${4:-}" sha="${5:-}" nonce="${6:-}"
    local sha8
    sha8="$(printf '%s' "$sha" | cut -c1-8)"
    printf 'vcr-%s-%s-%s-pr%s-%s-%s\n' \
        "$(_cr_slug "$host")" "$(_cr_slug "$owner")" "$(_cr_slug "$repo")" \
        "$(_cr_slug "$pr")" "$(_cr_slug "$sha8")" "$(_cr_slug "$nonce")"
}

# THE data-loss guard. Returns 0 ONLY when <path> is a well-formed sandbox path that is safe to
# `rm -rf` / `git worktree remove`. Called immediately before every destructive op in the teardown
# trap, not just at provision time (sec-7) — so a crash with half-set variables cannot widen the blast
# radius. Fails closed on: empty/unset, '.', '/', the bare root, $HOME, anything not strictly *under*
# the sandbox root, anything containing '..', and anything whose leaf doesn't carry the 'vcr-' prefix.
cr_sandbox_path_is_safe() {
    local path="${1:-}" root rel
    root="$(cr_sandbox_root)"

    [ -n "$path" ]            || return 1   # empty / unset
    case "$path" in
        */../*|*/..|../*|*/.) return 1 ;;   # traversal or trailing dot
        *//*) return 1 ;;                   # ambiguous double-separator (corr-d3)
        .|/) return 1 ;;                    # cwd / filesystem root
    esac
    [ "$path" != "$root" ]    || return 1   # never the root itself, only children
    [ "$path" != "${HOME:-/nonexistent}" ] || return 1
    case "$path" in
        "$root"/*) ;;                       # MUST be under the sandbox root
        *) return 1 ;;
    esac
    rel="${path#"$root"/}"                  # the portion below the root
    case "$rel" in
        */*) return 1 ;;                    # MUST be a DIRECT child, not nested (corr-d1):
                                            #   /root/real/vcr-fake must NOT pass on its leaf alone
        vcr-*) ;;                           # the single child component must be a cr_sandbox_name slug
        *) return 1 ;;
    esac
    return 0
}

# Isolation-envelope predicate (sec-2). Returns 0 when <key> controls the security boundary and must
# therefore be ignored if it appears in a repo file or a project indication — only per-stack defaults
# and user/global VCR_SANDBOX_MAP may set these. Returns 1 for benign recipe keys (install/test/lint/
# ports/build) that a project IS allowed to declare.
cr_is_envelope_key() {
    case "${1:-}" in
        network|network_mode|networks|dns|extra_hosts|links \
        |cap_add|cap_drop|capabilities|privileged|security_opt|devices|sysctls \
        |cpus|cpu_*|memory|mem_*|pids|pids_limit|ulimits|shm_size \
        |volumes|mounts|mount|bind|tmpfs|volumes_from \
        |env|environment|env_passthrough|proxy|http_proxy|https_proxy|registry|registries|user|userns_mode)
            return 0 ;;
        *)
            return 1 ;;
    esac
}

# Recipe source precedence (the "logic given inputs" half of recipe resolution — file discovery itself
# is I/O and lives in sandbox.md). Each argument is the resolved recipe VALUE for one source, or empty
# if that source is absent. Prints "<source>\t<value>" for the highest-precedence present source:
#   1 indication   (reviewed-repo vault indications/ — the project's own sandbox recipe; user's ask)
#   2 vault        (reviewed-repo VAULT.md behaviour.sandbox)
#   3 repo         (repo docker-compose.yml / Dockerfile — built INSIDE the framework wrapper)
#   4 stack-default(per-stack framework fallback)
# rc 1 if every source is empty (caller then refuses --sandbox or reports "cannot provision").
cr_recipe_resolve() {
    local indication="${1:-}" vault="${2:-}" repo="${3:-}" stackdefault="${4:-}"
    if   [ -n "$indication" ];   then printf 'indication\t%s\n'    "$indication"
    elif [ -n "$vault" ];        then printf 'vault\t%s\n'         "$vault"
    elif [ -n "$repo" ];         then printf 'repo\t%s\n'          "$repo"
    elif [ -n "$stackdefault" ]; then printf 'stack-default\t%s\n' "$stackdefault"
    else return 1
    fi
}

# Per-stack default recipe — the framework fallback when a repo declares nothing. Prints
# "image<TAB>install<TAB>test<TAB>lint". Deliberately conservative (install + test only); the isolation
# envelope is applied by sandbox.md, not here. Unknown stack -> rc 1 (caller reports "no recipe").
cr_stack_default_recipe() {
    case "${1:-}" in
        node|npm|typescript|ts)
            printf 'node:lts-slim\tnpm ci --ignore-scripts\tnpm test\tnpx --no-install eslint .\n' ;;
        pnpm)
            printf 'node:lts-slim\tpnpm install --frozen-lockfile --ignore-scripts\tpnpm test\tpnpm lint\n' ;;
        php|laravel)
            printf 'php:8.3-cli\tcomposer install --no-scripts --no-interaction\tvendor/bin/phpunit\tvendor/bin/phpstan analyse\n' ;;
        python|py)
            printf 'python:3.12-slim\tpip install .\tpytest\truff check .\n' ;;
        go|golang)
            printf 'golang:1-bookworm\tgo mod download\tgo test ./...\tgo vet ./...\n' ;;
        *)
            return 1 ;;
    esac
}

# Scrub untrusted runtime output (test/build/lint stdout+stderr) before it enters ANY model context,
# finding, comment, or captured session (sec-1). stdin -> stdout. Redacts:
#   (a) literal secret values the caller knows (CR_REDACT_VALUES, newline-separated) — e.g. any host env
#       the caller is aware of; matched as fixed strings so regex metacharacters are harmless;
#   (b) common secret token SHAPES (the same set 02-gather scans the diff for).
# This is a SECRET scrubber, not a prompt-injection scrub — runtime output must additionally be fenced
# as untrusted DATA by the caller (per the _shared/critic-panel untrusted-input contract).
#
# CONTRACT (corr-d2): this is a TEXT scrubber. `$(cat)` collapses trailing newlines and is not NUL/binary
# safe — fine for test/build/lint logs (its only intended input), out of contract for binary streams.
# The output is normalised to a single trailing newline; callers needing byte-fidelity must not use this.
cr_redact_runtime() {
    local content val rest nl
    content="$(cat)"

    if [ -n "${CR_REDACT_VALUES:-}" ]; then
        # A literal newline. NOTE: $(printf '\n') is WRONG here — command substitution strips the
        # trailing newline, yielding an empty string that makes the case pattern match everything and
        # spins forever. The trailing-sentinel trick preserves the newline; works in bash and zsh.
        nl="$(printf '\nX')"; nl="${nl%X}"
        rest="$CR_REDACT_VALUES"
        while [ -n "$rest" ]; do
            case "$rest" in
                *"$nl"*) val="${rest%%"$nl"*}"; rest="${rest#*"$nl"}" ;;
                *)       val="$rest"; rest="" ;;
            esac
            [ -n "$val" ] && content="${content//"$val"/[REDACTED]}"
        done
    fi

    printf '%s\n' "$content" | sed -E \
        -e 's/gh[pousr]_[A-Za-z0-9]{20,}/[REDACTED]/g' \
        -e 's/glpat-[A-Za-z0-9_-]{18,}/[REDACTED]/g' \
        -e 's/(Bearer )[A-Za-z0-9._~+\/-]+=*/\1[REDACTED]/g' \
        -e 's/ATATT[A-Za-z0-9._=-]{20,}/[REDACTED]/g' \
        -e 's/xox[abpr]-[A-Za-z0-9-]{10,}/[REDACTED]/g' \
        -e 's/AKIA[0-9A-Z]{16}/[REDACTED]/g'
}
