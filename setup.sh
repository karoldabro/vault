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
#   4. Serena (--full / --with-serena): uv + serena-agent.
#   5. claude-mem (--light / --full / --with-claude-mem): bun + claude-mem plugin.
#   6. Graphify (--full / --with-graphify): pipx + graphifyy.
#   7. Print per-repo onboarding instructions (vault-init).
#   8. Run install.sh to symlink slash commands — SKIPPED under a plugin install,
#      where Claude Code already supplies them (see lib/plugin-detect.sh).
#   9. Doctor pass — verify what landed; non-zero exit only if a required tool failed.
#
# Three install profiles (see ADR-021):
#   --light    claude-mem only. The default, and what a normal user wants.
#   --full     adds Serena + Graphify — developer tools for symbol navigation and
#              the structural code graph. Costs uv, pipx and Python >=3.10.
#   --minimal  no tools at all; scaffold + command links only.
# With no flag and a terminal, setup.sh asks which one. Pass --yes to consent
# non-interactively (CI/automation) — that lands on --light.
#
# Auto-install runs remote installers (uv/bun via the vendors' official
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
# shellcheck source=lib/plugin-detect.sh
. "${VAULT_ROOT}/lib/plugin-detect.sh"

with_serena=0
with_claude_mem=0
with_graphify=0
minimal=0
assume_yes=0
doctor_only=0
# Which profile the user asked for: "" until a flag or the prompt settles it.
profile=""
# 1 when any --with-* flag was passed — a hand-picked set is a choice of its own
# and must never be overwritten by the prompt or the light default.
picked_tools=0

usage() {
    cat <<EOF
Usage: $0 [flags]

Install profiles (asked interactively when you pass none):
  --light             claude-mem only. The default — what a normal user needs.
  --full              Adds Serena + Graphify: developer tools for symbol
                      navigation and the structural code graph. Needs uv, pipx
                      and Python >=3.10.
  --minimal           No tools at all (base scaffold + command links only).

Individual tools (override the profile):
  --with-serena       Serena language server (uv + serena-agent).
  --with-claude-mem   claude-mem mcp-search plugin (bun + claude-mem).
  --with-graphify     Graphify (pipx + graphifyy).

Behaviour:
  --yes, -y           Consent to auto-install non-interactively (no prompt).
  --dry-run           Echo every side-effecting command instead of running it.
  --doctor            Only run the tool-health check, then exit.
  -h, --help          Show this help.

On Ubuntu (apt + sudo) tools are installed automatically once consented; elsewhere
the exact install commands are printed instead. Re-run anytime; it is idempotent.

Examples:
  $0                  # asks which install you want
  $0 --yes            # light install, no questions
  $0 --full --yes
  $0 --full --dry-run
  $0 --doctor
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --with-serena)     with_serena=1; picked_tools=1 ;;
        --with-claude-mem) with_claude_mem=1; picked_tools=1 ;;
        --with-graphify)   with_graphify=1; picked_tools=1 ;;
        --light)           profile="light" ;;
        --full)            profile="full" ;;
        --minimal)         profile="minimal"; minimal=1 ;;
        --yes|-y)          assume_yes=1 ;;
        --dry-run)         export VAULT_SETUP_DRY_RUN=1; assume_yes=1 ;;
        --doctor)          doctor_only=1 ;;
        -h|--help)         usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# Footgun guard: setup.sh installs PER-USER (uv/bun/plugins all land in $HOME).
# Running it under sudo flips $HOME to /root, hides the user's `claude` from PATH, and
# strands every per-user artifact in root's home. $SUDO_USER is set only when a non-root
# user invokes sudo — genuine root (containers / CI, e.g. the e2e harness) has it unset,
# so this never trips there. We escalate for apt ourselves; you don't pre-sudo.
if [ -n "${SUDO_USER:-}" ] && [ "${VAULT_ALLOW_SUDO:-0}" != "1" ]; then
    warn "Do not run setup.sh with sudo — it installs per-user and writes to \$HOME."
    warn "Run it as your normal user:  ./setup.sh --full --yes"
    warn "(it prompts for your sudo password when it reaches apt)."
    warn "Override only if you truly mean it: VAULT_ALLOW_SUDO=1 sudo -E ./setup.sh ..."
    exit 1
fi

if [ "${doctor_only}" -eq 1 ]; then
    doctor
    exit $?
fi

#------------------------------------------------------------------------------
# Resolve the install profile (ADR-021)
#------------------------------------------------------------------------------
# Serena and Graphify are DEVELOPER tools: they buy cheaper structural code work
# and cost uv, pipx and Python >=3.10. A normal user of the framework never needs
# them, so they ship only in --full. Four rules, in order:
#
#   1. An explicit --light/--full/--minimal or any --with-* flag IS the answer.
#   2. No flag + a TTY            → ask.
#   3. No flag + --yes            → light (consent given, take the default).
#   4. No flag, no --yes, no TTY  → minimal. ADR-005's line holds: nothing is
#                                   ever installed unattended without consent.
if [ -z "${profile}" ] && [ "${picked_tools}" -eq 0 ]; then
    reply=""
    if [ "${assume_yes}" -eq 1 ]; then
        profile="light"
    elif [ -t 0 ] && { : </dev/tty; } 2>/dev/null; then
        # Gated on stdin being a terminal, not just on /dev/tty existing: a piped
        # or scripted run (curl | bash, CI, the test suite) has a controlling tty
        # but nobody to answer, and must fall through to rule 4 rather than hang.
        printf '\nWhich install?\n'
        printf '  [1] Light (normal)     claude-mem only. Recommended.\n'
        printf '  [2] Full (developer)   adds Serena + Graphify (uv, pipx, Python >=3.10).\n'
        printf '  [3] Minimal            framework only, no tools.\n'
        printf 'Choice [1]: '
        read -r reply </dev/tty || reply=""
        case "${reply}" in
            2) profile="full" ;;
            3) profile="minimal" ;;
            *) profile="light" ;;   # empty or unrecognised → the recommended one
        esac
    else
        profile="minimal"
        warn "No answer and no consent — installing no tools."
        info "Choose explicitly next time: --light (recommended), --full, or --minimal."
    fi
    [ "${profile}" = "minimal" ] && minimal=1
