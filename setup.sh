#!/usr/bin/env bash
# Umbrella installer for the vault knowledge-framework stack.
#
# Responsibilities (idempotent):
#   1. Verify base prereqs (git, curl, jq).
#   2. Create the machine-layer dir (~/vault/_global/) and coupled-groups.md.
#   3. Detect Obsidian (hint only).
#   4. Optional: wire OpenViking (--with-ov) — checks ollama + model + ov.conf.
#   5. Optional: wire Graphify (--with-graphify) — checks pipx + graphifyy.
#   6. Print the CLAUDE.md memory-stack snippet if not already present.
#   7. Run install.sh to symlink slash commands.
#
# Network-requiring installs (ollama, pipx) are NOT auto-executed. setup.sh
# detects what's missing and prints the exact command to run. This keeps the
# script safe to re-run, test-friendly, and avoids surprise `curl | bash`.
#
# Environment overrides (used by tests; safe to ignore in real use):
#   VAULT_HOME              default: $HOME/vault
#   CLAUDE_HOME             default: $HOME/.claude
#   SETUP_SKIP_INSTALL_SH   default: 0 — set to 1 to skip calling install.sh

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_HOME="${VAULT_HOME:-${HOME}/vault}"
CLAUDE_HOME="${CLAUDE_HOME:-${HOME}/.claude}"
SETUP_SKIP_INSTALL_SH="${SETUP_SKIP_INSTALL_SH:-0}"

with_ov=0
with_graphify=0
minimal=0
assume_yes=0

usage() {
    cat <<EOF
Usage: $0 [flags]

Flags:
  --with-ov         Wire OpenViking (Ollama + nomic-embed-text + ov.conf hint).
  --with-graphify   Wire Graphify (pipx install graphifyy hint).
  --minimal         Skip all optional integrations (default if no other flag).
  --yes             Non-interactive; never prompt.
  -h, --help        Show this help.

Examples:
  $0 --minimal
  $0 --with-ov --with-graphify --yes
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --with-ov)        with_ov=1 ;;
        --with-graphify)  with_graphify=1 ;;
        --minimal)        minimal=1 ;;
        --yes|-y)         assume_yes=1 ;;
        -h|--help)        usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [ "${minimal}" -eq 1 ]; then
    with_ov=0
    with_graphify=0
fi

section() { printf '\n=== %s ===\n' "$1"; }
ok()      { printf '  [ok]  %s\n' "$1"; }
warn()    { printf '  [warn] %s\n' "$1" >&2; }
todo()    { printf '  [todo] %s\n' "$1"; }
info()    { printf '  %s\n' "$1"; }

#------------------------------------------------------------------------------
# Step 1 — Base prerequisites
#------------------------------------------------------------------------------
section "Prerequisites"

missing_base=0
for cmd in git curl jq; do
    if command -v "${cmd}" >/dev/null 2>&1; then
        ok "${cmd}"
    else
        warn "${cmd} not found — install via your package manager"
        missing_base=$((missing_base + 1))
    fi
done

if [ "${missing_base}" -gt 0 ]; then
    warn "${missing_base} base prereqs missing; install them and re-run."
    exit 1
fi

#------------------------------------------------------------------------------
# Step 2 — Machine-layer directory
#------------------------------------------------------------------------------
section "Machine layer (${VAULT_HOME})"

mkdir -p "${VAULT_HOME}/_global"
ok "${VAULT_HOME}/_global/"

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
    || [ -d "${HOME}/.local/share/applications" ] && \
       find "${HOME}/.local/share/applications" -maxdepth 1 -iname '*obsidian*' 2>/dev/null | grep -q . ; then
    ok "Obsidian detected"
else
    todo "Obsidian not detected. Install hint:"
    info "  Linux:   snap install obsidian  (or flatpak install flathub md.obsidian.Obsidian)"
    info "  macOS:   brew install --cask obsidian"
    info "  Windows: https://obsidian.md/download"
fi

#------------------------------------------------------------------------------
# Step 4 — OpenViking (optional)
#------------------------------------------------------------------------------
if [ "${with_ov}" -eq 1 ]; then
    section "OpenViking"

    if command -v ollama >/dev/null 2>&1; then
        ok "ollama present"
        if ollama list 2>/dev/null | grep -q '^nomic-embed-text'; then
            ok "nomic-embed-text model pulled"
        else
            todo "Pull the embedding model:"
            info "  ollama pull nomic-embed-text"
        fi
    else
        todo "Install Ollama (https://ollama.com), then re-run setup."
        info "  Linux/macOS quick install: curl -fsSL https://ollama.com/install.sh | sh"
    fi

    ov_conf="${HOME}/.openviking/ov.conf"
    if [ -f "${ov_conf}" ]; then
        ok "ov.conf present"
    else
        mkdir -p "$(dirname "${ov_conf}")"
        cat > "${ov_conf}" <<EOF
workspace = ${VAULT_HOME}
provider  = ollama
model     = nomic-embed-text
EOF
        ok "wrote ${ov_conf}"
    fi

    todo "Install the OV Claude Code plugin (one-time, manual):"
    info "  In Claude Code:  /plugin install openviking"
fi

#------------------------------------------------------------------------------
# Step 5 — Graphify (optional)
#------------------------------------------------------------------------------
if [ "${with_graphify}" -eq 1 ]; then
    section "Graphify"

    if command -v graphify >/dev/null 2>&1; then
        ok "graphify present ($(graphify --version 2>/dev/null || echo unknown))"
    elif command -v pipx >/dev/null 2>&1; then
        todo "Install Graphify with pipx:"
        info "  pipx install graphifyy"
    else
        todo "Install pipx, then Graphify:"
        info "  Linux:   sudo apt install pipx  (or your distro equivalent)"
        info "  macOS:   brew install pipx"
        info "  Then:    pipx install graphifyy"
    fi
fi

#------------------------------------------------------------------------------
# Step 6 — CLAUDE.md snippet
#------------------------------------------------------------------------------
section "CLAUDE.md memory-stack snippet"

claude_md="${CLAUDE_HOME}/CLAUDE.md"
snippet_marker="Cross-project memory stack"

if [ -f "${claude_md}" ] && grep -q "${snippet_marker}" "${claude_md}"; then
    ok "snippet already present in ${claude_md}"
else
    todo "Paste this snippet into ${claude_md}:"
    cat <<EOF
  ---8<--- snippet ---8<---
  ## ${snippet_marker}

  Three layers — framework, project, machine. Framework is reachable as
  \`~/workspace/vault/\` (this repo) or as the \`_process/\` submodule inside
  any per-project vault under \`~/vault/<slug>/\`.

  Vault commands (installed by this framework):
  - /v-work     — vault-aware dev lifecycle.
  - /v-capture  — capture this session into the vault.

  See \`~/workspace/vault/vault-guide.md\`.
  ---8<--- snippet ---8<---
EOF
fi

#------------------------------------------------------------------------------
# Step 7 — install.sh (symlink slash commands)
#------------------------------------------------------------------------------
if [ "${SETUP_SKIP_INSTALL_SH}" -eq 1 ]; then
    section "install.sh (skipped via SETUP_SKIP_INSTALL_SH)"
else
    section "install.sh"
    "${VAULT_ROOT}/install.sh"
fi

section "Done"
info "Re-run setup.sh anytime; it is idempotent."
