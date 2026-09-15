#!/usr/bin/env bash
# SC-1 — commands/v-loop.md carries everything a session needs to start, resume and stop a campaign
# without asking the operator a second time.
#
# Fails when the command file would let a session begin against the operator's own system, begin with
# a restore command nobody ran, start with the adapter unnamed, resume with its round counter reset,
# or run without a ceiling.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cmd="$root/commands/v-loop.md"
fail=0
need() { grep -qiE "$1" "$cmd" || { printf '  MISSING  %s\n' "$2"; fail=1; }; }

[ -f "$cmd" ] || { printf '  MISSING  %s does not exist\n' "$cmd"; exit 1; }

# precondition, refusal 1: an arena the operator named, not merely a running system
need 'disposable|willing to lose' 'the precondition does not require an arena the operator agreed to lose'
need 'arena' 'the precondition never names the arena'
need 'operator|in words' 'the operator is never asked to name the arena'
need 'infer|config file' 'nothing bars an arena the session inferred for itself'

# precondition, refusal 2: a restore command the session has actually run
need 'restore' 'the precondition does not require a restore command'
need 'runs? (it )?once at intake|run once at intake' 'the restore command is collected but never run'
need 're-read|re.read the arena' 'nothing proves the restore by reading the arena back'
need 'untracked' 'nothing warns that the commonest restore leaves untracked files behind'
need 'which of the two|naming which' 'a refusal does not say which of the two facts is missing'

# intake: the decisions taken in the first exchange
need 'adapter' 'intake does not ask which adapter'
need 'target' 'intake does not ask what the adapter works on'
need 'specification|spec lives|where its spec' 'intake does not ask where the specification lives'
need 'data' 'intake does not ask which data to load'
need 'push|cadence' 'intake does not ask the commit and push cadence'
need 'already (know|broken)|known.broken' 'intake does not ask what is already known broken'

# caps, with numbers
need 'loop_max_rounds' 'no loop_max_rounds ceiling'
need 'loop_max_rounds[^0-9]{0,40}[0-9]' 'loop_max_rounds has no default value'
need 'retry cap|max_fix_attempts|fix attempts' 'no per-defect retry cap'
need '(retry cap|max_fix_attempts|fix attempts)[^0-9]{0,40}[0-9]' 'the retry cap has no default value'
need 'cap.{0,60}(escalat|stop|report)|(escalat|stop|report).{0,60}cap' 'no escalation stated for a cap hit'

# resume
need 'rounds_used' 'the round counter is not read back from state, so a resumed campaign restarts its cap'
need 'resum' 'no resume branch'
need 'campaigns/' 'nothing says where an unfinished campaign is found'

# the spawn envelope, and what it must carry
need 'envelope' 'no spawn envelope is defined'
need 'campaign-rules' 'the envelope does not carry the campaign rules'
need 'AGENT-BRIEF' 'the envelope does not carry the agent brief'
need 'adapters/' 'the envelope does not carry the adapter'
need 'conflicts_on|conflict set' 'the envelope does not carry the case conflict scope'

# routing: what to use instead, per ADR-015
need '/v-work|/v-team|/v-do' 'the command names no cheaper alternative'
need 'instead|rather than|not the' 'the command never says when not to use it'

# the unattended runner is handed over, never installed
need 'crontab|unattended|hand' 'nothing says the unattended runner is handed over rather than installed'

# the engine is the loop, not the task
need 'adapters\.md' 'the command does not name the adapter contract'
for a in 'test-and-repair' 'document-corpus'; do
  need "adapters/${a}" "the command does not name the ${a} adapter"
done
grep -qiE 'executable test|(^|[^-])tester|browser' "$cmd" && {
  printf '  LEAKED   the engine carries task vocabulary that belongs in an adapter\n'; fail=1; }

# every template it names exists
while read -r t; do
  [ -n "$t" ] || continue
  [ -f "$root/$t" ] || { printf '  MISSING  names %s, which does not exist\n' "$t"; fail=1; }
done < <(grep -oE 'templates/campaign/[A-Za-z0-9_.-]+' "$cmd" | sort -u)

[ "$fail" -eq 0 ] && printf '  OK  v-loop.md carries both refusals, the intake, both caps, resume, the envelope and its adapters\n'
exit "$fail"
