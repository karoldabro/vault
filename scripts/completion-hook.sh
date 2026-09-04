#!/usr/bin/env bash
# Stop hook: refuse to let a session end while it has marked work done and not recorded a verdict.
#
# This is the one hook in the framework that blocks. Every other one exits 0 by contract
# (lib/hook-common.sh) because a hook that interrupts a turn is worse than the problem it solves.
# The exception is earned by a measurement: across 1,879 trajectories, 75.8% of failures in
# self-assessing coding agents were reported as success, and no LLM judge configuration detected it
# above 0.65 AUROC. What did work, by an order of magnitude, was an independent process that reads
# the state. This is that process. It makes no model call.
#
# WHAT IT BLOCKS ON, and nothing else: a work item marked DONE whose covering success criterion has
# no verdict. That is the exact shape of "I finished it" with no evidence. A turn that marked
# nothing done never blocks, so a question, a read or a discussion is untouched.
#
# The check is bin/gate.sh verdict, which reads only the plan. Set COMPLETION_HOOK_RUN=1 to use
# --run instead, which executes each committed check script; that is slower and belongs on a close,
# not on every turn.
#
# Blocks by exiting 2. Claude Code returns stderr to the model as its next instruction, so the
# refusal names the criterion and the session continues rather than stopping.
#
# Loop safety: stop_hook_active is true when this hook already blocked the current stop. Honouring
# it is what keeps a session that cannot satisfy the gate from blocking forever.
#
# Off: COMPLETION=off

set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
COMMON="$(dirname "$SELF")/../lib/hook-common.sh"
[ -r "$COMMON" ] || exit 0
# shellcheck source=../lib/hook-common.sh
. "$COMMON"

hook_off COMPLETION && exit 0

VAULT_ROOT="$(hook_vault_root "${BASH_SOURCE[0]}")"
GATE="${VAULT_ROOT}/bin/gate.sh"
[ -x "$GATE" ] || exit 0

payload="$(cat)"

# Already blocked once on this stop. Blocking again is how a hook becomes a trap.
[ "$(hook_json_field "$payload" '.stop_hook_active // false')" = "true" ] && exit 0

cwd="$(hook_json_field "$payload" '.cwd // empty')"
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"

# Resolve the project vault the way vault-guide.md §1.1 does, minus the global fallback: a hook that
# reaches outside the working repo would block a session against a plan from another project.
vault=""
if [ -r "${cwd}/VAULT.md" ]; then
    declared="$(sed -n 's/^vault_path:[[:space:]]*//p' "${cwd}/VAULT.md" | head -1 | tr -d '\r')"
    case "$declared" in
        "")   : ;;
        /*)   vault="$declared" ;;
        "~"*) vault="${HOME}${declared#\~}" ;;
        *)    vault="${cwd}/${declared#./}" ;;
    esac
fi
[ -n "$vault" ] || vault="${cwd}/vault"
[ -d "${vault}/plans" ] || exit 0

# The session's plan is the most recently touched approved one. A session with no approved plan has
# nothing to be held to, and exits 0.
plan="$(grep -l '^status: approved' "${vault}"/plans/*.md 2>/dev/null \
        | xargs -r ls -t 2>/dev/null | head -1)"
[ -n "$plan" ] && [ -r "$plan" ] || exit 0

mode="verdict"
args=("$plan")
[ "${COMPLETION_HOOK_RUN:-0}" = "1" ] && args+=(--run)

out="$("$GATE" "$mode" "${args[@]}" 2>&1)"
rc=$?

[ "$rc" -eq 0 ] && exit 0

# Exit 2 is the only value that blocks a stop. Any other nonzero is reported to the user and lets
# the turn end, which would make this hook advisory — the thing it exists not to be.
if [ "$rc" -eq 1 ]; then
    {
        printf 'This session marked work done and recorded no verdict for it.\n\n'
        printf '%s\n\n' "$out"
        printf 'Fill each criterion above: run its check, put the command and its output in the\n'
        printf 'evidence cell, then set the verdict. Plan: %s\n' "$plan"
    } >&2
    exit 2
fi

# rc 2 means the gate could not parse the plan. That is a defect in the plan, not a completion
# claim, and it is reported without blocking so a session can go and fix the table.
printf 'completion-hook: gate could not read %s\n%s\n' "$plan" "$out" >&2
exit 0
