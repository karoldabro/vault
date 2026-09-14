#!/usr/bin/env bash
# SC-1 — /v-handoff carries what the next session needs, and refuses what belongs elsewhere.
#
# Fails when the command file drops one of the eight core sections, loses a mode, loses either
# refusal, or when templates/handoff.md puts an optional section above a core one. The order is the
# point: a handoff read at 1am is read from the top, and the failure this guards is the critical
# line buried under routine.
#
# Headings are matched as whole lines outside fenced blocks. A substring match accepted `### Goal`
# nested under an optional section, and an unanchored one accepted a heading named inside a comment.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cmd="$root/commands/v-handoff.md"
tpl="$root/templates/handoff.md"
fail=0
need()  { grep -qiE "$1" "$cmd" || { printf '  MISSING  %s\n' "$2"; fail=1; }; }
# `--` before the pattern: a flag name such as --open is a pattern here, never a grep option.
needF() { grep -qF -- "$1" "$cmd" || { printf '  MISSING  %s\n' "$2"; fail=1; }; }

# First or last exact-match line for a heading, ignoring anything inside a ``` fence.
head_line() { awk -v h="$1" -v want="$2" 'BEGIN{f=0;first=0;last=0}
  /^```/{f=!f; next} !f && $0==h {if(!first)first=NR; last=NR}
  END{ if(want=="first") print first; else print last }' "$tpl"; }

[ -f "$cmd" ] || { printf '  MISSING  %s does not exist\n' "$cmd"; exit 1; }
[ -f "$tpl" ] || { printf '  MISSING  %s does not exist\n' "$tpl"; exit 1; }

CORE=('## Left to do' '## Do not touch' '## Unverified' '## Goal' '## Task' '## Requirements' '## Next command' '## Blockers')
OPT=('## Success criteria' '## Plan' '## Method' '## Done' '## Direction' '## Notes')

for h in "${CORE[@]}" "${OPT[@]}"; do
  needF "$h" "the command never names the ${h#\#\# } section"
done

# the three modes, matched as they are invoked rather than as English words
needF '/v-handoff resume' 'no resume branch — a handoff nothing reads is a file nobody opens'
needF '/v-handoff list'   'no list branch'
need  'status:'  'the command never reads the status key, so resume cannot tell open from resumed'
need  'resumed'  'the command never sets status to resumed, so one handoff is picked up twice'

# chaining, and the mode that reads it
needF 'continues' 'the command never links the previous handoff'
need  'continues.{0,200}(chain|backwards|earlier|previous)|(chain|backwards).{0,200}continues' \
      'nothing reads the continues key back, so the chain is written and never followed'

# the two refusals
needF '/v-init'    'the command does not say what to run when no vault exists'
needF '/v-capture' 'the command never sends a finished session to /v-capture instead'
need  '(refuse|refusal)' 'the command states no refusal'

needF 'handoffs/' 'the command never names the handoffs folder'

head -1 "$cmd" | grep -q '^---$' || { printf '  MISSING  no frontmatter fence\n'; fail=1; }
grep -qE '^description: .{40,}' "$cmd" || { printf '  MISSING  frontmatter description under 40 characters\n'; fail=1; }

# every core section stands above every optional one. Core takes its LAST line and optional its
# FIRST, so a duplicated core heading cannot hide below an optional section.
core_last=0; opt_first=0
for h in "${CORE[@]}"; do
  n=$(head_line "$h" last)
  [ "$n" -gt 0 ] 2>/dev/null || { printf '  MISSING  template has no %s heading\n' "$h"; fail=1; continue; }
  [ "$n" -gt "$core_last" ] && core_last=$n
done
for h in "${OPT[@]}"; do
  n=$(head_line "$h" first)
  [ "$n" -gt 0 ] 2>/dev/null || { printf '  MISSING  template has no %s heading\n' "$h"; fail=1; continue; }
  { [ "$opt_first" -eq 0 ] || [ "$n" -lt "$opt_first" ]; } && opt_first=$n
done
if [ "$core_last" -gt 0 ] && [ "$opt_first" -gt 0 ] && [ "$core_last" -ge "$opt_first" ]; then
  printf '  WRONG  templates/handoff.md puts an optional section above a core one (last core line %s, first optional line %s)\n' "$core_last" "$opt_first"
  fail=1
fi

grep -q '^type: handoff' "$tpl" || { printf '  MISSING  template declares no type: handoff\n'; fail=1; }

[ "$fail" -eq 0 ] && printf '  OK  /v-handoff carries eight core sections above the optional ones, three modes and both refusals\n'
exit "$fail"
