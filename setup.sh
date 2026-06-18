#!/usr/bin/env bash
# Umbrella installer for the vault knowledge-framework stack.
#
# On Ubuntu (apt + sudo present) this AUTO-INSTALLS the whole tool stack and
# onboards it. Elsewhere — or without consent — it degrades to printing the exact
# commands to run (the old "hint" behaviour), and never halts.
#
# Responsibilities (idempotent):
#   1. Verify / auto-install base prereqs (git, curl, jq, ca-certificates, unzip).
#   2. Create the machine-layer dir (~/vault/_global/), config.md, coupled-groups.md.
#   3. Detect Obsidian (hint only).
#   4. OpenViking (--with-ov): ollama + nomic-embed-text + ov.conf + OV plugin.
#   5. Serena (--with-serena): uv + serena-agent.
#   6. claude-mem (--with-claude-mem): bun + claude-mem plugin.
#   7. Graphify (--with-graphify): pipx + graphifyy.
#   8. Print per-repo onboarding instructions (vault-init).
#   9. Run install.sh to symlink slash commands.
#  10. Doctor pass — verify what landed; non-zero exit only if a required tool failed.
#
# Use --full to wire every tool in one pass. On a real Ubuntu workstation that is
# the one-command install. Pass --yes to consent non-interactively (CI/automation).
#
# Auto-install runs remote installers (ollama/uv/bun via the vendors' official
# curl|sh scripts) and adds third-party Claude marketplaces — every source URL is
# printed before it runs. See vault/decisions/ADR-005-installer-auto-exec.md.
#
# Environment overrides (used by tests; safe to ignore in real use):
#   VAULT_HOME              default: $HOME/vault
#   SETUP_SKIP_INSTALL_SH   default: 0 — set to 1 to skip calling install.sh
#   VAULT_SETUP_DRY_RUN     default: 0 — set to 1 (or pass --dry-run) to echo every
#                           side-effecting command instead of executing it

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_HOME="${VAULT_HOME:-${HOME}/vault}"
SETUP_SKIP_INSTALL_SH="${SETUP_SKIP_INSTALL_SH:-0}"
export VAULT_SETUP_DRY_RUN="${VAULT_SETUP_DRY_RUN:-0}"

# shellcheck source=lib/installers.sh
. "${VAULT_ROOT}/lib/installers.sh"

with_ov=0
with_serena=0
with_claude_mem=0
with_graphify=0
minimal=0
assume_yes=0
doctor_only=0

usage() {
    cat <<EOF
Usage: $0 [flags]

Tool flags (wire all with --full):
  --with-ov           OpenViking: ollama + nomic-embed-text + ov.conf + OV plugin.
  --with-serena       Serena language server (uv + serena-agent).
  --with-claude-mem   claude-mem mcp-search plugin (bun + claude-mem).
  --with-graphify     Graphify (pipx + graphifyy).
  --full              Shorthand for all of the above.

Behaviour:
  --minimal           Skip all tool wiring (base scaffold only).
  --yes, -y           Consent to auto-install non-interactively (no prompt).
  --dry-run           Echo every side-effecting command instead of running it.
  --doctor            Only run the tool-health check, then exit.
  -h, --help          Show this help.

On Ubuntu (apt + sudo) tools are installed automatically once consented; elsewhere
the exact install commands are printed instead. Re-run anytime; it is idempotent.

Examples:
  $0 --minimal
  $0 --full --yes
  $0 --full --dry-run
  $0 --doctor
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --with-ov)         with_ov=1 ;;
        --with-serena)     with_serena=1 ;;
        --with-claude-mem) with_claude_mem=1 ;;
        --with-graphify)   with_graphify=1 ;;
        --full)            with_ov=1; with_serena=1; with_claude_mem=1; with_graphify=1 ;;
        --minimal)         minimal=1 ;;
        --yes|-y)          assume_yes=1 ;;
        --dry-run)         export VAULT_SETUP_DRY_RUN=1; assume_yes=1 ;;
        --doctor)          doctor_only=1 ;;
        -h|--help)         usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [ "${doctor_only}" -eq 1 ]; then
    doctor
    exit $?
fi

if [ "${minimal}" -eq 1 ]; then
    with_ov=0
    with_serena=0
    with_claude_mem=0
    with_graphify=0
fi

any_tool=$(( with_ov + with_serena + with_claude_mem + with_graphify ))

