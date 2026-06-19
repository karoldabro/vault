#!/usr/bin/env bash
# Reverse what setup.sh / install.sh wired up — safely and in layers.
#
# By default removes only the FRAMEWORK WIRING (reversible, no data loss):
#   * command symlinks in ~/.claude/commands/ that point into this repo
#   * the OpenViking --user service (stop + disable + remove the unit)
#   * ov.conf + the plugin client config.json   (NOT ~/.openviking/data)
#   * the two OPENVIKING_*_CONFIG_FILE keys in ~/.claude/settings.json
#   * the OpenViking + claude-mem Claude Code plugins
#
# Opt-in extras:
#   --tools        also uninstall the vault-specific tools (openviking, graphifyy,
#                  serena-agent). NEVER touches shared toolchains (ollama/uv/bun/node).
#   --purge-data   also delete ~/.openviking (incl. indexed memory) and
#                  $VAULT_HOME/_global — DESTRUCTIVE.
#   --all          --tools + --purge-data.
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
    sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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
not_consented=0
if [ "${dry_run}" -eq 1 ]; then
    export VAULT_SETUP_DRY_RUN=1
elif [ "${assume_yes}" -eq 1 ]; then
    export VAULT_SETUP_DRY_RUN=0
else
    printf '\nThis removes the vault framework wiring'
    [ "${with_tools}" -eq 1 ] && printf ' + tools'
    [ "${purge_data}" -eq 1 ] && printf ' + ALL OpenViking data'
    printf '.\nProceed? [y/N] '
    reply=""
    if read -r reply </dev/tty 2>/dev/null && { [ "${reply}" = "y" ] || [ "${reply}" = "Y" ]; }; then
        export VAULT_SETUP_DRY_RUN=0
    else
        export VAULT_SETUP_DRY_RUN=1; not_consented=1
    fi
fi

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

remove_ov_service() {
    section "OpenViking service"
    local unit="${HOME}/.config/systemd/user/openviking.service"
    if have systemctl && systemctl --user show-environment >/dev/null 2>&1; then
        run systemctl --user disable --now openviking.service 2>/dev/null || true
    fi
    if [ -f "${unit}" ]; then
        run rm -f "${unit}"
        run systemctl --user daemon-reload 2>/dev/null || true
        ok "removed openviking.service unit"
    else
        info "no openviking.service unit"
    fi
}

remove_ov_configs() {
    section "OpenViking config"
    run rm -f "${HOME}/.openviking/ov.conf" "${HOME}/.openviking/claude-code-memory-plugin/config.json"
    ok "removed ov.conf + plugin client config (kept ${HOME}/.openviking/data)"
}

clean_settings_env() {
    section "Claude settings.json env"
    local f="${HOME}/.claude/settings.json"
    [ -f "${f}" ] || { info "no settings.json"; return 0; }
    if ! have jq; then warn "jq missing — remove OPENVIKING_*_CONFIG_FILE from ${f} manually"; return 0; fi
    if [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; then
        printf '  [dry-run] jq del .env.OPENVIKING_CC_CONFIG_FILE/.OPENVIKING_CONFIG_FILE in %s\n' "${f}"
        return 0
    fi
    local tmp; tmp="$(mktemp)"
    if jq 'if .env then .env |= del(.OPENVIKING_CC_CONFIG_FILE, .OPENVIKING_CONFIG_FILE) else . end
           | if (.env) == {} then del(.env) else . end' "${f}" > "${tmp}" 2>/dev/null; then
        mv "${tmp}" "${f}"; ok "removed OPENVIKING_*_CONFIG_FILE from settings.json"
    else
        rm -f "${tmp}"; warn "could not edit ${f} — remove the keys manually"
    fi
}

remove_plugins() {
    section "Claude Code plugins"
    if ! claude_cli_ok; then info "claude CLI unavailable — uninstall plugins manually"; return 0; fi
    run claude plugin uninstall claude-code-memory-plugin@openviking-plugin 2>/dev/null || true
    run claude plugin uninstall claude-mem@claude-mem 2>/dev/null || true
    ok "removed OV + claude-mem plugins (marketplaces left intact)"
}

remove_tools() {
    section "Vault tools"
    if have pipx; then
        run pipx uninstall openviking 2>/dev/null || true
        run pipx uninstall graphifyy 2>/dev/null || true
    fi
    have uv && { run uv tool uninstall serena-agent 2>/dev/null || true; }
    ok "removed openviking, graphifyy, serena-agent — left ollama/uv/bun/node intact"
}

purge_vault_data() {
    section "Purge data (DESTRUCTIVE)"
    warn "deleting indexed memory + machine config — this cannot be undone"
    run rm -rf "${HOME}/.openviking" "${VAULT_HOME}/_global"
    ok "purged ${HOME}/.openviking and ${VAULT_HOME}/_global"
    info "project vaults (~/vault/<slug>/, in-repo vault/) were NOT touched"
}

#------------------------------------------------------------------------------
# Run
#------------------------------------------------------------------------------
remove_command_symlinks
remove_ov_service
remove_ov_configs
clean_settings_env
remove_plugins
[ "${with_tools}" -eq 1 ] && remove_tools
[ "${purge_data}" -eq 1 ] && purge_vault_data

section "Done"
if [ "${not_consented}" -eq 1 ]; then
    warn "Nothing was changed (no consent). Re-run with --yes to apply, or --dry-run to preview."
else
    info "Restart Claude Code so the removed plugins/MCP unload."
    [ "${purge_data}" -eq 0 ] && info "Data kept. Re-run with --purge-data to also delete ~/.openviking + _global."
fi
exit 0
