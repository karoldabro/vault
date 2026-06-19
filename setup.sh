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

# Footgun guard: setup.sh installs PER-USER (uv/bun/plugins/ov.conf all land in $HOME).
# Running it under sudo flips $HOME to /root, hides the user's `claude` from PATH, and
# strands every per-user artifact in root's home. $SUDO_USER is set only when a non-root
# user invokes sudo — genuine root (containers / CI, e.g. the e2e harness) has it unset,
# so this never trips there. We escalate for apt/ollama ourselves; you don't pre-sudo.
if [ -n "${SUDO_USER:-}" ] && [ "${VAULT_ALLOW_SUDO:-0}" != "1" ]; then
    warn "Do not run setup.sh with sudo — it installs per-user and writes to \$HOME."
    warn "Run it as your normal user:  ./setup.sh --full --yes"
    warn "(it prompts for your sudo password when it reaches apt / ollama)."
    warn "Override only if you truly mean it: VAULT_ALLOW_SUDO=1 sudo -E ./setup.sh ..."
    exit 1
fi

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

# Pre-warm sudo so the apt/ollama steps prompt for the password ONCE up front rather
# than at each escalation point. Best-effort: only when we'll auto-install, aren't root,
# have sudo, and it actually needs a password. A failed prime warns and continues — the
# sudo-free tools (uv/bun/serena/plugins) still install regardless.
if [ "${auto}" -eq 1 ] && [ "${VAULT_SETUP_DRY_RUN}" != "1" ] \
   && [ "$(id -u)" -ne 0 ] && have sudo && ! sudo -n true 2>/dev/null; then
    info "Auto-install needs apt — you'll be prompted for your sudo password once."
    sudo -v || warn "sudo not primed — apt-dependent tools (pipx/graphify) may be skipped."
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

    # OpenViking has THREE parts, all needed for the memory MCP to connect:
    #   1. server  — `openviking` pipx pkg (`openviking-server` + `ov` CLI), runs on :1933.
    #   2. ov.conf — the server's JSON config (host/port/storage/embedding).
    #   3. plugin client config — ~/.openviking/claude-code-memory-plugin/config.json,
    #      which the MCP server REQUIRES ({ "mode": "local" }); without it the plugin
    #      exits and Claude Code shows "Connection closed".
    # Config files + the systemd unit are pure-local scaffold — written directly here;
    # the network/privileged installs (pipx, systemctl) go through install_* / run().
    ov_dir="${HOME}/.openviking"
    ov_conf="${ov_dir}/ov.conf"
    # A valid config has the JSON "server" block; the old 3-line "workspace =" format is
    # rewritten (the server can't parse it, and the plugin reads port/key from here).
    if [ -f "${ov_conf}" ] && grep -q '"server"' "${ov_conf}" 2>/dev/null; then
        ok "ov.conf present"
    else
        ( umask 077; mkdir -p "${ov_dir}/data" "${ov_dir}/logs" )
        chmod 700 "${ov_dir}" 2>/dev/null || true
        ( umask 077; cat > "${ov_conf}" <<EOF
{
  "server": { "host": "127.0.0.1", "port": 1933 },
  "storage": {
    "workspace": "${ov_dir}/data",
    "vectordb": { "backend": "local" },
    "agfs": { "backend": "local", "port": 1833 }
  },
  "embedding": {
    "dense": {
      "provider": "litellm",
      "model": "ollama/nomic-embed-text",
      "api_base": "http://127.0.0.1:11434",
      "dimension": 768
    }
  }
}
EOF
        )
        ok "wrote ${ov_conf} (0600)"
    fi

    # Plugin client config — the file the MCP server requires to start.
    cc_conf="${ov_dir}/claude-code-memory-plugin/config.json"
    if [ -f "${cc_conf}" ]; then
        ok "client config.json present"
    else
        mkdir -p "$(dirname "${cc_conf}")"
        cat > "${cc_conf}" <<'EOF'
{
  "mode": "local",
  "agentId": "claude-code",
  "recallLimit": 6,
  "captureMode": "semantic",
  "captureTimeoutMs": 30000,
  "captureAssistantTurns": false
}
EOF
        ok "wrote ${cc_conf}"
    fi

    # systemd --user unit that keeps openviking-server running on :1933 (%h = $HOME).
    ov_unit="${HOME}/.config/systemd/user/openviking.service"
    if [ -f "${ov_unit}" ]; then
        ok "openviking.service unit present"
    else
        mkdir -p "$(dirname "${ov_unit}")"
        cat > "${ov_unit}" <<'EOF'
[Unit]
Description=OpenViking memory server (vault + Claude Code)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/openviking-server --config %h/.openviking/ov.conf
Restart=on-failure
RestartSec=5
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin
StandardOutput=append:%h/.openviking/logs/openviking.log
StandardError=append:%h/.openviking/logs/openviking.err

[Install]
WantedBy=default.target
EOF
        ok "wrote ${ov_unit}"
    fi

    if [ "${auto}" -eq 1 ]; then
        tool_try ollama install_ollama
        tool_try openviking-server install_openviking_server
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
        todo "Install the OpenViking server + ov CLI:"
        info "  pipx install openviking"
        todo "Enable the memory server (user service on :1933):"
        info "  systemctl --user enable --now openviking.service"
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
if [ "${auto}" -eq 1 ]; then
    info "Open a fresh shell (exec \$SHELL -l) so new PATH entries (uv/bun/pipx) take effect"
    info "before running graphify/serena from the terminal."
    info "OpenViking has no standalone 'ov' command — it is the MCP plugin (+ ollama backend);"
    info "'ov: command not found' is expected. Health = the plugin rows above / in --doctor."
fi
if [ "${#TOOLS_FAILED[@]}" -gt 0 ]; then
    warn "Some tools failed to install: ${TOOLS_FAILED[*]} — re-run or see hints above."
fi
exit "${doctor_status}"
