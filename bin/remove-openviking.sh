#!/usr/bin/env bash
# remove-openviking.sh — take OpenViking off this machine.
#
# The vault framework no longer uses OpenViking (see docs/removing-openviking.md).
# This script exists to unwire an install that predates that removal. It is
# independent of bin/vault-uninstall.sh: it touches ONLY OpenViking and leaves
# the vault framework, your vaults, and your repos alone.
#
# It removes, in layers, skipping whatever is already gone:
#   1. the openviking.service --user unit (stop, disable, delete, daemon-reload)
#   2. ~/.openviking/ov.conf + the plugin client config.json
#   3. the OPENVIKING_CC_CONFIG_FILE / OPENVIKING_CONFIG_FILE keys in
#      ~/.claude/settings.json
#   4. the claude-code-memory-plugin Claude Code plugin
#   5. (--tools) the `openviking` pipx package
#   6. (--purge-data) ~/.openviking in full, INCLUDING the indexed memory
#
# Not touched: ollama and the nomic-embed-text model. OpenViking was their only
# consumer here, so `ollama rm nomic-embed-text` is a reasonable optional
# follow-up, but plenty of people use ollama for other things.
#
# Flags:
#   --tools        also `pipx uninstall openviking`
#   --purge-data   also delete ~/.openviking including indexed data — DESTRUCTIVE
#   --all          --tools + --purge-data
#   --dry-run      print every action, change nothing
#   --yes, -y      consent non-interactively
#   -h, --help
#
# Without --yes (and with no terminal to confirm on) this only PRINTS the plan.
# Safe to run twice: every layer is skip-on-absent and the script exits 0.

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VAULT_SETUP_DRY_RUN="${VAULT_SETUP_DRY_RUN:-0}"

# shellcheck source=../lib/installers.sh
. "${VAULT_ROOT}/lib/installers.sh"

with_tools=0
purge_data=0
assume_yes=0
dry_run=0

usage() {
    cat <<'EOF'
remove-openviking.sh — take OpenViking off this machine.

Removes the --user service, ~/.openviking configs, the two OPENVIKING_* keys in
~/.claude/settings.json, and the claude-code-memory-plugin. Leaves the vault
framework, your vaults, your repos, and ollama alone.

  --tools        also `pipx uninstall openviking`
  --purge-data   also delete ~/.openviking including indexed data — DESTRUCTIVE
  --all          --tools + --purge-data
  --dry-run      print every action, change nothing
  --yes, -y      consent non-interactively
  -h, --help     this text

Without --yes and with no terminal to confirm on, this only prints the plan.
Safe to run twice.
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
# Consent
#------------------------------------------------------------------------------
what="This removes OpenViking from this machine"
[ "${with_tools}" -eq 1 ] && what="${what} + the openviking package"
[ "${purge_data}" -eq 1 ] && what="${what} + ALL indexed OpenViking data (irreversible)"
what="${what}."

CONSENT_MODE=""
consent_gate "${what}" "${dry_run}" "${assume_yes}"

#------------------------------------------------------------------------------
# Layers — each one skip-on-absent and non-fatal
#------------------------------------------------------------------------------
remove_service() {
    section "OpenViking service"
    local unit="${HOME}/.config/systemd/user/openviking.service"
    if have systemctl && systemctl --user show-environment >/dev/null 2>&1; then
        run systemctl --user disable --now openviking.service 2>/dev/null || true
    else
        info "no user systemd — nothing to stop"
    fi
    if [ -f "${unit}" ]; then
        run rm -f "${unit}"
        run systemctl --user daemon-reload 2>/dev/null || true
        ok "removed openviking.service unit"
    else
        info "already absent: openviking.service unit"
    fi
}

remove_configs() {
    section "OpenViking config"
    local conf="${HOME}/.openviking/ov.conf"
    local client="${HOME}/.openviking/claude-code-memory-plugin/config.json"
    local found=0
    [ -e "${conf}" ]   && { run rm -f "${conf}";   found=1; }
    [ -e "${client}" ] && { run rm -f "${client}"; found=1; }
    if [ "${found}" -eq 1 ]; then
        ok "removed ov.conf + plugin client config"
    else
        info "already absent: ov.conf + plugin client config"
    fi
}

# The jq/mv pair writes through a redirection, which run() cannot intercept —
# so this step branches on the dry-run flag by hand.
clean_settings_env() {
    section "Claude settings.json env"
    local f="${HOME}/.claude/settings.json"
    [ -f "${f}" ] || { info "already absent: settings.json"; return 0; }
    if ! have jq; then
        warn "jq missing — remove OPENVIKING_CC_CONFIG_FILE / OPENVIKING_CONFIG_FILE from ${f} by hand"
        return 0
    fi
    if ! jq -e '.env | has("OPENVIKING_CC_CONFIG_FILE") or has("OPENVIKING_CONFIG_FILE")' \
         "${f}" >/dev/null 2>&1; then
        info "already absent: OPENVIKING_* keys in settings.json"
        return 0
    fi
    if [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; then
        printf '  [dry-run] jq del .env.OPENVIKING_CC_CONFIG_FILE/.OPENVIKING_CONFIG_FILE in %s\n' "${f}"
        return 0
    fi
    local tmp; tmp="$(mktemp)"
    if jq 'if .env then .env |= del(.OPENVIKING_CC_CONFIG_FILE, .OPENVIKING_CONFIG_FILE) else . end
           | if (.env) == {} then del(.env) else . end' "${f}" > "${tmp}" 2>/dev/null; then
        mv "${tmp}" "${f}"; ok "removed OPENVIKING_* keys from settings.json"
    else
        rm -f "${tmp}"; warn "could not edit ${f} — remove the keys by hand"
    fi
}

remove_plugin() {
    section "Claude Code plugin"
    if ! claude_cli_ok; then
        info "claude CLI unavailable — uninstall claude-code-memory-plugin by hand"
        return 0
    fi
    if run claude plugin uninstall claude-code-memory-plugin@openviking-plugin 2>/dev/null; then
        ok "removed the OpenViking plugin (marketplace left intact)"
    else
        warn "plugin uninstall did not succeed — remove claude-code-memory-plugin by hand"
    fi
}

remove_package() {
    section "OpenViking package"
    if ! have pipx; then info "no pipx — nothing to uninstall"; return 0; fi
    run pipx uninstall openviking 2>/dev/null || true
    ok "removed the openviking pipx package"
}

purge_ov_data() {
    section "Purge OpenViking data (DESTRUCTIVE)"
    warn "deleting the indexed memory — this cannot be undone"
    safe_rm_under_home "${HOME}/.openviking" || return 0
    ok "purged ${HOME}/.openviking"
    info "your vault markdown was NOT touched — only the index built from it"
}

#------------------------------------------------------------------------------
# Run
#------------------------------------------------------------------------------
remove_service
remove_configs
clean_settings_env
remove_plugin
if [ "${with_tools}" -eq 1 ]; then remove_package; fi
if [ "${purge_data}" -eq 1 ]; then purge_ov_data; fi

section "Done"
if [ "${CONSENT_MODE}" = "plan-only" ]; then
    warn "Nothing was changed. Re-run with --yes to apply, or --dry-run to preview."
else
    info "Restart Claude Code so the removed plugin unloads."
    if [ "${purge_data}" -eq 0 ]; then
        info "Data kept. Re-run with --purge-data to also delete ~/.openviking."
    fi
    info "Optional: 'ollama rm nomic-embed-text' — OpenViking was its only consumer here."
fi

# Explicit: the layered `if` blocks above must not decide this script's status.
exit 0
