#!/usr/bin/env bash
# The `init` point. Copy this into your plugin at extend/init.sh and make it executable.
#
# The framework runs it once per registered plugin during bin/vault-init.sh, after VAULT.md exists,
# through your own shebang in a child process with stdin closed. Three arguments:
#
#   $1  the code repo being onboarded
#   $2  its vault directory
#   $3  its slug
#
# Exit 0 when you did your work or had nothing to do. Exit 1 to decline. Any higher exit is reported
# as "could not run". The host completes either way, so a failure here never leaves a repo
# half-onboarded — but it also means nobody will notice a silent mistake. Say what you did.
#
# Two rules this stub exists to demonstrate:
#
#   1. Adding your name to `plugins:` is what makes your dod-keys required. Write those keys in the
#      SAME pass, or gate.sh config refuses the repo you just onboarded.
#   2. Merge into an existing `plugins:` line. A second line is silently dropped by the reader, so
#      the next plugin's keys would never be enforced.
#
# Running twice must change nothing the second time.

set -u

PLUGIN_NAME="my-plugin"     # must match extend/plugin.tsv

code_repo=${1:-}
vault_dir=${2:-}
slug=${3:-}

[ -n "${code_repo}" ] || exit 0

vault_md="${code_repo}/VAULT.md"
# The framework skips this point when VAULT.md is absent. Checking again costs nothing and means the
# script is also safe to run by hand.
[ -f "${vault_md}" ] || exit 0

# --- your own per-repo scaffolding ------------------------------------------------------

mkdir -p "${code_repo}/${PLUGIN_NAME}" 2>/dev/null || exit 1

# --- merge into the plugins scalar ------------------------------------------------------

# A file with no trailing newline fuses your first line onto its last key.
[ -n "$(tail -c1 "${vault_md}")" ] && printf '\n' >> "${vault_md}"

current=$(sed -n 's/^plugins:[[:space:]]*//p' "${vault_md}" | head -1 | tr -d '\r')

if ! grep -q '^plugins:' "${vault_md}"; then
    printf 'plugins: %s\n' "${PLUGIN_NAME}" >> "${vault_md}"
elif [ -z "${current}" ]; then
    sed -i "s|^plugins:.*|plugins: ${PLUGIN_NAME}|" "${vault_md}"
elif printf '%s' "${current}" | tr ',' '\n' | tr -d '[:space:]' | grep -qx "${PLUGIN_NAME}"; then
    :   # already listed — running twice changes nothing
else
    sed -i "s|^\(plugins:.*\)$|\1, ${PLUGIN_NAME}|" "${vault_md}"
fi

# --- write every key extend/dod-keys.tsv declares ---------------------------------------

grep -q '^my_setting:' "${vault_md}" \
    || printf 'my_setting: %s\n' "refs/heads/release/*" >> "${vault_md}"

printf '  %s: scaffolded %s and recorded its keys\n' "${PLUGIN_NAME}" "${code_repo}/${PLUGIN_NAME}"
exit 0
