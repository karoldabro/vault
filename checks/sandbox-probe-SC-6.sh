#!/usr/bin/env bash
# SC-6 — the envelope key and the text: `cr_probe_image` reads the probe image from VCR_SANDBOX_MAP and no indication
# can set it; sandbox.md, the two /v-cr steps, probe-kit.md, the panel module and ADR-009 state the stage once each;
# the rule count does not grow.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { printf '%s\n' "$*"; exit 1; }
grep -q 'cr_probe_image' "$root/lib/cr-sandbox.sh" || { echo "cr_probe_image not written yet"; exit 2; }
( . "$root/lib/cr-sandbox.sh"
  [ "$(VCR_SANDBOX_MAP='memory=1g;probe-image=reg.example/probes:1.2' cr_probe_image)" = "reg.example/probes:1.2" ] || exit 11
  [ "$(VCR_SANDBOX_MAP='memory=1g;probe-image=a:1;probe-image=b:2' cr_probe_image)" = "a:1" ] || exit 12
  for bad in '-x' 'a b' 'a$(id)' 'a`id`' '' '../x' 'a\nb' 'a..b'; do
      VCR_SANDBOX_MAP="probe-image=$bad" cr_probe_image >/dev/null 2>&1 && exit 13
  done
  VCR_SANDBOX_MAP='memory=1g' cr_probe_image >/dev/null 2>&1 && exit 14
  (unset VCR_SANDBOX_MAP; cr_probe_image >/dev/null 2>&1) && exit 15
  [ "$(VCR_SANDBOX_MAP='memory=1g;cpus=2' cr_sandbox_map_get cpus)" = 2 ] || exit 16
  cr_is_envelope_key probe-image || exit 17
  cr_is_envelope_key probe_image || exit 18
  cr_is_recipe_key probe-image && exit 19
  exit 0 ); rc=$?
case $rc in 0) ;; 11) fail "cr_probe_image must print the image of the map" ;; 12) fail "the first probe-image key wins" ;;
    13) fail "cr_probe_image accepted an unsafe image name" ;; 14|15) fail "a map without probe-image must return 1" ;;
    16) fail "cr_sandbox_map_get must print the value of a key" ;; 17|18) fail "probe-image and probe_image must be envelope keys" ;; *) fail "envelope check failed ($rc)" ;; esac

has() { grep -Fq -- "$2" "$root/$1" || fail "$1 lacks: $2"; }
sb=commands/v-cr/sandbox.md
for lit in 'bin/probe-sandbox.sh' 'probe-image' 'VCR_SANDBOX_MAP' 'PROBE_TOOLS_FROM=image' 'framework.tsv' 'rules.tsv' 'no-rules:' \
           'hand-written' '--changed-list' 'INCOMPLETE' 'never falls back to the host' 'lizard' 'typos' 'jq' 'never installs' \
           'An indication never sets the probe image'; do has "$sb" "$lit"; done
has commands/v-cr/steps/02-gather.md 'bin/probe-sandbox.sh'
has commands/v-cr/steps/03-review.md '--posture sandbox --rows-from'
has commands/v-cr/steps/03-review.md 'Probes: sandbox'
has commands/_shared/probe-kit.md '--changed-list'
has commands/_shared/probe-kit.md 'PROBE_TOOLS_FROM'
has commands/_shared/critic-panel.md '--posture sandbox'
has commands/_shared/critic-panel.md 'commands/v-cr/sandbox.md'
has vault/decisions/ADR-009-v-cr-sandboxed-execution.md '## Addendum'
has vault/decisions/ADR-009-v-cr-sandboxed-execution.md 'probe-sandbox'
[ "$(grep -c -- '--posture sandbox' "$root/commands/_shared/critic-panel.md")" -le 2 ] || fail "critic-panel.md states the sandbox posture more than twice"
homes=$(grep -rl 'never falls back to the host' "$root/commands" "$root/lib" "$root/bin" "$root/vault/decisions" 2>/dev/null | sed "s#$root/##" | sort | tr '\n' ' ')
[ "$homes" = "commands/v-cr/sandbox.md " ] || fail "the no-fallback rule has more than one home: $homes"
for f in commands/v-cr/sandbox.md commands/_shared/probe-kit.md; do grep -Fq 'PROBE_TOOLS_FROM=image' "$root/$f" || fail "$f lacks PROBE_TOOLS_FROM=image"; done
[ "$(grep -rl 'PROBE_TOOLS_FROM=image' "$root/commands" | wc -l | tr -d ' ')" = 2 ] || fail "PROBE_TOOLS_FROM=image belongs in sandbox.md and probe-kit.md only"
for f in commands/v-cr/steps/02-gather.md commands/v-cr/steps/03-review.md commands/_shared/critic-panel.md; do
    grep -Fq 'PROBE_TOOLS_FROM' "$root/$f" && fail "$f repeats PROBE_TOOLS_FROM"
done
n=$("$root/bin/rule-count.sh" | awk '/^rule lines/{print $3}')
[ -n "$n" ] && [ "$n" -le 181 ] || fail "the corpus holds $n rule lines; the ceiling is 181"
"$root/bin/doc-lint.sh" "$root/$sb" "$root/vault/decisions/ADR-009-v-cr-sandboxed-execution.md" "$root/commands/_shared/probe-kit.md" >/dev/null 2>&1 || fail "doc-lint refuses one of the touched contract documents"
exit 0
