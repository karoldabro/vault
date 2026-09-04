#!/usr/bin/env bash
# SC-7: a repo declaring no test, lint and delivery commands is refused at the first step.
# The behaviour lives in gate.sh config (C-03); this asserts the subcommand exists and its cases pass.
set -uo pipefail
./bin/gate.sh config --help >/dev/null 2>&1 || grep -q 'cmd_config' bin/gate.sh || {
    printf 'gate.sh has no config subcommand yet (C-03)\n'; exit 1; }
out=$(./tests/run.sh tests/unit/gate.bats 2>&1); rc=$?
fails=$(printf '%s' "$out" | grep -c '^not ok')
[ "$rc" -eq 0 ] && [ "$fails" -eq 0 ] || { printf 'gate.bats: %s failing\n' "$fails"; exit 1; }
printf 'gate.bats green and config exists\n'
