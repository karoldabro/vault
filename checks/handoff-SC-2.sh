#!/usr/bin/env bash
# SC-2 — /v-report carries everything a later session needs to act on a problem nobody fixed today.
#
# Fails when the command drops one of the ten fields, loses a mode, or when templates/report.md
# carries the finder as a key in its body. The finder belongs in frontmatter: a rule with an author
# attached in the body reads as one person's opinion, which document-standard.md rule 7 bars.
#
# Modes are matched as they are invoked. A bare `grep -i list` was satisfied by the word "checklist",
# and a bare `grep -i unknown` by any sentence containing "unknown".
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cmd="$root/commands/v-report.md"
tpl="$root/templates/report.md"
fail=0
need()  { grep -qiE "$1" "$cmd" || { printf '  MISSING  %s\n' "$2"; fail=1; }; }
# `--` before the pattern: a flag name such as --open is a pattern here, never a grep option.
needF() { grep -qF -- "$1" "$cmd" || { printf '  MISSING  %s\n' "$2"; fail=1; }; }

[ -f "$cmd" ] || { printf '  MISSING  %s does not exist\n' "$cmd"; exit 1; }
[ -f "$tpl" ] || { printf '  MISSING  %s does not exist\n' "$tpl"; exit 1; }

# the two frontmatter keys and the eight sections a report carries
needF 'found_by'         'the report never records who found it'
needF 'found_in'         'the report never records what was being done when it surfaced'
needF 'severity'         'reports carry no severity, so a list of forty is unordered'
needF '## What is wrong' 'the report never states the defect'
needF '## Files'         'the report never names the files involved'
needF '## Consequence'   'the report never says what breaks and who notices'
needF '## Cause'         'the report never asks why it is this way'
needF '## How to see it' 'the report gives no way to reproduce the problem'
needF '## Repair'        'the report suggests no repair'
needF '## Not now because' 'the report never records why it was left'
needF '## Closes when'   'the report names no condition that would close it'

# an unknown cause is the honest answer and the command has to permit it in so many words
need 'cause.{0,120}unknown|unknown.{0,120}cause' \
     'the command never allows an unknown cause, so a session will invent one'

# the three modes, as invoked
needF '/v-report list'  'no list branch'
needF '/v-report close' 'no close branch'
needF '--open'          'list cannot be filtered to open reports'
needF '--fixed'         'closing does not record a report as fixed'
needF '--rejected'      'closing does not distinguish rejected from fixed'

# severity is written only if something orders by it
need 'severity.{0,200}(order|sort|rank)|(order|sort|rank).{0,200}severity' \
     'nothing orders a report list by severity, so the key is written and never read'

# the one-line offer another command makes
need 'offer' 'nothing says how another command offers to file a report'

needF 'reports/' 'the command never names the reports folder'

head -1 "$cmd" | grep -q '^---$' || { printf '  MISSING  no frontmatter fence\n'; fail=1; }
grep -qE '^description: .{40,}' "$cmd" || { printf '  MISSING  frontmatter description under 40 characters\n'; fail=1; }

grep -q '^type: report' "$tpl" || { printf '  MISSING  template declares no type: report\n'; fail=1; }

# the finder is a key in the frontmatter and a key nowhere below it. Prose ABOUT the key survives:
# only the key form is matched, so the template may state its own constraint.
if ! head -1 "$tpl" | grep -q '^---$'; then
  printf '  MISSING  templates/report.md does not open with a frontmatter fence\n'; fail=1
else
  fence_end=$(awk 'NR>1 && /^---$/{print NR; exit}' "$tpl")
  if [ -z "$fence_end" ]; then
    printf '  MISSING  templates/report.md has no closing frontmatter fence\n'; fail=1
  else
    head -n "$fence_end" "$tpl" | grep -qE '^found_by:' \
      || { printf '  MISSING  template has no found_by key in frontmatter\n'; fail=1; }
    if tail -n "+$((fence_end + 1))" "$tpl" | grep -qE '^[[:space:]]*(-[[:space:]]*)?found_by[:=]'; then
      printf '  WRONG  templates/report.md carries found_by as a key in its body; it belongs in frontmatter only\n'
      fail=1
    fi
  fi
fi

[ "$fail" -eq 0 ] && printf '  OK  /v-report carries ten fields, three modes, and keeps the finder in frontmatter\n'
exit "$fail"
