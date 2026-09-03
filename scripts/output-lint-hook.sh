#!/usr/bin/env bash
# Stop hook: measure the reply that just finished and store the numbers for the next turn.
#
# It never exits 2. Exit 2 on a Stop hook blocks the stop and continues the conversation, so the
# model appends more text to a reply that was already too long — the cure would produce the disease.
# Correction happens at the next turn instead, through scripts/brevity-reminder-hook.sh.
#
# Writes two files, both under ~/.claude:
#   brevity-state.<session_id>.json   the previous reply's numbers, read once at the next turn
#   brevity-log.jsonl                 one line per turn, read by the 2026-09-10 review
#
# The state file carries the session id because several Claude Code sessions run at once on one
# machine; a shared filename would make the reminder quote a reply from a different window.
#
# Measures: bin/output-lint.sh          Off: BREVITY=off

set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
COMMON="$(dirname "$SELF")/../lib/hook-common.sh"
[ -r "$COMMON" ] || exit 0
# shellcheck source=../lib/hook-common.sh
. "$COMMON"

hook_off BREVITY && exit 0

VAULT_ROOT="$(hook_vault_root "${BASH_SOURCE[0]}")"
LINT="${VAULT_ROOT}/bin/output-lint.sh"
[ -x "$LINT" ] || exit 0

payload="$(cat)"
reply="$(hook_json_field "$payload" '.last_assistant_message // empty')"
session="$(hook_json_field "$payload" '.session_id // empty')"

[ -z "$reply" ] && exit 0

# One definition of the path, shared with the hook that reads it back.
state="$(hook_state_path "$session")" || exit 0

measured="$(printf '%s' "$reply" | "$LINT" 2>/dev/null)" || exit 0
[ -z "$measured" ] && exit 0

dir="${HOME}/.claude"
mkdir -p "$dir" 2>/dev/null || exit 0

printf '%s\n' "$measured" > "$state" 2>/dev/null || true

stamped="$(printf '%s' "$measured" \
    | jq -c --arg t "$(date -Iseconds)" --arg s "$session" '. + {at:$t, session:$s}' 2>/dev/null)" || true
printf '%s\n' "${stamped:-$measured}" >> "${dir}/brevity-log.jsonl" 2>/dev/null || true

exit 0
