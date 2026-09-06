#!/usr/bin/env bash
# PreToolUse hook: refuse a git staging command that sweeps files the session did not name.
#
# `git add -A`, `git add .` and `git add --all` stage whatever is in the tree — a credential someone
# dropped, a generated file, or another session's work in progress. This session committed another
# session's file twice in one afternoon that way, four hours after writing the rule against it. The
# rule was prose, and prose is what failed.
#
# `git commit -a`, `git commit -am` and a pathspec-less `git commit` reach the same outcome through a
# different verb: every tracked edit in the tree, whoever made it, lands in a commit this session did
# not write. `git commit --amend` and `git reset --hard` go further and destroy work already
# committed. An unattended campaign agent runs all of these.
#
# A PreToolUse hook denies before the permission check and holds even when permission prompting is
# off, which is the only layer that blocks rather than reminds.
#
# What passes: `git add <path> [<path>...]` and `git commit <path> [<path>...]`, naming each file,
# plus `git reset` in any mode that keeps the working tree. That is the whole rule.
#
# Off: GATE=off

set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
COMMON="$(dirname "$SELF")/../lib/hook-common.sh"
[ -r "$COMMON" ] || exit 0
# shellcheck source=../lib/hook-common.sh
. "$COMMON"

hook_off GATE && exit 0

payload="$(cat)"
tool="$(hook_json_field "$payload" '.tool_name // empty')"
[ "$tool" = "Bash" ] || exit 0

cmd="$(hook_json_field "$payload" '.tool_input.command // empty')"
[ -n "$cmd" ] || exit 0

# Match a git add carrying -A, --all, or a bare dot. `git add -- ./file` names a file and passes.
if printf '%s' "$cmd" | grep -qE '(^|[;&|]|\s)git\s+add\s+([^;&|]*\s)?(-A|--all|-[A-Za-z]*A[A-Za-z]*)(\s|$)' \
   || printf '%s' "$cmd" | grep -qE '(^|[;&|]|\s)git\s+add\s+\.(\s|$)'; then
    {
        printf 'Refused: this stages files you did not name.\n\n'
        printf '  %s\n\n' "$cmd"
        printf 'A directory-wide add sweeps in whatever is in the tree — a credential, a generated\n'
        printf 'file, or another session working in the same repo right now. Name each file:\n\n'
        printf '  git add path/one path/two\n\n'
        printf 'Run `git status --short` first if you need the list.\n'
    } >&2
    exit 2
fi

# --- git commit / git reset ---------------------------------------------------------------------
# Walk each simple command separately so a compound line is judged on the segment that matters.
refuse() {
    {
        printf 'Refused: this commits files you did not name.\n\n'
        printf '  %s\n\n' "$cmd"
        printf '%s\n\n' "$1"
        printf 'Name each file:\n\n'
        printf '  git commit path/one path/two -m "message"\n\n'
        printf 'Run `git status --short` first if you need the list.\n'
    } >&2
    exit 2
}

# has_pathspec <tokens after `commit`> — true when a non-flag argument survives.
has_pathspec() {
    local want_value=0 after_sep=0 t
    for t in "$@"; do
        if [ "$after_sep" -eq 1 ]; then return 0; fi
        if [ "$want_value" -eq 1 ]; then want_value=0; continue; fi
        case "$t" in
            --) after_sep=1 ;;
            -m|--message|-F|--file|-c|-C|--reuse-message|--reedit-message|--author|--date|-S|--gpg-sign)
                want_value=1 ;;
            -*) ;;
            *) return 0 ;;
        esac
    done
    return 1
}

while IFS= read -r seg || [ -n "$seg" ]; do
    # A segment that does not start with `git` is not ours, and `set --` on a leading dash would
    # read it as options rather than arguments.
    case "$seg" in git\ *) ;; *) continue ;; esac
    # shellcheck disable=SC2086
    set -- $seg

    if [ "${2:-}" = "commit" ]; then
        shift 2
        for t in "$@"; do
            # A short bundle is `-am`; `--author` is a long option and carries no staging effect,
            # so long options are matched by name and never by the letters inside them.
            case "$t" in
                --amend)
                    refuse 'Amending rewrites a commit someone else may already hold. Make a new commit instead.' ;;
                --all)
                    refuse 'The --all flag stages every tracked change in the tree, including edits another session is making right now.' ;;
                --*) ;;
                -*a*)
                    refuse 'The -a flag stages every tracked change in the tree, including edits another session is making right now.' ;;
            esac
        done
        has_pathspec "$@" ||             refuse 'A commit with no pathspec takes whatever is already staged, which may be another session'"'"'s work.'
    fi

    if [ "${2:-}" = "reset" ]; then
        for t in "$@"; do
            [ "$t" = "--hard" ] || continue
            {
                printf 'Refused: this destroys uncommitted work.\n\n'
                printf '  %s\n\n' "$cmd"
                printf 'A hard reset discards every uncommitted change in the tree, including work\n'
                printf 'another session has not saved. Use `git reset --soft` or `git restore <path>`.\n'
            } >&2
            exit 2
        done
    fi
done < <(printf '%s\n' "$cmd" | tr ';&|' '\n\n\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

exit 0