fi

case "${profile}" in
    light) with_claude_mem=1 ;;
    full)  with_serena=1; with_claude_mem=1; with_graphify=1 ;;
esac

# --minimal beats every profile and every hand-picked tool.
if [ "${minimal}" -eq 1 ]; then
    with_serena=0
    with_claude_mem=0
    with_graphify=0
fi

# A hand-picked --with-* set with no profile flag is its own profile for the
# purposes of the recorded install_mode: it is at least as capable as light, and
# counts as full only when both developer tools landed.
if [ -z "${profile}" ]; then
    if [ "${with_serena}" -eq 1 ] && [ "${with_graphify}" -eq 1 ]; then
        profile="full"
    else
        profile="light"
    fi
fi

any_tool=$(( with_serena + with_claude_mem + with_graphify ))

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
        printf '\nAuto-install will run vendor install scripts (uv/bun) and add\n'
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

# Pre-warm sudo so the apt steps prompt for the password ONCE up front rather
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
install_mode: ${profile}
EOF
    ok "wrote ${config_md}"
fi

# Record which profile this machine runs, so the commands know whether the
# developer tools are *expected*. Without it a light machine reads as a broken
# one and every structural question re-offers a Graphify install (ADR-021).
# Rewritten on every run: re-running with a different profile must update it.
if grep -q '^install_mode:' "${config_md}" 2>/dev/null; then
    existing_mode="$(sed -n 's/^install_mode:[[:space:]]*//p' "${config_md}" | head -1)"
    if [ "${existing_mode}" != "${profile}" ]; then
        tmp_cfg="${config_md}.tmp.$$"
        sed "s|^install_mode:.*|install_mode: ${profile}|" "${config_md}" > "${tmp_cfg}" \
            && mv "${tmp_cfg}" "${config_md}"
        ok "install_mode: ${existing_mode} → ${profile}"
    else
        ok "install_mode: ${profile}"
    fi
else
    printf 'install_mode: %s\n' "${profile}" >> "${config_md}"
    ok "install_mode: ${profile}"
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
# Step 4 — Serena (--full / --with-serena) — developer tool
#------------------------------------------------------------------------------
if [ "${with_serena}" -eq 1 ]; then
    section "Serena (developer)"
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
# Step 5 — claude-mem (--light / --full / --with-claude-mem)
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
            info "  claude plugin install claude-mem@thedotmack"   # qualified id — bare 'claude-mem' no-ops
        fi
    else
        todo "Install bun + the claude-mem plugin:"
        info "  curl -fsSL https://bun.com/install | bash"
        info "  claude plugin marketplace add thedotmack/claude-mem"
        info "  claude plugin install claude-mem@thedotmack"   # qualified id — bare 'claude-mem' no-ops
    fi
fi

#------------------------------------------------------------------------------
# Step 6 — Graphify (--full / --with-graphify) — developer tool
#------------------------------------------------------------------------------
if [ "${with_graphify}" -eq 1 ]; then
    section "Graphify (developer)"
    if [ "${auto}" -eq 1 ]; then
        tool_try graphify install_graphify
    else
        todo "Install pipx, then Graphify:"
        info "  sudo apt install -y pipx python3.12 python3.12-venv && pipx ensurepath"
        info "  pipx install graphifyy --python python3.12   # needs Python >=3.10"
    fi
    info "Per-project graph: /v-init installs the post-commit hook (graphify hook install)."
fi

#------------------------------------------------------------------------------
# Step 7 — Per-repo onboarding instructions
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
# Step 8 — install.sh (symlink slash commands)  (pure-local — never via run())
#------------------------------------------------------------------------------
if [ "${SETUP_SKIP_INSTALL_SH}" -eq 1 ]; then
    section "install.sh (skipped via SETUP_SKIP_INSTALL_SH)"
elif vault_running_from_plugin_cache "${VAULT_ROOT}" || vault_plugin_installed; then
    # Plugin install: Claude Code already loads the commands. Symlinking them as
    # well would install every command twice. install.sh refuses on its own; skip
    # it here so a normal --full run doesn't end on a scary REFUSED block.
    section "install.sh (skipped — commands come from the Claude Code plugin)"
else
    section "install.sh"
    "${VAULT_ROOT}/install.sh"
fi

#------------------------------------------------------------------------------
# Step 9 — Doctor (verify what landed; owns the exit code on auto-install)
#------------------------------------------------------------------------------
doctor_status=0
if [ "${auto}" -eq 1 ]; then
    doctor || doctor_status=$?
fi

section "Done"
info "Install: ${profile}."
if [ "${profile}" = "light" ]; then
    info "Serena + Graphify were not installed — they are developer tools."
    info "Add them later with: ${VAULT_ROOT}/setup.sh --full"
fi
info "Re-run setup.sh anytime; it is idempotent."
if [ "${auto}" -eq 1 ]; then
    info "Open a fresh shell (exec \$SHELL -l) so new PATH entries (uv/bun/pipx) take effect"
    info "before running graphify/serena from the terminal."
fi
if [ "${#TOOLS_FAILED[@]}" -gt 0 ]; then
    warn "Some tools failed to install: ${TOOLS_FAILED[*]} — re-run or see hints above."
fi
exit "${doctor_status}"
