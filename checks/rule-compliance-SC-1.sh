#!/usr/bin/env bash
# rule-compliance SC-1: the audit prints a rate for every scorable rule and UNSCORABLE for the rest.
#
# Names carry the plan slug because checks/ is flat and the gates plan already owns SC-1.sh.
# First run builds the corpus cache and takes minutes; later runs read the cache and take seconds.
set -uo pipefail
out=$(./bin/rule-audit.sh 2>&1)
rc=$?
[ "$rc" -eq 0 ] || { printf 'rule-audit.sh exited %s\n' "$rc"; exit 1; }

rules=$(./bin/rule-audit.sh --list | grep -c '^ *R-')
scored=$(printf '%s\n' "$out" | grep -cE '^R-[0-9]+ +([0-9]+\.[0-9]%|UNSCORABLE)')
[ "$scored" -eq "$rules" ] || { printf 'inventory has %s rules, audit printed %s lines\n' "$rules" "$scored"; exit 1; }

blank=$(printf '%s\n' "$out" | grep -cE '^R-[0-9]+ +$')
[ "$blank" -eq 0 ] || { printf '%s rule(s) printed no rate and no UNSCORABLE\n' "$blank"; exit 1; }

printf '%s rules: every one carries a rate or UNSCORABLE with a reason\n' "$rules"
