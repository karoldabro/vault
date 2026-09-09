#!/usr/bin/env bash
# SC-3 — the step files carry the fenced CALL to each new function, and lib/cr-helpers.sh carries
# its DEFINITION.
#
# A bare token grep is the defect vault/indications/enforced-not-just-stated.md §5 describes: a
# function's name also appears in the prose around it, so a token match still passes after the
# invocation is deleted. Each pair below is call-site plus definition.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lib="$root/lib/cr-helpers.sh"
review="$root/commands/v-cr/steps/03-review.md"
gather="$root/commands/v-cr/steps/02-gather.md"
post="$root/commands/v-cr/steps/04-post.md"
panel="$root/commands/_shared/critic-panel.md"

fail=0
note() { printf '  FAIL  %s\n' "$1"; fail=1; }

for f in "$lib" "$review" "$gather" "$post" "$panel"; do
    [ -r "$f" ] || { printf '  MISSING  %s\n' "$f"; exit 1; }
done

for fn in cr_rule_route cr_anchor_check cr_rule_coverage; do
    grep -qE "^${fn}\(\)" "$lib" || note "$lib defines no ${fn}()"
done

# The fenced call, not a mention: the function name followed by an argument on the same line.
grep -qE 'cr_rule_route +"?\$' "$gather"       || note "$gather never calls cr_rule_route with an argument"
grep -qE 'cr_anchor_check +"?\$' "$review"     || note "$review never calls cr_anchor_check with an argument"
grep -qE 'cr_rule_coverage +"?\$' "$review"    || note "$review never calls cr_rule_coverage with an argument"

# The receipt and its vocabulary are defined once, in the shared module.
grep -q 'RULES_CHECKED' "$panel"               || note "$panel does not define the RULES_CHECKED receipt"
for tok in breaks holds 'n/a'; do
    grep -qF "$tok" "$panel"                   || note "$panel does not define the verdict token ${tok}"
done

# The summary line the PR author reads, and the gate that feeds it.
grep -qE 'routed-unchecked' "$review"          || note "$review §3.5 has no routed-unchecked count in the rule line"
grep -qE 'unroutable' "$review"                || note "$review §3.5 has no unroutable count in the rule line"
grep -qE 'cr_rule_coverage' "$post"            || note "$post does not act on the rule-coverage exit code"

[ "$fail" -eq 0 ] && printf '  OK  every new function is called from a step file and defined in the library\n'
exit "$fail"
