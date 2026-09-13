#!/usr/bin/env bash
# SC-1 — a session reading commands/v-method.md finds everything it needs to run the command.
#
# A command whose refusals, its one blocking question and its output contract are not all present is
# a command that starts work it should have declined. Each grep below names a thing the command
# cannot be run without, so a miss is a real gap rather than a wording preference.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cmd="$root/commands/v-method.md"
fail=0

[ -f "$cmd" ] || { printf '  MISSING  %s does not exist yet\n' "$cmd"; exit 1; }

need() {  # need <label> <extended-regex>
    grep -qiE "$2" "$cmd" || { printf '  FAIL  %s names no %s\n' "$cmd" "$1"; fail=1; }
}

# The three refusals. Each one stops the command before it produces a method.
need 'refusal on a missing problem statement'  'problem statement'
need 'refusal on an unobservable criterion'    'WHEN .*SHALL'
need 'refusal that sends small work down the ladder' 'v-ask.*v-do.*v-work.*v-team|the ladder'

# The one question that cannot be defaulted: a fixed budget and guaranteed criteria are exclusive.
need 'the fixed-budget-or-fixed-criteria question' 'appetite|fixed budget|which one is fixed'

# The reference tables live beside the command; the command must actually read them.
need 'the routing reference'   'commands/v-method/routing\.md'
need 'the output template'     'templates/method\.md'

# Every stage the command writes carries these four, or the method file is decoration.
for f in 'kill criterion' 'exit evidence' 'seats' 'tools'; do
    need "the per-stage \`$f\`" "$f"
done

# The gate a stage is graded by, and the command that runs each stage.
need 'the verdict mechanism' 'bin/gate\.sh'

[ "$fail" -eq 0 ] || exit 1
printf '  OK  v-method.md carries three refusals, the budget question, both references and the per-stage fields\n'
