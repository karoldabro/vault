#!/usr/bin/env bash
# rule-count.sh — how many rules a session is asked to obey, and in which grammatical form.
#
# Two numbers, both measured because both are known to move compliance.
#
# COUNT. Instruction-following degrades as the number of simultaneous instructions rises; the best
# model satisfies every constraint of a multi-part instruction under 30% of the time. A rule with no
# check behind it is therefore not free — it spends the same attention as one that matters, and you
# do not get to choose which rules lose.
#
# FORM. Across 4,416 trials, prohibitions fell from 73% compliance at turn 5 to 33% by turn 16 while
# requirements held at 100%. `Never git add -A` is the weak form of `Stage each file by name`.
#
# Usage:  bin/rule-count.sh            report the numbers
#         bin/rule-count.sh --assert   exit 1 when a budget is crossed
#         bin/rule-count.sh --lines    list the prohibition-shaped lines, worst file first
#
# Exit: 0 within budget · 1 over budget · 2 usage error

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Baseline measured 2026-09-04, before any cut. Lowering these is the work; raising one is a visible
# edit in this file rather than a number that drifts.
BUDGET_RULES=173
BUDGET_RATIO_NUM=1     # prohibitions must not exceed requirements: ratio ceiling 1:1

# The files one /v-team run is told to read and obey. Adding a file here is adding to what a session
# must hold at once, so the list is explicit rather than a glob.
CORPUS=(
  commands/v-team.md
  commands/_shared/communication.md
  commands/_shared/document-standard.md
  commands/_shared/agent-conduct.md
  commands/_shared/critic-panel.md
  commands/_shared/definition-of-done.md
  commands/v-work/steps/01-analyze.md
  commands/v-work/steps/02-load-context.md
  commands/v-team/steps/03-propose-loop.md
  commands/v-team/steps/04-execute-loop.md
  commands/v-work/steps/05-commit-capture.md
  tool-playbook.md
)

PROHIBIT='(^|[^a-z])(never|do not|don.t|must not|cannot|may not|refuses? to)([^a-z]|$)'
REQUIRE='(^|[^a-z])(must|shall|always|is required|are required)([^a-z]|$)'

present=()
for f in "${CORPUS[@]}"; do [ -r "${ROOT}/${f}" ] && present+=("${ROOT}/${f}"); done
[ "${#present[@]}" -gt 0 ] || { printf 'no corpus files found under %s\n' "$ROOT" >&2; exit 2; }

count() { grep -hciE "$1" "${present[@]}" 2>/dev/null | paste -sd+ | bc 2>/dev/null || echo 0; }

prohibitions=$(count "$PROHIBIT")
requirements=$(grep -hiE "$REQUIRE" "${present[@]}" 2>/dev/null | grep -civE 'must not|never' || true)
rules=$(grep -hciE "${PROHIBIT}|${REQUIRE}" "${present[@]}" 2>/dev/null | paste -sd+ | bc 2>/dev/null || echo 0)
lines=$(cat "${present[@]}" 2>/dev/null | wc -l)
words=$(cat "${present[@]}" 2>/dev/null | wc -w)

case "${1:-}" in
--lines)
    for f in "${present[@]}"; do
        n=$(grep -ciE "$PROHIBIT" "$f" || true)
        [ "$n" -gt 0 ] && printf '%4d  %s\n' "$n" "${f#$ROOT/}"
    done | sort -rn
    exit 0 ;;
esac

printf 'corpus        %d files · %d lines · ~%d tokens\n' "${#present[@]}" "$lines" "$((words * 13 / 10))"
printf 'rule lines    %d   (budget %d)\n' "$rules" "$BUDGET_RULES"
printf 'prohibitions  %d\n' "$prohibitions"
printf 'requirements  %d\n' "$requirements"

# The output style is loaded too, and is deliberately outside the budget: it earns its length by
# improving the reply, and cutting it is not this measurement's business.
style="${ROOT}/output-styles/director.md"
[ -r "$style" ] && printf 'style (not budgeted)  %s lines\n' "$(wc -l < "$style")"

[ "${1:-}" = "--assert" ] || exit 0

over=0
if [ "$rules" -gt "$BUDGET_RULES" ]; then
    printf '\nOVER: %d rule lines, budget %d\n' "$rules" "$BUDGET_RULES" >&2
    over=1
fi
if [ "$prohibitions" -gt $(( requirements * BUDGET_RATIO_NUM )) ]; then
    printf 'OVER: %d prohibitions against %d requirements. A prohibition falls to 33%% compliance by turn 16; a requirement holds. Rewrite, do not delete the rule.\n' \
        "$prohibitions" "$requirements" >&2
    over=1
fi
exit "$over"
