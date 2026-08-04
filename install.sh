#!/usr/bin/env bash
# Install vault framework commands into ~/.claude/commands/ and output styles into
# ~/.claude/output-styles/.
# Idempotent. Refuses to overwrite non-symlink files.
set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/plugin-detect.sh
. "${VAULT_ROOT}/lib/plugin-detect.sh"

# The plugin install and this symlink install are mutually exclusive: with both
# active every command exists twice (/v-work and /vault:v-work) and the two copies
# drift apart on the next plugin update. Refuse rather than create that state.
if [ "${VAULT_ALLOW_DOUBLE_INSTALL:-0}" -ne 1 ]; then
    if vault_running_from_plugin_cache "${VAULT_ROOT}"; then
        echo "REFUSED: this copy of the framework is Claude Code's plugin cache." >&2
        echo "  The plugin already provides the commands — install.sh would duplicate them," >&2
        echo "  and its symlinks would dangle at the next plugin update." >&2
        echo "  Nothing to do. Run /v-setup instead to install the tool stack." >&2
        exit 1
    fi
    if vault_plugin_installed; then
        echo "REFUSED: the vault plugin is already installed in Claude Code." >&2
        echo "  Running install.sh too would install every command twice." >&2
        echo "  Pick one:" >&2
        echo "    - keep the plugin (recommended): nothing to do here." >&2
        echo "    - switch to symlinks: /plugin uninstall vault@kdabro-vault, then re-run this." >&2
        echo "  Override with VAULT_ALLOW_DOUBLE_INSTALL=1 if you really mean it." >&2
        exit 1
    fi
fi

TARGET_DIR="${HOME}/.claude/commands"
COMMANDS_DIR="${VAULT_ROOT}/commands"
STYLES_TARGET_DIR="${HOME}/.claude/output-styles"
STYLES_DIR="${VAULT_ROOT}/output-styles"

linked=0
skipped=0
refused=0
pruned=0

# link_one <src> <target> — symlink one path, idempotently, never clobbering a real file.
link_one() {
    local src="$1" target="$2" current

    if [ -L "${target}" ]; then
        current="$(readlink "${target}")"
        if [ "${current}" = "${src}" ]; then
            skipped=$((skipped + 1))
            return 0
        fi
        ln -sfn "${src}" "${target}"
        linked=$((linked + 1))
    elif [ -e "${target}" ]; then
        echo "REFUSED: ${target} exists and is not a symlink. Move or remove it manually." >&2
        refused=$((refused + 1))
    else
        ln -s "${src}" "${target}"
        linked=$((linked + 1))
    fi
}

# link_tree <src_dir> <target_dir> [skip_file] [skip_dir]
# Links every *.md in src_dir, then every immediate subdirectory of src_dir.
link_tree() {
    local src_dir="$1" target_dir="$2" skip_file="${3:-}" skip_dir="${4:-}"
    local src name

    mkdir -p "${target_dir}"

    for src in "${src_dir}"/*.md; do
        [ -f "${src}" ] || continue
        name="$(basename "${src}")"
        [ -n "${skip_file}" ] && [ "${name}" = "${skip_file}" ] && continue
        link_one "${src}" "${target_dir}/${name}"
    done

    # A command may ship its step/ref files in a sibling directory; dispatchers reference them at
    # the stable global path ~/.claude/commands/<cmd>/... so they resolve from any project.
    for src in "${src_dir}"/*/; do
        src="${src%/}"
        [ -d "${src}" ] || continue
        name="$(basename "${src}")"
        [ -n "${skip_dir}" ] && [ "${name}" = "${skip_dir}" ] && continue
        link_one "${src}" "${target_dir}/${name}"
    done
}

# prune_stale <src_prefix> <target_dir>
# Removes symlinks in target_dir that point into src_prefix but whose source no longer exists
# (renamed/deleted in the framework). The src_prefix guard is load-bearing: without it this would
# delete a user's own dangling symlinks. It is a parameter, never inferred from target_dir.
prune_stale() {
    local src_prefix="$1" target_dir="$2" link src

    [ -d "${target_dir}" ] || return 0

    for link in "${target_dir}"/*; do
        [ -L "${link}" ] || continue
        src="$(readlink "${link}")"
        case "${src}" in
            "${src_prefix}"/*)
                if [ ! -e "${src}" ]; then
                    rm "${link}"
                    pruned=$((pruned + 1))
                fi
                ;;
        esac
    done
}

# Commands. Skip the README (documentation, not a command) and the attic (archived, never installed).
link_tree "${COMMANDS_DIR}" "${TARGET_DIR}" "README.md" "attic"
prune_stale "${COMMANDS_DIR}" "${TARGET_DIR}"

# Output styles (e.g. output-styles/director.md → ~/.claude/output-styles/director.md).
if [ -d "${STYLES_DIR}" ]; then
    link_tree "${STYLES_DIR}" "${STYLES_TARGET_DIR}" "README.md" "attic"
fi
# Pruned unconditionally, symmetrically with the commands tree: if the framework ever drops
# output-styles/ entirely, the installed symlinks must still be cleaned up rather than dangling
# forever. prune_stale is a no-op when the target dir is absent, and the src_prefix guard keeps
# a user's own symlinks safe.
prune_stale "${STYLES_DIR}" "${STYLES_TARGET_DIR}"

echo "Vault framework installed."
echo "  Linked:  ${linked}"
echo "  Skipped: ${skipped} (already correct)"
echo "  Pruned:  ${pruned} (stale symlinks removed)"
if [ -L "${STYLES_TARGET_DIR}/director.md" ]; then
    echo
    echo "Output style 'director' is available (answer-first, decision-ready writing)."
    echo "  Turn it on:  /config  ->  Output style  ->  director"
    echo "  Or set \"outputStyle\": \"director\" in ~/.claude/settings.json"
    echo "  Takes effect after /clear or in a new session."
fi
if [ "${refused}" -gt 0 ]; then
    echo "  Refused: ${refused} (see warnings above)" >&2
    exit 1
fi
