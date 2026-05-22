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

echo "Vault framework installed."
echo "  Linked:  ${linked}"
echo "  Skipped: ${skipped} (already correct)"
if [ "${refused}" -gt 0 ]; then
    echo "  Refused: ${refused} (see warnings above)" >&2
    exit 1
fi
