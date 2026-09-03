#!/usr/bin/env bash
# UserPromptSubmit hook: tell the model what its previous reply broke, and otherwise say nothing.
#
# Silence is the normal case. Text here means a limit was exceeded — the same
# report-exceptions-not-normality rule commands/_shared/communication.md imposes on the model.
#
# It prints no rule and no bare target. The rules already load twice per session, through
# ~/.claude/CLAUDE.md and the director output style, and the reply is still long, so a third copy
# adds nothing. A number with no limit beside it states no problem. A limit printed after a reply
# that met it becomes a figure to fill: the 15-line cap covers a decision block, and most turns are
# not one, so a two-line answer would drift up toward fifteen.
#
# Three triggers, each a written rule rather than an invented threshold:
#   * a sentence over 25 words     — the contract's universal sentence ceiling
#   * banned filler                — lib/doc-lint-patterns.tsv, prose/reference/process groups
#   * over 15 lines in a decision block, recognised by two of its six field labels
#
# Known blind spot: a padded paragraph of short sentences, with no filler and no decision fields,
# measures clean. That is the defect the operator actually complained about, and none of the three
# triggers catches it. The 2026-09-10 review in ADR-025 decides what to do about it.
#
# Reads: ~/.claude/brevity-state.<session_id>.json, written by scripts/output-lint-hook.sh
# Off:   BREVITY=off

set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
COMMON="$(dirname "$SELF")/../lib/hook-common.sh"
[ -r "$COMMON" ] || exit 0
# shellcheck source=../lib/hook-common.sh
. "$COMMON"

hook_off BREVITY && exit 0

payload="$(cat)"
session="$(hook_json_field "$payload" '.session_id // empty')"

# One definition of the path, shared with the hook that writes it.
state="$(hook_state_path "$session")" || exit 0
[ -r "$state" ] || exit 0

lines="$(jq -r '.lines // 0' "$state" 2>/dev/null)" || exit 0
long="$(jq -r '.long_sentences // 0' "$state" 2>/dev/null)" || exit 0
hits="$(jq -r '.notes // ""' "$state" 2>/dev/null)" || exit 0
block="$(jq -r '.is_decision_block // 0' "$state" 2>/dev/null)" || exit 0

case "${lines}${long}${block}" in *[!0-9]*) exit 0 ;; esac

breaches=""
[ "${long:-0}" -gt 0 ] \
    && breaches="${breaches}${long} sentence(s) over the 25-word ceiling. "
[ "${block:-0}" -eq 1 ] && [ "${lines:-0}" -gt 15 ] \
    && breaches="${breaches}${lines} lines in a decision block, which is capped at 15. "
# The pattern table's own message, never its code — a code number tells the reader nothing.
[ -n "$hits" ] \
    && breaches="${breaches}${hits}. "

[ -z "$breaches" ] && exit 0

printf 'Your previous reply broke a limit. %s\n' "$breaches"
printf 'Cut narrative, not warnings, blockers, open questions, or the impact line.\n'
exit 0
