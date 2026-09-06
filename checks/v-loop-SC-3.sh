#!/usr/bin/env bash
# SC-3 — commands/v-loop/campaign-rules.md restates no rule a shared module already owns.
#
# Every prose rule the framework adds spends the same attention as one that matters, and a session
# does not get to choose which rules lose. A rule with a home is referenced from here, never
# repeated. Fails on a restatement.
#
# LIMIT, stated so a green run is not read as proof: this matches the owners' literal wording. A
# rule reworded rather than copied passes. Recorded in vault/check-budget.md.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/v-loop/campaign-rules.md"
[ -f "$f" ] || { printf '  MISSING  %s does not exist\n' "$f"; exit 1; }

owned=$(cat <<'TSV'
writes? (its|the|every) artifacts? to disk	agent-conduct.md §3
report is not the deliverable	agent-conduct.md §3
put what went wrong at the top	agent-conduct.md §2
lead with (open )?blockers	agent-conduct.md §2
report what could not be verified	agent-conduct.md §2 + communication.md
a number carries the command	agent-conduct.md §4
never state a count you cannot reproduce	agent-conduct.md §4
measure.{0,20}never hardcode	agent-conduct.md §4
read the whole source before	agent-conduct.md §1
the source can be wrong	agent-conduct.md §5
correct the plan when it is wrong	agent-conduct.md §5
verify the (claim|filing) against (the )?(live|current) (code|source)	agent-conduct.md §5
choose the model per agent	agent-conduct.md fan-out
settle names before spawning	agent-conduct.md fan-out
slice shared context by what each agent needs	agent-conduct.md fan-out
prove coverage mechanically	agent-conduct.md fan-out
report exceptions,? not (status|normality)	communication.md
answer first	communication.md
lead with the conclusion	communication.md + document-standard.md rule 2
current truth only	document-standard.md rule 5
delete superseded	document-standard.md rule 5
(met|failed), .*not-applicable	definition-of-done.md
kills .{0,3}1 seeded mutant	definition-of-done.md §Tests + v-team 04-execute-loop §5.2
coverage without fault.detection	definition-of-done.md §Tests + v-team 04-execute-loop §5.2
temporarily break the code and confirm	definition-of-done.md §Tests
never weaken an assertion	v-team 04-execute-loop.md §5.2
separate defects from opinions	critic-panel.md §(d) severity + grounding
ground first	critic-panel.md §(a)
(default|hard max).{0,20}(3|5).{0,20}(critics|agents)	critic-panel.md §(b)
ask everything.{0,20}(up front|in the first exchange).{0,40}never	elicitation.md
do not invent a third	elicitation.md
leave pushing to the operator	v-work 05-commit-capture.md §5.1
commit with a pathspec	vault-sync.md §2 + scripts/staging-hook.sh
never raw git against a vault	vault-sync.md
declared (values|identifiers) are consumed	bin/gate.sh readers
TSV
)
fail=0
while IFS=$'\t' read -r pat owner; do
  [ -n "$pat" ] || continue
  if hit=$(grep -inE "$pat" "$f"); then
    printf '  RESTATED  %s owns this; reference it instead:\n%s\n' "$owner" "$hit"; fail=1
  fi
done <<<"$owned"

# every module under commands/_shared/ must appear as an owner above, so a new module cannot be
# added without extending this check
for m in "$root"/commands/_shared/*.md; do
  n=$(basename "$m")
  grep -q "$n" <<<"$owned" || { printf '  UNCOVERED  %s owns rules this check never looks for\n' "$n"; fail=1; }
done

grep -q 'agent-conduct.md' "$f" || { printf '  MISSING  the file defers to no shared module\n'; fail=1; }

[ "$fail" -eq 0 ] && printf '  OK  campaign-rules.md restates no shared-module rule; all _shared modules covered\n'
exit "$fail"
