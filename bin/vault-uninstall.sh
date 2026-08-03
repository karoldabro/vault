#!/usr/bin/env bash
# Reverse what setup.sh / install.sh wired up — safely and in layers.
#
# By default removes only the FRAMEWORK WIRING (reversible, no data loss):
#   * command symlinks in ~/.claude/commands/ that point into this repo
#   * the claude-mem Claude Code plugin
#
# Opt-in extras:
#   --tools        also uninstall the vault-specific tools (graphifyy, serena-agent).
#                  NEVER touches shared toolchains (uv/bun/node).
#   --purge-data   also delete $VAULT_HOME/_global — DESTRUCTIVE.
#   --all          --tools + --purge-data.
#
# OpenViking is no longer part of this framework. To remove an install that
# predates that change, use bin/remove-openviking.sh (see docs/removing-openviking.md).
#
# Safety: destructive actions need consent. Without --yes (and without a TTY to
# confirm on) this only PRINTS the plan and changes nothing. Project vaults
# (~/vault/<slug>/, in-repo vault/) and your repos are never touched.
#
#   --dry-run  echo every action instead of running it
#   --yes, -y  consent non-interactively
#   -h, --help

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_HOME="${VAULT_HOME:-${HOME}/vault}"
export VAULT_SETUP_DRY_RUN="${VAULT_SETUP_DRY_RUN:-0}"

# shellcheck source=../lib/installers.sh
. "${VAULT_ROOT}/lib/installers.sh"

with_tools=0
purge_data=0
assume_yes=0
dry_run=0

usage() {
    cat <<'EOF'
vault-uninstall.sh — reverse what setup.sh / install.sh wired up, in layers.

By default removes only the framework wiring (reversible, no data loss):
the command symlinks in ~/.claude/commands/ that point into this repo, and
the claude-mem Claude Code plugin.

  --tools        also uninstall graphifyy + serena-agent (never uv/bun/node)
  --purge-data   also delete $VAULT_HOME/_global — DESTRUCTIVE
  --all          --tools + --purge-data
  --dry-run      echo every action instead of running it
  --yes, -y      consent non-interactively
  -h, --help     this text

OpenViking is no longer part of this framework. To remove an install that
predates that change, use bin/remove-openviking.sh.

Project vaults (~/vault/<slug>/, in-repo vault/) and your repos are never touched.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --tools)      with_tools=1 ;;
        --purge-data) purge_data=1 ;;
        --all)        with_tools=1; purge_data=1 ;;
        --dry-run)    dry_run=1 ;;
        --yes|-y)     assume_yes=1 ;;
        -h|--help)    usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

#------------------------------------------------------------------------------
# Consent → decide whether we actually apply or just echo the plan.
#------------------------------------------------------------------------------
what="This removes the vault framework wiring"
[ "${with_tools}" -eq 1 ] && what="${what} + tools"
[ "${purge_data}" -eq 1 ] && what="${what} + the _global machine config"
what="${what}."

CONSENT_MODE=""
consent_gate "${what}" "${dry_run}" "${assume_yes}"

#------------------------------------------------------------------------------
# Steps
#------------------------------------------------------------------------------
remove_command_symlinks() {
    section "Command symlinks"
    local target_dir="${HOME}/.claude/commands" link src n=0
    [ -d "${target_dir}" ] || { info "no ${target_dir}"; return 0; }
    for link in "${target_dir}"/*; do
        [ -L "${link}" ] || continue
        src="$(readlink "${link}")"
        case "${src}" in
            "${VAULT_ROOT}/commands"/*) run rm -f "${link}"; n=$((n + 1)) ;;
        esac
    done
    ok "removed ${n} command symlink(s) → ${VAULT_ROOT}/commands"
}


remove_plugins() {
    section "Claude Code plugins"
    if ! claude_cli_ok; then info "claude CLI unavailable — uninstall plugins manually"; return 0; fi
    # The qualified id is claude-mem@thedotmack (marketplace.json declares the
    # marketplace name "thedotmack") — claude-mem@claude-mem silently no-ops.
    run claude plugin uninstall claude-mem@thedotmack 2>/dev/null || true
    ok "removed the claude-mem plugin (marketplace left intact)"
}

remove_tools() {
    section "Vault tools"
    if have pipx; then
        run pipx uninstall graphifyy 2>/dev/null || true
    fi
    have uv && { run uv tool uninstall serena-agent 2>/dev/null || true; }
    ok "removed graphifyy, serena-agent — left uv/bun/node intact"
}

purge_vault_data() {
    section "Purge data (DESTRUCTIVE)"
    warn "deleting the machine config — this cannot be undone"
    # VAULT_HOME defaults to ${HOME}/vault but may be overridden anywhere, so the
    # under-HOME guard doesn't apply. Assert the path is absolute and has a real
    # parent — with an empty HOME the default expands to the bare "/vault/_global".
    case "${VAULT_HOME}" in
        /|""|/_global) warn "VAULT_HOME is '${VAULT_HOME}' — refusing to delete"; return 0 ;;
        /*) ;;
        *) warn "VAULT_HOME '${VAULT_HOME}' is not an absolute path — refusing to delete"; return 0 ;;
    esac
    if [ -z "${HOME:-}" ] && [ "${VAULT_HOME}" = "/vault" ]; then
        warn "HOME is empty, so VAULT_HOME resolved to '/vault' — refusing to delete"; return 0
    fi
    run rm -rf "${VAULT_HOME}/_global"
    ok "purged ${VAULT_HOME}/_global"
    info "project vaults (~/vault/<slug>/, in-repo vault/) were NOT touched"
}

#------------------------------------------------------------------------------
# Run
#------------------------------------------------------------------------------
remove_command_symlinks
remove_plugins
if [ "${with_tools}" -eq 1 ]; then remove_tools; fi
if [ "${purge_data}" -eq 1 ]; then purge_vault_data; fi

section "Done"
if [ "${CONSENT_MODE}" = "plan-only" ]; then
    warn "Nothing was changed (no consent). Re-run with --yes to apply, or --dry-run to preview."
else
    info "Restart Claude Code so the removed plugins/MCP unload."
    if [ "${purge_data}" -eq 0 ]; then
        info "Data kept. Re-run with --purge-data to also delete _global."
    fi
fi
exit 0
