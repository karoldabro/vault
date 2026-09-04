#!/usr/bin/env bash
# SC-8: a defect repair without a test that failed before it is refused.
# The behaviour lives in gate.sh recurrence (E-02). Fails until it exists.
set -uo pipefail
grep -q 'cmd_recurrence' bin/gate.sh || { printf 'gate.sh has no recurrence subcommand yet (E-02)\n'; exit 1; }
[ -f vault/defect-ledger.md ] || { printf 'vault/defect-ledger.md does not exist yet (E-02)\n'; exit 1; }
out=$(./tests/run.sh tests/unit/gate.bats 2>&1); rc=$?
fails=$(printf '%s' "$out" | grep -c '^not ok')
[ "$rc" -eq 0 ] && [ "$fails" -eq 0 ] || { printf 'gate.bats: %s failing\n' "$fails"; exit 1; }
printf 'gate.bats green and recurrence exists\n'
