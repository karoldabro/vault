#!/usr/bin/env bash
# Install vault framework commands into ~/.claude/commands/ and output styles into
# ~/.claude/output-styles/.
# Idempotent. Refuses to overwrite non-symlink files.
#
# Usage:  install.sh [--enable-style] [--enable-doc-lint] [--enable-brevity] [--enable-all]
#
# Linking a file and switching it on are separate steps, and the default is to link only. The
# director output style shipped on 2026-08-03 and was active in 0 of 18 projects eighteen days
# later, because "we printed the instructions" is not a mechanism. The flags below make turning it
# on one command instead of a hand-edited JSON file — still opt-in, still never silent.
set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

enable_style=0
enable_doclint=0
enable_brevity=0
while [ $# -gt 0 ]; do
    case "$1" in
        --enable-style)     enable_style=1; shift ;;
        --enable-doc-lint)  enable_doclint=1; shift ;;
        --enable-brevity)   enable_brevity=1; shift ;;
        --enable-all)       enable_style=1; enable_doclint=1; enable_brevity=1; shift ;;
        -h|--help)          sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)                  echo "install.sh: unknown option $1" >&2; exit 2 ;;
    esac
done

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
HOOKS_TARGET_DIR="${HOME}/.claude/hooks"

# The hooks this framework ships, as data. Adding one is a row here, not five edits scattered
# through the file. Semicolon-separated because a matcher legitimately contains a pipe.
# Fields: script ; flag group ; Claude Code event ; matcher ; off-switch ; one-line description.
#
# A plugin install reads hooks/hooks.json and needs none of this; a symlink install has no
# manifest, so the scripts are linked here and registered only behind their flag.
HOOK_ROWS=(
  "doc-lint-hook.sh;doclint;PostToolUse;Write|Edit|MultiEdit;DOC_LINT;checks every markdown document Claude writes and hands the findings back to it"
  "output-lint-hook.sh;brevity;Stop;;BREVITY;measures the length of every reply and records it"
  "brevity-reminder-hook.sh;brevity;UserPromptSubmit;;BREVITY;says what your previous reply overran, and stays silent when nothing did"
)

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

# Link every shipped hook. Linking is not activating: registering a hook means editing
# settings.json, which happens below and only behind a flag.
for _row in "${HOOK_ROWS[@]}"; do
    IFS=';' read -r _script _flag _event _matcher _envvar _desc <<< "${_row}"
    if [ -f "${VAULT_ROOT}/scripts/${_script}" ]; then
        mkdir -p "${HOOKS_TARGET_DIR}"
        ln -sfn "${VAULT_ROOT}/scripts/${_script}" "${HOOKS_TARGET_DIR}/${_script}"
    fi
done

# --- opt-in activation -------------------------------------------------------------------------
# Both of these edit ~/.claude/settings.json, which is yours, not the framework's. They run only
# when you asked for them by flag, they back the file up first, and they are idempotent.
SETTINGS="${HOME}/.claude/settings.json"

edit_settings() {   # edit_settings <python-snippet> <description>
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  Cannot edit ${SETTINGS}: python3 not found. Edit it by hand." >&2
        return 1
    fi
    mkdir -p "$(dirname "${SETTINGS}")"
    [ -f "${SETTINGS}" ] || echo '{}' > "${SETTINGS}"
    cp "${SETTINGS}" "${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
    python3 - "${SETTINGS}" <<PYEOF || { echo "  Failed to edit ${SETTINGS}; backup kept." >&2; return 1; }
import json, sys
p = sys.argv[1]
d = json.load(open(p))
${1}
json.dump(d, open(p, "w"), indent=2)
PYEOF
    echo "  ${2}"
}

if [ "${enable_style}" -eq 1 ]; then
    edit_settings 'd["outputStyle"] = "director"' \
        "Output style 'director' switched on globally (takes effect in a new session)." || true
fi

# Register the hooks whose flag was given. The membership test keeps this idempotent and leaves
# every entry the user already had — including unrelated Stop hooks — in place.
for _row in "${HOOK_ROWS[@]}"; do
    IFS=';' read -r _script _flag _event _matcher _envvar _desc <<< "${_row}"
    case "${_flag}" in
        doclint) [ "${enable_doclint}" -eq 1 ] || continue ;;
        brevity) [ "${enable_brevity}" -eq 1 ] || continue ;;
        *)       continue ;;
    esac
    [ -f "${VAULT_ROOT}/scripts/${_script}" ] || continue
    # The row's values reach Python as JSON, never pasted into its source: a matcher containing a
    # quote would otherwise break the settings edit and look like a settings problem.
    HOOK_ROW_JSON="$(printf '{"script":%s,"event":%s,"matcher":%s}' \
        "\"${_script}\"" "\"${_event}\"" "\"${_matcher}\"")"
    export HOOK_ROW_JSON
    edit_settings '
import os
row = json.loads(os.environ["HOOK_ROW_JSON"])
hooks = d.setdefault("hooks", {})
bucket = hooks.setdefault(row["event"], [])
if not any(row["script"] in json.dumps(e) for e in bucket):
    entry = {"hooks": [{"type": "command",
                        "command": "$HOME/.claude/hooks/" + row["script"]}]}
    if row["matcher"]:
        entry["matcher"] = row["matcher"]
    bucket.append(entry)
' "Switched on: ${_script} — ${_desc} (${_envvar}=off disables it)." || true
done

echo "Vault framework installed."
echo "  Linked:  ${linked}"
echo "  Skipped: ${skipped} (already correct)"
echo "  Pruned:  ${pruned} (stale symlinks removed)"
if [ -L "${STYLES_TARGET_DIR}/director.md" ] && [ "${enable_style}" -eq 0 ] \
   && ! grep -q '"outputStyle"' "${SETTINGS}" 2>/dev/null; then
    echo
    echo "Output style 'director' is available (answer-first, decision-ready writing)."
    echo "  Turn it on:  install.sh --enable-style"
    echo "  Or:          /config  ->  Output style  ->  director"
    echo "  By hand:     \"outputStyle\": \"director\" in ~/.claude/settings.json"
    echo "  Takes effect in a new session."
fi
for _row in "${HOOK_ROWS[@]}"; do
    IFS=';' read -r _script _flag _event _matcher _envvar _desc <<< "${_row}"
    [ -L "${HOOKS_TARGET_DIR}/${_script}" ] || continue
    grep -q "${_script}" "${SETTINGS}" 2>/dev/null && continue
    case "${_flag}" in
        doclint) _turn_on="install.sh --enable-doc-lint" ;;
        brevity) _turn_on="install.sh --enable-brevity" ;;
        *)       _turn_on="install.sh --enable-all" ;;
    esac
    echo
    echo "${_script} is installed but not switched on."
    echo "  It ${_desc}."
    echo "  It never blocks and never prompts you."
    echo "  Turn it on:  ${_turn_on}"
    echo "  Turn it off any time with ${_envvar}=off."
done
if [ "${refused}" -gt 0 ]; then
    echo "  Refused: ${refused} (see warnings above)" >&2
    exit 1
fi
