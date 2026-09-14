#!/usr/bin/env bash
# SC-3 — every framework surface that must know about handoffs and reports names them, in the
# section that actually carries the information.
#
# Fails when a folder exists that nothing scaffolds, a document nobody loads, or a check nobody
# scores. An artifact with no reader is the failure vault/indications/artifact-has-a-named-consumer.md
# exists to prevent, and it is invisible until the session that needed the file does not find it.
#
# Every assertion is scoped to one section or one line form. A whole-file grep went green on a single
# mention anywhere, which let an edit to one section satisfy a requirement on four.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0

# Text between a start line and the next section start, so a claim about §2 is checked against §2.
# grep plus sed rather than a dynamic awk regex: awk implementations disagree on how an interpolated
# pattern is escaped, and the container's awk silently matched nothing where the host's matched.
#
# `grep -m1` rather than `grep | head -1`: under `pipefail`, head closing the pipe early kills grep
# with SIGPIPE and the pipeline returns 141, which read as "section not found" on the larger file and
# as success on the smaller one. A check that answers differently by file size answers nothing.
section() {
    local f="$root/$1" start end
    start=$(grep -m1 -nE "$2" "$f" | cut -d: -f1)
    [ -n "$start" ] || return 0
    end=$(tail -n "+$((start + 1))" "$f" | grep -m1 -nE "$3" | cut -d: -f1)
    if [ -n "$end" ]; then sed -n "${start},$((start + end - 1))p" "$f"
    else sed -n "${start},\$p" "$f"; fi
}

# The section text is captured first and matched second. Piping it into `grep -q` let grep exit on
# the first hit, which killed the producing `sed` with SIGPIPE and turned the whole pipeline into a
# 141 under `pipefail` — so an early match reported as a miss and a late match reported as a hit.
in_section() {
  local file=$1 start=$2 end=$3 pat=$4 msg=$5 body
  body=$(section "$file" "$start" "$end")
  grep -qE "$pat" <<<"$body" || { printf '  MISSING  %s: %s\n' "$file" "$msg"; fail=1; }
}
in_file() { grep -qE "$2" "$root/$1" 2>/dev/null || { printf '  MISSING  %s: %s\n' "$1" "$3"; fail=1; }; }

for f in commands/v-work/steps/02-load-context.md bin/vault-init.sh vault-guide.md README.md vault/check-budget.md; do
  [ -f "$root/$f" ] || { printf '  MISSING  %s does not exist\n' "$f"; fail=1; }
done
[ "$fail" -eq 0 ] || exit 1

# the read path — a session starting work is told what is open, and prints it
in_file commands/v-work/steps/02-load-context.md 'handoffs/' 'the context load never looks for an open handoff'
in_file commands/v-work/steps/02-load-context.md 'reports/'  'the context load never looks for an open report'
in_section commands/v-work/steps/02-load-context.md '^### Required output' '^Before marking complete' \
  '^Handoffs:' 'the required-output block never reports an open handoff'
in_section commands/v-work/steps/02-load-context.md '^### Required output' '^Before marking complete' \
  '^Reports:' 'the required-output block never reports an open problem'

# the scaffold — anchored to the loop, so a stray comment cannot satisfy it
in_file bin/vault-init.sh '^for sub in .*handoffs' 'the scaffold loop does not create handoffs/'
in_file bin/vault-init.sh '^for sub in .*reports'  'the scaffold loop does not create reports/'

# the guide — each claim checked inside the section that must carry it
in_section vault-guide.md '^## 2\. Folder map' '^## 3\.' 'handoffs/' 'the §2 folder map omits handoffs/'
in_section vault-guide.md '^## 2\. Folder map' '^## 3\.' 'reports/'  'the §2 folder map omits reports/'
in_section vault-guide.md '^## 4\. Templates'  '^## 5\.' 'handoff\.md' 'the §4 template table omits handoff.md'
in_section vault-guide.md '^## 4\. Templates'  '^## 5\.' 'report\.md'  'the §4 template table omits report.md'
in_section vault-guide.md '^## 6\. When to save what' '^## 7\.' 'handoffs/' 'the §6 decision tree never sends anything to handoffs/'
in_section vault-guide.md '^## 6\. When to save what' '^## 7\.' 'reports/'  'the §6 decision tree never sends anything to reports/'
in_section vault-guide.md '^## 11\. Commands reference' '^## 11b\.' '/v-handoff' 'the §11 command reference omits /v-handoff'
in_section vault-guide.md '^## 11\. Commands reference' '^## 11b\.' '/v-report'  'the §11 command reference omits /v-report'

# §6 must also settle where a problem does NOT go, or three folders claim open work
in_section vault-guide.md '^## 6\. When to save what' '^## 7\.' \
  'outside the scope|scope of the work' 'the §6 tree never says a problem inside the current plan scope stays in that plan'

# the landing page
in_file README.md '/v-handoff' 'the README command table omits /v-handoff'
in_file README.md '/v-report'  'the README command table omits /v-report'

# the check budget — a check nobody scores is a check nobody can retire
for id in handoff-SC-1 handoff-SC-2 handoff-SC-3 handoff-SC-4; do
  in_file vault/check-budget.md "^\\|[[:space:]]*${id}[[:space:]]*\\|" \
    "no budget row for ${id}, so its false-positive rate is never counted"
done

[ "$fail" -eq 0 ] && printf '  OK  the context load, the scaffold, all four guide sections, the README and the check budget name both commands\n'
exit "$fail"
