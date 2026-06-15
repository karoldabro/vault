#!/usr/bin/env bash
# vault-migrate — convert an existing submodule-based project vault to the global model.
#
# Older vaults carried the framework as a `_process/` git submodule. This removes that submodule,
# writes a repo `VAULT.md` recording where the vault lives, and repoints the MOC at the global
# framework install. Idempotent: a vault with no `_process/` submodule is reported as already
# migrated and left untouched.
#
# Run it from inside the CODE repo (so the slug + VAULT.md location resolve), or point at the vault
# directly with --vault.
#
# What it does:
#   1. Resolve the vault dir (from slug/$VAULT_HOME, or --vault).
#   2. If no `_process/` submodule → already migrated, exit 0.
#   3. Deinit + remove the submodule (.gitmodules, index, .git/modules/_process).
#   4. Write <code-repo>/VAULT.md (vault_path + slug) if absent.
#   5. Repoint the MOC `_process` pointer at $VAULT_FRAMEWORK_PATH.
#   6. Commit `chore(vault): de-submodule`.
#
# Environment overrides:
#   VAULT_HOME              default: $HOME/vault
#   VAULT_FRAMEWORK_PATH    default: this framework install (parent of bin/)
#   VAULT_INIT_GIT_FLAGS    extra git flags (tests use: -c protocol.file.allow=always)
#
# Flags:
#   --slug NAME             override derived slug
#   --vault PATH            operate on this vault dir directly (skips slug resolution)
#   --framework-path PATH   override VAULT_FRAMEWORK_PATH
#   --no-vault-md           do not write <code-repo>/VAULT.md
#   --yes                   non-interactive (currently informational)
#   -h, --help              show usage

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_HOME="${VAULT_HOME:-${HOME}/vault}"
VAULT_FRAMEWORK_PATH="${VAULT_FRAMEWORK_PATH:-${VAULT_ROOT}}"
VAULT_INIT_GIT_FLAGS="${VAULT_INIT_GIT_FLAGS:-}"

slug=""
vault_dir=""
no_vault_md=0

usage() {
    sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --slug)            slug="$2"; shift 2 ;;
        --vault)           vault_dir="$2"; shift 2 ;;
        --framework-path)  VAULT_FRAMEWORK_PATH="$2"; shift 2 ;;
        --no-vault-md)     no_vault_md=1; shift ;;
        --yes|-y)          shift ;;
        -h|--help)         usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
    esac
done

#------------------------------------------------------------------------------
# Resolve code repo + vault dir
#------------------------------------------------------------------------------
code_repo=""
if git -C "$(pwd)" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    code_repo="$(git -C "$(pwd)" rev-parse --show-toplevel)"
fi

if [ -z "${slug}" ] && [ -n "${code_repo}" ]; then
    slug="$(basename "${code_repo}")"
fi

if [ -z "${vault_dir}" ]; then
    if [ -z "${slug}" ]; then
        echo "ERROR: cannot resolve a slug. Run inside a code repo or pass --slug / --vault." >&2
        exit 1
    fi
    vault_dir="${VAULT_HOME}/${slug}"
fi

if [ ! -d "${vault_dir}/.git" ] && [ ! -f "${vault_dir}/.git" ]; then
    echo "ERROR: ${vault_dir} is not a git repo. Nothing to migrate." >&2
    exit 1
fi

#------------------------------------------------------------------------------
# Already migrated?
#------------------------------------------------------------------------------
if [ ! -e "${vault_dir}/_process" ] && ! grep -q "_process" "${vault_dir}/.gitmodules" 2>/dev/null; then
    echo "Vault at ${vault_dir} has no _process submodule — already on the global model. Nothing to do."
    exit 0
fi

echo "Migrating vault off submodule: ${vault_dir}"
echo "  slug:           ${slug:-<unknown>}"
echo "  framework path: ${VAULT_FRAMEWORK_PATH}"

#------------------------------------------------------------------------------
# Remove the _process submodule
#------------------------------------------------------------------------------
# shellcheck disable=SC2086
git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" submodule deinit -f _process 2>/dev/null || true
# `git rm` stages the gitlink removal and drops the section from .gitmodules.
# shellcheck disable=SC2086
git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" rm -f _process 2>/dev/null \
    || rm -rf "${vault_dir}/_process"
rm -rf "${vault_dir}/.git/modules/_process"

# Drop .gitmodules if it is now empty (only whitespace left).
gitmodules="${vault_dir}/.gitmodules"
if [ -f "${gitmodules}" ] && [ ! -s "${gitmodules}" ]; then
    git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" rm -f .gitmodules 2>/dev/null || rm -f "${gitmodules}"
elif [ -f "${gitmodules}" ] && ! grep -q '[^[:space:]]' "${gitmodules}"; then
    git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" rm -f .gitmodules 2>/dev/null || rm -f "${gitmodules}"
fi

#------------------------------------------------------------------------------
# Repoint the MOC _process pointer at the global framework
#------------------------------------------------------------------------------
moc="${vault_dir}/_moc.md"
if [ -f "${moc}" ] && grep -q "_process" "${moc}"; then
    sed -i \
        -e "s|- \[\[_process/vault-guide\]\].*|- Process docs: \`${VAULT_FRAMEWORK_PATH}/vault-guide.md\` (global framework install)|" \
        "${moc}"
fi

#------------------------------------------------------------------------------
# Write VAULT.md in the code repo
#------------------------------------------------------------------------------
if [ "${no_vault_md}" -eq 0 ] && [ -n "${code_repo}" ]; then
    vault_md="${code_repo}/VAULT.md"
    vault_path_value="${vault_dir/#${HOME}/\~}"
    if [ -f "${vault_md}" ]; then
        echo "  VAULT.md already present — leaving it untouched."
    else
        sed -e "s|{{slug}}|${slug}|g" \
            -e "s|^vault_path: ./vault|vault_path: ${vault_path_value}|" \
            "${VAULT_ROOT}/templates/VAULT.md" > "${vault_md}"
        echo "  wrote ${vault_md}"
    fi
fi

#------------------------------------------------------------------------------
# Commit
#------------------------------------------------------------------------------
if ! git -C "${vault_dir}" config user.email >/dev/null 2>&1; then
    git -C "${vault_dir}" config user.email "vault-init@localhost"
    git -C "${vault_dir}" config user.name  "vault-init"
fi
# shellcheck disable=SC2086
git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" add -A
# shellcheck disable=SC2086
git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" commit --quiet \
    -m "chore(vault): de-submodule — migrate to global framework" \
    || echo "  (nothing to commit)"

echo ""
echo "Migrated ${vault_dir} to the global framework model."
echo "Next:"
if [ "${no_vault_md}" -eq 0 ] && [ -n "${code_repo}" ]; then
    echo "  - Commit the new VAULT.md in ${code_repo}."
fi
echo "  - Run /v-work to confirm commands resolve the vault with no _process/."
