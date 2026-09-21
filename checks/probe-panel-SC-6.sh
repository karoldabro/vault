#!/usr/bin/env bash
# SC-6 — the four files carry the probe stage, the panel module owns the rules, /v-cr passes no repo registry.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
panel="$root/commands/_shared/critic-panel.md"
team="$root/commands/v-team/steps/04-execute-loop.md"
cr="$root/commands/v-cr/steps/03-review.md"
work="$root/commands/v-work/steps/04-execute.md"
kit="$root/commands/_shared/probe-kit.md"
fail() { printf '%s\n' "$*"; exit 1; }
for f in "$panel" "$team" "$cr" "$work" "$kit"; do [ -r "$f" ] || { echo "cannot read $f"; exit 2; }; done
grep -q 'probe-panel.sh' "$panel" || fail "critic-panel.md does not run bin/probe-panel.sh (not written yet)"
for f in "$team" "$cr" "$work"; do
  grep -q 'probe-panel.sh' "$f" || fail "$f does not run bin/probe-panel.sh"
  grep -q 'critic-panel.md' "$f" || fail "$f does not refer to critic-panel.md for the rules"
done
grep -q -- '--posture own' "$team" || fail "04-execute-loop.md does not pass --posture own"
grep -q -- '--posture own' "$work" || fail "04-execute.md does not pass --posture own"
grep -q -- '--posture pr'  "$cr"   || fail "03-review.md does not pass --posture pr"
grep -q -- '--allow-repo-registry' "$cr" && fail "03-review.md names --allow-repo-registry"
grep -qi 'no checkout' "$cr" || fail "03-review.md does not say what happens with no checkout"
grep -q 'PROBE_BASE' "$team" && grep -q 'PROBE_BASE' "$work" && grep -q 'PROBE_BASE' "$cr" || fail "a caller does not record PROBE_BASE"
n=$(cat "$panel" "$team" "$cr" "$work" | grep -c 'A critic treats `INCOMPLETE` as a lower bound')
[ "$n" -eq 1 ] || fail "the INCOMPLETE rule sentence appears $n times across the four files, expected 1"
grep -q 'A critic treats `INCOMPLETE` as a lower bound' "$panel" || fail "the INCOMPLETE rule is not in critic-panel.md"
grep -q 'critic-panel.md' "$kit" || fail "probe-kit.md Trust does not refer to critic-panel.md"
grep -q 'A consumer treats a finding' "$kit" && fail "probe-kit.md still restates the consumer rule"
grep -q 'probe <id> <file>:<line>' "$panel" || fail "critic-panel.md does not state the check convention"
exit 0
