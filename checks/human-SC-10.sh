#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { printf '%s\n' "$*"; exit 1; }
step="$root/commands/v-team/steps/03-propose-loop.md"; disp="$root/commands/v-team.md"
for f in "$step" "$disp"; do [ -f "$f" ] || { printf '%s missing — cannot say\n' "${f#$root/}"; exit 2; }; done
grep -qF 'render-human.sh' "$step" || fail "03-propose-loop.md does not name bin/render-human.sh"
grep -qF 'gate.sh human' "$step" || fail "03-propose-loop.md does not run gate.sh human"
grep -qF 'human_plan' "$step" || fail "03-propose-loop.md does not record human_plan"
grep -qF 'file:' "$step" || fail "03-propose-loop.md names no file: fallback for a failed publish"
grep -qF 'gate.sh human' "$disp" || fail "v-team.md Step 4 does not run gate.sh human"
grep -qF 'human-plan.md' "$step" || fail "03-propose-loop.md does not point at the human plan contract"
exit 0
