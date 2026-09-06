#!/usr/bin/env bash
# SC-5 — every safety rule the source campaigns paid for survives into commands/v-loop/campaign-rules.md.
#
# These are the rules whose absence destroyed a working database twice, rewrote another agent's
# commit, and turned passing cases red. A 150-line cap must not be met by cutting them.
# Each is checked in REQUIREMENT form: the sanctioned action, not the prohibition, because a
# prohibition falls to 33% compliance by turn 16 while a requirement holds.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/v-loop/campaign-rules.md"
[ -f "$f" ] || { printf '  MISSING  %s does not exist\n' "$f"; exit 1; }
fail=0
need() { grep -qiE "$1" "$f" || { printf '  MISSING  %s\n' "$2"; fail=1; }; }

need 'pin|pinned'                      'the environment-pinning rule: prove the stack is pinned before running the suite'
need 'restore script|restore path|the environment.{0,20}own restore' 'the rebuild rule: rebuild through the stack own restore path'
need 'pathspec'                        'the commit rule: stage each file by name'
need 'shared branch'                   'the history rule: rewriting only on a branch nobody else holds'
need 'path.{0,30}(not|never|instead of).{0,20}value|pass the path' 'the credential rule: pass the path, never the value'
need 'worker|queue'                    'the worker-restart rule: restart the queue after a code change'
need 'full case id|whole case id|case id in full' 'the teardown rule: tear down on the full case id'
need 'read (it|the value|every restoration) back|read back' 'the restoration rule: read every restoration back'
need 'disjoint'                        'the concurrency rule: one tester unless the conflict sets are disjoint'
need 'fence'                           'the fencing rule: name what each agent owns and what others hold'
need 'the test is wrong'               'the two-column table separating a wrong test from a wrong app'
need 'app source|application source'   'the rule that app source is never edited to make a test pass'

[ "$fail" -eq 0 ] && printf '  OK  all twelve safety rules survive in campaign-rules.md\n'
exit "$fail"
