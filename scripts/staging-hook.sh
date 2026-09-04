#!/usr/bin/env bash
# PreToolUse hook: refuse a git staging command that sweeps files the session did not name.
#
# `git add -A`, `git add .` and `git add --all` stage whatever is in the tree — a credential someone
# dropped, a generated file, or another session's work in progress. This session committed another
# session's file twice in one afternoon that way, four hours after writing the rule against it. The
# rule was prose, and prose is what failed.
#
# A PreToolUse hook denies before the permission check and holds even when permission prompting is
# off, which is the only layer that blocks rather than reminds.
#
# What passes: `git add <path> [<path>...]`, naming each file. That is the whole rule.
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
exit 0
