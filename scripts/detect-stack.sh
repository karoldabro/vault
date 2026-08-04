#!/usr/bin/env bash
# SessionStart hook for the vault plugin.
#
# Detects only. It NEVER installs anything: installing the tool stack runs vendor
# curl|sh scripts and apt, which must not happen unattended at session start
# (ADR-005). When something is missing it prints one line pointing at /v-setup;
# when everything is present it prints nothing at all, per the framework's
# "report exceptions, not normality" rule.
#
# Always exits 0. A hook that fails must never block a session.
set -uo pipefail

VAULT_HOME="${VAULT_HOME:-${HOME:-}/vault}"

# No HOME means no machine layer to check and no safe path to guess. Stay quiet.
[ -n "${HOME:-}" ] || exit 0

missing=()

[ -f "${VAULT_HOME}/_global/config.md" ] || missing+=("the machine layer (~/vault/_global/)")

# Both installs are a graceful degrade, not a failure — mention them only alongside
# a real gap, never on their own.
if [ "${#missing[@]}" -gt 0 ]; then
    command -v graphify >/dev/null 2>&1 || missing+=("graphify")
    command -v serena >/dev/null 2>&1 || command -v serena-agent >/dev/null 2>&1 || missing+=("serena")
fi

[ "${#missing[@]}" -gt 0 ] || exit 0

printf 'vault plugin: not set up on this machine yet — missing %s' "${missing[0]}"
if [ "${#missing[@]}" -gt 1 ]; then
    printf ' (and %d optional tool(s))' "$(( ${#missing[@]} - 1 ))"
fi
printf '. Run /v-setup once to fix it.\n'

exit 0