#------------------------------------------------------------------------------
# Decide the install mode: AUTO (real install) vs HINT (print commands).
#------------------------------------------------------------------------------
# AUTO requires: a selected tool, apt + sudo (Ubuntu), and consent. Dry-run counts
# as AUTO (it walks the real code path, just echoing). No TTY and no --yes → no
# consent → degrade to hints rather than hang.
auto=0
auto_reason=""
if [ "${any_tool}" -gt 0 ]; then
    if [ "${VAULT_SETUP_DRY_RUN}" = "1" ]; then
        auto=1; auto_reason="dry-run"
    elif ! apt_available; then
        auto_reason="no apt (non-Ubuntu) — printing install hints"
    elif ! sudo_available; then
        auto_reason="no passwordless sudo — printing install hints"
    elif [ "${assume_yes}" -eq 1 ]; then
        auto=1; auto_reason="consented via --yes"
    else
        # Interactive consent.
        printf '\nAuto-install will run vendor install scripts (ollama/uv/bun) and add\n'
        printf 'third-party Claude marketplaces. Sources are printed as they run.\n'
        printf 'Proceed with auto-install? [y/N] '
        reply=""
        if read -r reply </dev/tty 2>/dev/null && { [ "${reply}" = "y" ] || [ "${reply}" = "Y" ]; }; then
            auto=1; auto_reason="consented interactively"
        else
            auto_reason="declined / no TTY — printing install hints"
        fi
    fi
fi

#------------------------------------------------------------------------------
# Step 1 — Base prerequisites
#------------------------------------------------------------------------------
section "Prerequisites"

base_pkgs="git curl jq ca-certificates unzip"
missing_base=0
for cmd in git curl jq; do
    if have "${cmd}"; then ok "${cmd}"; else missing_base=$((missing_base + 1)); fi
done

if [ "${missing_base}" -gt 0 ]; then
    if [ "${auto}" -eq 1 ]; then
        info "installing base prerequisites via apt"
        run $(_priv) apt-get update || true
        # shellcheck disable=SC2086
        apt_install ${base_pkgs} || true
        missing_base=0
        for cmd in git curl jq; do have "${cmd}" || missing_base=$((missing_base + 1)); done
    fi
    if [ "${missing_base}" -gt 0 ]; then
        warn "${missing_base} base prereqs missing; install git/curl/jq and re-run."
        exit 1
    fi
fi

#------------------------------------------------------------------------------
# Step 2 — Machine-layer directory  (pure-local scaffold — never via run())
#------------------------------------------------------------------------------
section "Machine layer (${VAULT_HOME})"

mkdir -p "${VAULT_HOME}/_global"
ok "${VAULT_HOME}/_global/"

config_md="${VAULT_HOME}/_global/config.md"
if [ -f "${config_md}" ]; then
    ok "config.md present"
else
    cat > "${config_md}" <<EOF
---
type: machine-config
tags: [config]
---

# Machine vault config (local-only)

Global defaults for vault commands. A repo's \`VAULT.md\` overrides these per-repo.

## config
framework_path: ${VAULT_ROOT}
vault_home: ${VAULT_HOME}
EOF
    ok "wrote ${config_md}"
fi

coupled="${VAULT_HOME}/_global/coupled-groups.md"
if [ -f "${coupled}" ]; then
    ok "coupled-groups.md present"
else
    cat > "${coupled}" <<'EOF'
# Coupled project groups

Projects listed in the same group share memory recall. One project per line within a group; one blank line between groups.

<!-- Example
group: vivi
- vivi-api
- vivi-admin
- vivi-contracts
-->
EOF
    ok "wrote ${coupled}"
fi

#------------------------------------------------------------------------------
# Step 3 — Obsidian (detection only)
#------------------------------------------------------------------------------
section "Obsidian"

if command -v obsidian >/dev/null 2>&1 \
    || [ -d "/Applications/Obsidian.app" ] \
    || { [ -d "${HOME}/.local/share/applications" ] && \
         find "${HOME}/.local/share/applications" -maxdepth 1 -iname '*obsidian*' 2>/dev/null | grep -q . ; }; then
    ok "Obsidian detected"
else
    todo "Obsidian not detected. Install hint:"
    info "  Linux:   snap install obsidian  (or flatpak install flathub md.obsidian.Obsidian)"
    info "  macOS:   brew install --cask obsidian"
    info "  Windows: https://obsidian.md/download"
fi

if [ "${any_tool}" -gt 0 ]; then
    if [ "${auto}" -eq 1 ]; then
        section "Auto-install (${auto_reason})"
    else
        section "Tool install hints (${auto_reason})"
    fi
fi

