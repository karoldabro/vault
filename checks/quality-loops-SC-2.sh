#!/usr/bin/env bash
# SC-2 of vault/plans/2026-10-18-1257-quality-loops.md — the registry accepts the check point and runs it only for opted-in plugins.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
fail() { printf '%s\n' "$*"; exit 1; }
grep -qE '^VAULT_PLUGIN_POINTS=".*\bcheck\b' lib/plugin-registry.sh || fail "lib/plugin-registry.sh does not implement the check point"
grep -q '^vault_plugin_run_check()' lib/plugin-registry.sh || fail "lib/plugin-registry.sh has no vault_plugin_run_check"
grep -q 'extend/check.sh' vault/architecture/plugin-extension-contract.md || fail "plugin-extension-contract.md does not define extend/check.sh"
out=$(./tests/run.sh tests/unit/plugin-registry.bats 2>&1)
grep -q '^1\.\.' <<<"$out" || { echo "tests/unit/plugin-registry.bats did not run"; exit 2; }
grep -qi '^ok .*check.*executable' <<<"$out" || fail "no passing test refuses a non-executable check.sh"
grep -q '^not ok' <<<"$out" && fail "$(grep '^not ok' <<<"$out")"
exit 0
