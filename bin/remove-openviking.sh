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
#   3. the OPENVIKING_CC_CONFIG_FILE / OPENVIKING_CONFIG_FILE keys, the enabled
#      plugin entry, and the marketplace entry in every Claude config dir
#   4. the claude-code-memory-plugin plugin + marketplace, per config dir
#
# "Every config dir" matters: a second Claude home (CLAUDE_CONFIG_DIR pointing
# somewhere like ~/workspace/.claude-work) keeps its own settings.json and its
# own plugin registry. Cleaning only ~/.claude leaves that one loading the
# plugin, whose UserPromptSubmit hook then errors on the config file layer 2
# just deleted. Layer 7 sweeps for config dirs this run did not visit.
#   5. (--tools) the `openviking` pipx package
#   6. (--purge-data) ~/.openviking in full, INCLUDING the indexed memory
#
# Not touched: ollama and the nomic-embed-text model. OpenViking was their only
# consumer here, so `ollama rm nomic-embed-text` is a reasonable optional
# follow-up, but plenty of people use ollama for other things.
#
# Flags:
#   --config-dir D  also clean Claude config dir D (repeatable)
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
extra_config_dirs=()

usage() {
    cat <<'EOF'
remove-openviking.sh — take OpenViking off this machine.

Removes the --user service, ~/.openviking configs, the OPENVIKING_* keys and the
plugin + marketplace entries from every Claude config dir it can see, and the
claude-code-memory-plugin itself. Leaves the vault framework, your vaults, your
repos, and ollama alone.

Config dirs cleaned: $CLAUDE_CONFIG_DIR (if set), ~/.claude, and any --config-dir
you pass. Anything else still referencing OpenViking is reported at the end.

  --config-dir D also clean Claude config dir D (repeatable)
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
        --config-dir)
            [ $# -ge 2 ] || { echo "--config-dir needs a path" >&2; exit 2; }
            extra_config_dirs+=("$2"); shift ;;
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
# Config dirs — a machine can have several Claude homes, each with its own
# settings.json and plugin registry. Deduplicated, existing dirs only.
#------------------------------------------------------------------------------
CONFIG_DIRS=()
collect_config_dirs() {
    local candidate seen
    for candidate in "${CLAUDE_CONFIG_DIR:-}" "${HOME}/.claude" "${extra_config_dirs[@]+"${extra_config_dirs[@]}"}"; do
        [ -n "${candidate}" ] || continue
        [ -d "${candidate}" ] || continue
        for seen in "${CONFIG_DIRS[@]+"${CONFIG_DIRS[@]}"}"; do
            [ "${seen}" = "${candidate}" ] && continue 2
        done
        CONFIG_DIRS+=("${candidate}")
    done
}

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
clean_one_settings() {
    local f="$1/settings.json"
    [ -f "${f}" ] || { info "already absent: ${f}"; return 0; }
    if ! have jq; then
        warn "jq missing — remove the OPENVIKING_* keys, the enabledPlugins entry and the marketplace entry from ${f} by hand"
        return 0
    fi
    if ! jq -e '(.env // {} | has("OPENVIKING_CC_CONFIG_FILE") or has("OPENVIKING_CONFIG_FILE"))
                or ((.enabledPlugins // {}) | keys | any(test("openviking")))
                or ((.extraKnownMarketplaces // {}) | has("openviking-plugin"))' \
         "${f}" >/dev/null 2>&1; then
        info "already clean: ${f}"
        return 0
    fi
    if [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; then
        printf '  [dry-run] jq del OPENVIKING_* env keys + openviking plugin/marketplace entries in %s\n' "${f}"
        return 0
    fi
    local tmp; tmp="$(mktemp)"
    if jq 'if .env then .env |= del(.OPENVIKING_CC_CONFIG_FILE, .OPENVIKING_CONFIG_FILE) else . end
           | if (.env) == {} then del(.env) else . end
           | if .enabledPlugins then
                 .enabledPlugins |= with_entries(select(.key | test("openviking") | not))
             else . end
           | if .extraKnownMarketplaces then
                 .extraKnownMarketplaces |= del(."openviking-plugin")
             else . end' "${f}" > "${tmp}" 2>/dev/null; then
        mv "${tmp}" "${f}"; ok "cleaned ${f}"
    else
        rm -f "${tmp}"; warn "could not edit ${f} — remove the entries by hand"
    fi
}

clean_settings_env() {
    section "Claude settings.json"
    local dir
    for dir in "${CONFIG_DIRS[@]+"${CONFIG_DIRS[@]}"}"; do
        clean_one_settings "${dir}"
    done
}

remove_plugin() {
    section "Claude Code plugin"
    if ! claude_cli_ok; then
        info "claude CLI unavailable — uninstall claude-code-memory-plugin by hand"
        return 0
    fi
    # The CLI edits whichever registry CLAUDE_CONFIG_DIR names, so it has to be
    # driven once per config dir. Both calls are no-ops when already removed.
    local dir
    for dir in "${CONFIG_DIRS[@]+"${CONFIG_DIRS[@]}"}"; do
        if run env CLAUDE_CONFIG_DIR="${dir}" claude plugin uninstall \
               claude-code-memory-plugin@openviking-plugin 2>/dev/null; then
            ok "removed the OpenViking plugin from ${dir}"
        else
            info "no OpenViking plugin to remove in ${dir}"
        fi
        if run env CLAUDE_CONFIG_DIR="${dir}" claude plugin marketplace remove \
               openviking-plugin 2>/dev/null; then
            ok "removed the OpenViking marketplace from ${dir}"
        else
            info "no OpenViking marketplace to remove in ${dir}"
        fi
    done
}

# Anything this run did not visit — a second Claude home under another path —
# is reported, not touched: the script cannot know it is safe to edit.
scan_stray_configs() {
    section "Stray config dirs"
    local visited=" ${CONFIG_DIRS[*]+${CONFIG_DIRS[*]}} "
    local found=0 f dir
    while IFS= read -r f; do
        dir="$(dirname "${f}")"
        case "${visited}" in *" ${dir} "*) continue ;; esac
        grep -qi openviking "${f}" 2>/dev/null || continue
        warn "still references OpenViking: ${f}"
        info "  re-run with --config-dir ${dir}"
        found=1
    done < <(find "${HOME}" -maxdepth 4 -name settings.json -path '*claude*' \
                  -not -path '*/plugins/*' -not -path '*/node_modules/*' 2>/dev/null)
    [ "${found}" -eq 0 ] && ok "no other config dir references OpenViking"
    return 0
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
collect_config_dirs
remove_service
remove_configs
clean_settings_env
remove_plugin
if [ "${with_tools}" -eq 1 ]; then remove_package; fi
if [ "${purge_data}" -eq 1 ]; then purge_ov_data; fi
scan_stray_configs

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