#------------------------------------------------------------------------------
# Step 4 — OpenViking (--with-ov)
#------------------------------------------------------------------------------
if [ "${with_ov}" -eq 1 ]; then
    section "OpenViking"

    # ov.conf is pure-local scaffold — written directly, always, on --with-ov.
    ov_conf="${HOME}/.openviking/ov.conf"
    if [ -f "${ov_conf}" ]; then
        ok "ov.conf present"
    else
        ( umask 077; mkdir -p "$(dirname "${ov_conf}")" )
        chmod 700 "$(dirname "${ov_conf}")" 2>/dev/null || true
        ( umask 077; cat > "${ov_conf}" <<EOF
workspace = ${VAULT_HOME}
provider  = ollama
model     = nomic-embed-text
EOF
        )
        ok "wrote ${ov_conf} (0600)"
    fi

    if [ "${auto}" -eq 1 ]; then
        tool_try ollama install_ollama
        if claude_cli_ok; then
            tool_try openviking-plugin install_openviking_plugin
        else
            todo "claude CLI missing/old — install the OpenViking plugin manually:"
            info "  claude plugin marketplace add Castor6/openviking-plugins"
            info "  claude plugin install claude-code-memory-plugin@openviking-plugin"
        fi
    else
        todo "Install Ollama + embedding model:"
        info "  curl -fsSL https://ollama.com/install.sh | sh"
        info "  ollama pull nomic-embed-text"
        todo "Install the OpenViking Claude Code plugin:"
        info "  claude plugin marketplace add Castor6/openviking-plugins"
        info "  claude plugin install claude-code-memory-plugin@openviking-plugin"
    fi
fi

#------------------------------------------------------------------------------
# Step 5 — Serena (--with-serena)
#------------------------------------------------------------------------------
if [ "${with_serena}" -eq 1 ]; then
    section "Serena"
    if [ "${auto}" -eq 1 ]; then
        tool_try uv install_uv
        tool_try serena install_serena
    else
        todo "Install uv, then Serena:"
        info "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        info "  uv tool install -p 3.13 serena-agent"
    fi
fi

#------------------------------------------------------------------------------
# Step 6 — claude-mem (--with-claude-mem)
#------------------------------------------------------------------------------
if [ "${with_claude_mem}" -eq 1 ]; then
    section "claude-mem / mcp-search"
    if [ "${auto}" -eq 1 ]; then
        tool_try bun install_bun
        if claude_cli_ok; then
            tool_try claude-mem-plugin install_claude_mem_plugin
        else
            todo "claude CLI missing/old — install claude-mem manually:"
            info "  claude plugin marketplace add thedotmack/claude-mem"
            info "  claude plugin install claude-mem"
        fi
    else
        todo "Install bun + the claude-mem plugin:"
        info "  curl -fsSL https://bun.com/install | bash"
        info "  claude plugin marketplace add thedotmack/claude-mem"
        info "  claude plugin install claude-mem"
    fi
fi

#------------------------------------------------------------------------------
# Step 7 — Graphify (--with-graphify)
#------------------------------------------------------------------------------
if [ "${with_graphify}" -eq 1 ]; then
    section "Graphify"
    if [ "${auto}" -eq 1 ]; then
        tool_try graphify install_graphify
    else
        todo "Install pipx, then Graphify:"
        info "  sudo apt install -y pipx && pipx ensurepath"
        info "  pipx install graphifyy"
    fi
    info "Per-project graph: /v-init installs the post-commit hook (graphify hook install)."
fi

#------------------------------------------------------------------------------
# Step 8 — Per-repo onboarding instructions
#------------------------------------------------------------------------------
# The installer no longer writes a snippet into the user-owned ~/.claude/CLAUDE.md.
# The framework path lives in $VAULT_FRAMEWORK_PATH (recorded below in config.md);
# each code repo is onboarded explicitly with vault-init, which writes a VAULT.md
# in that folder and references $VAULT_FRAMEWORK_PATH (portable across users).
section "Onboard a code repo"
todo "Run this inside each code repo you want vault-aware:"
info "  cd <your-repo> && ${VAULT_ROOT}/bin/vault-init.sh"
info "  (or /v-init from Claude Code) — writes VAULT.md + scaffolds the vault."
info "Framework path recorded in ${VAULT_HOME}/_global/config.md as \$VAULT_FRAMEWORK_PATH."
info "Optional (stable per-user): add to your shell profile —"
info "  export VAULT_FRAMEWORK_PATH=\"${VAULT_ROOT}\""

#------------------------------------------------------------------------------
# Step 9 — install.sh (symlink slash commands)  (pure-local — never via run())
#------------------------------------------------------------------------------
if [ "${SETUP_SKIP_INSTALL_SH}" -eq 1 ]; then
    section "install.sh (skipped via SETUP_SKIP_INSTALL_SH)"
else
    section "install.sh"
    "${VAULT_ROOT}/install.sh"
fi

#------------------------------------------------------------------------------
# Step 10 — Doctor (verify what landed; owns the exit code on auto-install)
#------------------------------------------------------------------------------
doctor_status=0
if [ "${auto}" -eq 1 ]; then
    doctor || doctor_status=$?
fi

section "Done"
info "Re-run setup.sh anytime; it is idempotent."
if [ "${#TOOLS_FAILED[@]}" -gt 0 ]; then
    warn "Some tools failed to install: ${TOOLS_FAILED[*]} — re-run or see hints above."
fi
exit "${doctor_status}"
