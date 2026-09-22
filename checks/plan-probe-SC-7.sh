#!/usr/bin/env bash
# SC-7 of vault/plans/2026-09-21-1800-plan-time-probes.md — the wiring text and the rule budget.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
md="$root/commands/_shared/plan-probes.md"; loop="$root/commands/v-team/steps/03-propose-loop.md"
[ -r "$md" ] && [ -x "$root/bin/plan-probes.sh" ] || { echo "commands/_shared/plan-probes.md is not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
grep -q '(b2)' "$loop" && grep -q 'commands/_shared/plan-probes.md' "$loop" || fail "step (b2) or its reference is missing from 03-propose-loop.md"
a2=$(grep -n '^## (b2)' "$loop" | head -1 | cut -d: -f1); b=$(grep -n '^## (b)' "$loop" | head -1 | cut -d: -f1); c=$(grep -n '^## (c)' "$loop" | head -1 | cut -d: -f1)
[ -n "$a2" ] && [ "$a2" -gt "$b" ] && [ "$a2" -lt "$c" ] || fail "step (b2) is not between (b) and (c)"
grep -q 'plan-probes.sh budget' "$loop" && grep -q 'plan-probes.sh verify' "$loop" && grep -q 'probe-panel.sh run --stage plan' "$loop" || fail "step (b2) or (g) does not name the three commands"
ids_script=$("$root/bin/plan-probes.sh" auditors | cut -f1 | sort | tr '\n' ' ')
ids_md=$(awk '/^## Auditors/{f=1} f && /^\| [a-z-]+ \|/ && $2 != "id" {print $2} f && /^## / && !/^## Auditors/{exit}' "$md" | sort | tr '\n' ' ')
[ "$ids_script" = "$ids_md" ] || fail "auditor ids differ: script [$ids_script] md [$ids_md]"
for n in 'a tool is absent' 'skipped' 'without the auditor' 'defect'; do grep -qi "$n" "$md" || fail "plan-probes.md lacks the note for: $n"; done
rc=$("$root/bin/rule-count.sh" | sed -n 's/^rule lines *\([0-9]*\).*/\1/p')
[ "$rc" = 181 ] || fail "bin/rule-count.sh reads $rc rule lines, not 181"
git -C "$root" diff --quiet 435a83e -- commands/_shared/critic-panel.md || fail "commands/_shared/critic-panel.md differs from commit 435a83e"
"$root/bin/doc-lint.sh" "$md" >/dev/null 2>&1 || fail "doc-lint fails on plan-probes.md"
exit 0
