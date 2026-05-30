#!/usr/bin/env bash
# Install vault framework commands into ~/.claude/commands/.
# Idempotent. Refuses to overwrite non-symlink files.
set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.claude/commands"
COMMANDS_DIR="${VAULT_ROOT}/commands"

mkdir -p "${TARGET_DIR}"

linked=0
skipped=0
refused=0

for src in "${COMMANDS_DIR}"/*.md; do
    [ -f "${src}" ] || continue
    name="$(basename "${src}")"

    # Skip the commands README, it's documentation not a command.
    [ "${name}" = "README.md" ] && continue

    target="${TARGET_DIR}/${name}"

    if [ -L "${target}" ]; then
        current="$(readlink "${target}")"
        if [ "${current}" = "${src}" ]; then
            skipped=$((skipped + 1))
            continue
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
done

# Symlink command subdirectories too (e.g. commands/v-work/ → ~/.claude/commands/v-work/).
# A command may ship its step/ref files in a sibling directory; the dispatcher references them at
# the stable global path ~/.claude/commands/<cmd>/... so they resolve from any project.
for src in "${COMMANDS_DIR}"/*/; do
    src="${src%/}"
    [ -d "${src}" ] || continue
    name="$(basename "${src}")"
    target="${TARGET_DIR}/${name}"

    if [ -L "${target}" ]; then
        current="$(readlink "${target}")"
        if [ "${current}" = "${src}" ]; then
            skipped=$((skipped + 1))
            continue
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
done

pruned=0
# Prune stale symlinks: any symlink in TARGET_DIR pointing into our COMMANDS_DIR whose source no
# longer exists (renamed/deleted in framework). Covers both command files and command subdirs.
for link in "${TARGET_DIR}"/*; do
    [ -L "${link}" ] || continue
    src="$(readlink "${link}")"
    case "${src}" in
        "${COMMANDS_DIR}"/*)
            if [ ! -e "${src}" ]; then
                rm "${link}"
                pruned=$((pruned + 1))
            fi
            ;;
    esac
done

echo "Vault framework installed."
echo "  Linked:  ${linked}"
echo "  Skipped: ${skipped} (already correct)"
echo "  Pruned:  ${pruned} (stale symlinks removed)"
if [ "${refused}" -gt 0 ]; then
    echo "  Refused: ${refused} (see warnings above)" >&2
    exit 1
fi
