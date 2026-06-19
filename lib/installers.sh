#!/usr/bin/env bash
# lib/installers.sh — per-tool installers + the run() executor for setup.sh.
#
# Sourced by setup.sh (and by the bats suite, which exercises install_*/check_* in
# isolation against a faux apt/claude on PATH). Holds NO orchestration — setup.sh
# decides which tools to install and in what order; this file knows only how to
# install/check one tool each, idempotently.
#
# Design contract (see vault/plans/2026-06-18-1518-setup-auto-install.md):
#   * run() is the ONLY path for network/privileged side-effects. Pure-local
#     scaffolding (mkdir, config heredocs) stays a direct call in setup.sh so the
#     offline test image keeps exercising those assertions unchanged.
#   * VAULT_SETUP_DRY_RUN=1 makes run() echo "[dry-run] <cmd>" and return 0 without
#     executing — the primary tested surface for the execute-path logic.
#   * Every install_X is idempotent (check_X guards it) and continue-on-error: a
#     failure is recorded, never fatal. The doctor pass owns the exit code.

# Guard against double-source.
[ -n "${_VAULT_INSTALLERS_SH:-}" ] && return 0
_VAULT_INSTALLERS_SH=1

#------------------------------------------------------------------------------
# Logging (printf-based; safe under set -euo pipefail)
#------------------------------------------------------------------------------
section() { printf '\n=== %s ===\n' "$1"; }
ok()      { printf '  [ok]  %s\n' "$1"; }
warn()    { printf '  [warn] %s\n' "$1" >&2; }
todo()    { printf '  [todo] %s\n' "$1"; }
info()    { printf '  %s\n' "$1"; }

#------------------------------------------------------------------------------
# run() — the dry-run-aware, secret-redacting executor
#------------------------------------------------------------------------------
# Redact KEY/TOKEN/SECRET/PASSWORD values so they never reach stdout / a CI log /
# a test fixture (defence-in-depth; the stack ships no secrets today).
_redact_args() {
    local out=() a k
    for a in "$@"; do
        case "$a" in
            *=*)
                k="${a%%=*}"
                case "${k^^}" in
                    *KEY|*TOKEN|*SECRET|*PASSWORD) out+=("${k}=***") ;;
                    *) out+=("$a") ;;
                esac ;;
            *) out+=("$a") ;;
        esac
    done
    printf '%s ' "${out[@]}"
}

_dry() { [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; }

# run <cmd...> — execute, or echo under dry-run. Returns the command's status.
run() {
    if [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; then
        printf '  [dry-run] %s\n' "$(_redact_args "$@")"
        return 0
    fi
    "$@"
}

# run_shell <description> <shell-pipeline> — for pipe-to-shell installers that can't
# be argv-quoted (curl … | sh). Prints the pipeline (so the URL is auditable) and,
# outside dry-run, executes it via bash -c.
# INVARIANT: the pipeline MUST be secret-free — it is printed verbatim (no redaction,
# unlike run()). Pass any KEY=val through run(), never run_shell.
run_shell() {
    local desc="$1" pipeline="$2"
    info "source: ${desc}"
    if [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; then
        printf '  [dry-run] %s\n' "${pipeline}"
        return 0
    fi
    bash -c "${pipeline}"
}

#------------------------------------------------------------------------------
# Platform + PATH helpers
#------------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

# Pull the well-known user-install bins onto PATH for THIS process, so check_*
# and the doctor see tools installed earlier in the same run (uv/bun/pipx edit
# shell rc files that only a fresh login shell would pick up).
ensure_session_path() {
    local d
    for d in "${HOME}/.local/bin" "${HOME}/.bun/bin" "/usr/local/bin"; do
        case ":${PATH}:" in
            *":${d}:"*) ;;
            *) [ -d "$d" ] && PATH="${d}:${PATH}" ;;
        esac
    done
    export PATH
}

apt_available()  { have apt-get; }
# True when we can run apt: root, passwordless sudo, or an interactive sudo we can
# prompt on (a TTY is attached). The last case is the common workstation — the user
# runs setup.sh as themselves and sudo asks for their password when apt is reached.
# Only a non-interactive shell without passwordless sudo is a real "no": there we
# cannot escalate, so the caller degrades to printing hints.
sudo_available() {
    [ "$(id -u)" -eq 0 ] && return 0
    have sudo || return 1
    sudo -n true >/dev/null 2>&1 && return 0   # passwordless
    [ -t 0 ] || [ -t 1 ]                        # interactive → sudo can prompt
}
# Emit the right privilege prefix for apt ("" as root, "sudo" otherwise).
_priv() { [ "$(id -u)" -eq 0 ] || printf 'sudo'; }

# apt_install <pkg...> — idempotent-ish; apt itself skips already-installed pkgs.
apt_install() { run $(_priv) apt-get install -y "$@"; }

#------------------------------------------------------------------------------
# Per-tool status tracking + continue-on-error wrapper
#------------------------------------------------------------------------------
TOOLS_OK=()
TOOLS_FAILED=()
record_ok()   { TOOLS_OK+=("$1"); }
record_fail() { TOOLS_FAILED+=("$1"); }

# tool_try <name> <install_fn> — run an installer with continue-on-error so one
# failure never aborts the whole run (the doctor pass decides the exit code).
tool_try() {
    local name="$1" fn="$2"
    if "${fn}"; then record_ok "${name}"; else record_fail "${name}"; warn "${name}: install step failed (continuing)"; fi
}

#------------------------------------------------------------------------------
# uv (astral.sh) — foundational; Serena depends on it
#------------------------------------------------------------------------------
check_uv() { ensure_session_path; have uv; }
install_uv() {
    if check_uv; then ok "uv present"; return 0; fi
    run_shell "https://astral.sh/uv/install.sh" "curl -LsSf https://astral.sh/uv/install.sh | sh" || return 1
    _dry && { ok "uv (dry-run)"; return 0; }
    ensure_session_path
    have uv && ok "uv installed" || { warn "uv not on PATH after install"; return 1; }
}

#------------------------------------------------------------------------------
# bun (bun.com) — needs unzip; claude-mem can use it
#------------------------------------------------------------------------------
check_bun() { ensure_session_path; have bun; }
install_bun() {
    if check_bun; then ok "bun present"; return 0; fi
    # bun installer needs unzip; only reach for apt when it's actually usable.
    if ! have unzip; then
        if apt_available && sudo_available; then apt_install unzip || true
        else warn "bun needs 'unzip' — install it manually"; fi
    fi
    run_shell "https://bun.com/install" "curl -fsSL https://bun.com/install | bash" || return 1
    _dry && { ok "bun (dry-run)"; return 0; }
    ensure_session_path
    have bun && ok "bun installed" || { warn "bun not on PATH after install"; return 1; }
}

#------------------------------------------------------------------------------
# Ollama — embedding backend for OpenViking
#------------------------------------------------------------------------------
check_ollama() { ensure_session_path; have ollama; }
# Start the daemon if it isn't reachable. Prefer systemd; fall back to a
# backgrounded `ollama serve` (containers have no init) and poll for readiness.
# Returns 0 only when `ollama list` actually succeeds (daemon reachable).
ensure_ollama_running() {
    if ollama list >/dev/null 2>&1; then return 0; fi
    if have systemctl && systemctl list-unit-files 2>/dev/null | grep -q '^ollama\.service'; then
        run $(_priv) systemctl enable --now ollama || true
        ollama list >/dev/null 2>&1 && return 0
    fi
    # No systemd (e.g. container): start a detached daemon and poll for readiness.
    ollama serve >/dev/null 2>&1 &
    disown 2>/dev/null || true
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        ollama list >/dev/null 2>&1 && return 0
        sleep 1
    done
    warn "ollama daemon did not become ready within 10s"
    return 1
}
install_ollama() {
    if check_ollama; then
        ok "ollama present"
    elif _dry; then
        run_shell "https://ollama.com/install.sh" "curl -fsSL https://ollama.com/install.sh | sh"
    else
        run_shell "https://ollama.com/install.sh" "curl -fsSL https://ollama.com/install.sh | sh" || return 1
        ensure_session_path
        have ollama || { warn "ollama not on PATH after install"; return 1; }
        ok "ollama installed"
    fi
    # Pull the embedding model, guarded so a re-run is a no-op. A dead daemon is a
    # recorded failure, not a silent skip — don't pull against an unreachable server.
    if [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; then
        printf '  [dry-run] ollama list | grep -q nomic-embed-text || ollama pull nomic-embed-text\n'
    elif ! ensure_ollama_running; then
        warn "ollama installed but daemon unreachable — skipping model pull"
        return 1
    elif ollama list 2>/dev/null | grep -q '^nomic-embed-text'; then
        ok "nomic-embed-text already pulled"
    else
        run ollama pull nomic-embed-text || return 1
    fi
}

#------------------------------------------------------------------------------
# pipx + graphify (PyPI graphifyy, binary `graphify`)
#------------------------------------------------------------------------------
check_graphify() { ensure_session_path; have graphify; }
install_graphify() {
    if check_graphify; then ok "graphify present"; return 0; fi
    if ! have pipx; then
        apt_install pipx || return 1
        run pipx ensurepath || true
        ensure_session_path
    fi
    run pipx install graphifyy || return 1
    _dry && { ok "graphify (dry-run)"; info "per-repo: 'graphify hook install' (or /v-init)"; return 0; }
    ensure_session_path
    have graphify && ok "graphify installed" || { warn "graphify not on PATH after install"; return 1; }
    info "per-repo: run 'graphify hook install' inside a repo (or let /v-init do it)"
}

#------------------------------------------------------------------------------
# Serena (oraios/serena) — uv tool
#------------------------------------------------------------------------------
check_serena() { ensure_session_path; have serena || { have uv && uv tool list 2>/dev/null | grep -q 'serena-agent'; }; }
install_serena() {
    if check_serena; then ok "serena present"; return 0; fi
    if _dry; then run uv tool install -p 3.13 serena-agent; ok "serena (dry-run)"; return 0; fi
    have uv || { warn "serena needs uv (install uv first)"; return 1; }
    run uv tool install -p 3.13 serena-agent || return 1
    ensure_session_path
    ok "serena installed"
}

#------------------------------------------------------------------------------
# OpenViking server (PyPI `openviking` → `openviking-server` + `ov` CLI) + the
# systemd --user service that keeps it running on :1933. The Claude Code MCP
# plugin (installed separately below) connects to this server in local mode.
#------------------------------------------------------------------------------
check_openviking_server() { ensure_session_path; have openviking-server || have ov; }
# Write + enable the user service (setup.sh has already written the unit file). Best
# effort: degrade cleanly where there is no user systemd (containers/CI) by starting
# a detached server instead. Never fatal.
ov_enable_service() {
    if [ "${VAULT_SETUP_DRY_RUN:-0}" = "1" ]; then
        printf '  [dry-run] systemctl --user enable --now openviking.service\n'
        return 0
    fi
    if have systemctl && systemctl --user show-environment >/dev/null 2>&1; then
        run systemctl --user daemon-reload || true
        if run systemctl --user enable --now openviking.service; then
            ok "openviking.service enabled (:1933)"
            # Survive logout; needs privilege, so best-effort + a hint when it can't.
            loginctl enable-linger "$(id -un)" >/dev/null 2>&1 \
                || info "for boot persistence: sudo loginctl enable-linger $(id -un)"
        else
            warn "could not enable openviking.service — start it with: systemctl --user start openviking.service"
            return 1
        fi
    else
        warn "no user systemd — starting openviking-server detached (no auto-restart)"
        ( openviking-server --config "${HOME}/.openviking/ov.conf" >/dev/null 2>&1 & disown 2>/dev/null ) || true
    fi
}
install_openviking_server() {
    if check_openviking_server; then
        ok "openviking-server present"
    elif _dry; then
        run pipx install openviking
        ok "openviking (dry-run)"
        ov_enable_service
        return 0
    else
        if ! have pipx; then
            apt_install pipx || return 1
            run pipx ensurepath || true
            ensure_session_path
        fi
        run pipx install openviking || return 1
        ensure_session_path
        have openviking-server || { warn "openviking-server not on PATH after install"; return 1; }
        ok "openviking installed"
    fi
    ov_enable_service
}

#------------------------------------------------------------------------------
# Claude Code plugins / marketplaces (scriptable `claude` CLI)
#------------------------------------------------------------------------------
# Minimum claude CLI version exposing `plugin`/`mcp` subcommands.
CLAUDE_MIN_VERSION="2.0.0"
claude_cli_ok() {
    have claude || return 1
    # Probe the subcommand surface rather than trusting a version string alone.
    claude plugin --help >/dev/null 2>&1
}
_marketplace_add() {  # <repo> <grep-key>
    local repo="$1" key="$2"
    if claude plugin marketplace list 2>/dev/null | grep -qi "$key"; then
        ok "marketplace ${key} already added"
    else
        run claude plugin marketplace add "$repo" || return 1
    fi
}
_plugin_install() {  # <qualified-id> <grep-key>
    local id="$1" key="$2"
    if claude plugin list 2>/dev/null | grep -qi "$key"; then
        ok "plugin ${key} already installed"
    else
        run claude plugin install "$id" --scope user || return 1
    fi
}
install_openviking_plugin() {
    _marketplace_add "Castor6/openviking-plugins" "openviking" || return 1
    _plugin_install "claude-code-memory-plugin@openviking-plugin" "claude-code-memory-plugin" || return 1
    ok "OpenViking plugin wired"
}
install_claude_mem_plugin() {
    _marketplace_add "thedotmack/claude-mem" "claude-mem" || return 1
    # marketplace name == plugin name for this repo; bun is auto-installed by claude-mem.
    _plugin_install "claude-mem@claude-mem" "claude-mem" || return 1
    ok "claude-mem plugin wired"
}

#------------------------------------------------------------------------------
# Claude settings.json env — make the OV plugin's stock .mcp.json placeholders
# (${OPENVIKING_CC_CONFIG_FILE} / ${OPENVIKING_CONFIG_FILE}) resolve. Without these
# Claude injects the literal "${VAR}" as a path and the MCP exits ("Connection closed").
#------------------------------------------------------------------------------
# ov_set_env_key <settings.json> <key> <value> — non-clobbering + self-healing:
# add when absent; keep a present value that points at a real file (deliberate
# override); rewrite only a value whose file is missing (stale). Other keys untouched.
ov_set_env_key() {
    local f="$1" k="$2" v="$3" cur tmp
    if ! have jq; then warn "jq missing — add ${k} to ${f} manually (= ${v})"; return 1; fi
    mkdir -p "$(dirname "$f")"
    [ -s "$f" ] || printf '{}\n' > "$f"
    cur="$(jq -r --arg k "$k" '.env[$k] // empty' "$f" 2>/dev/null || true)"
    if [ -n "$cur" ] && [ -e "$cur" ]; then
        if [ "$cur" = "$v" ]; then ok "settings.json: ${k} already set"; else info "settings.json: kept your ${k} (${cur})"; fi
        return 0
    fi
    tmp="$(mktemp)"
    if jq --arg k "$k" --arg v "$v" '.env = (.env // {}) | .env[$k] = $v' "$f" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$f"; ok "settings.json: ${k} → ${v}"
    else
        rm -f "$tmp"; warn "could not merge ${k} into ${f} (invalid JSON?) — add it manually"; return 1
    fi
}

#------------------------------------------------------------------------------
# Doctor — verify what actually landed; owns the exit code
#------------------------------------------------------------------------------
# doctor_check <label> <test-cmd...> ; prints ✓/✗, returns the test status.
_doctor_row() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf '  [\xE2\x9C\x93] %s\n' "${label}"; return 0
    else
        printf '  [\xE2\x9C\x97] %s\n' "${label}"; return 1
    fi
}
# doctor [required-csv] — prints a status table; returns non-zero if a REQUIRED
# tool is missing. Uses fresh CLI invocations, never the live Claude session.
doctor() {
    ensure_session_path
    section "Doctor — tool health"
    local failed_required=0

    _doctor_row "ollama"               have ollama || true
    _doctor_row "  nomic-embed-text"   bash -c 'ollama list 2>/dev/null | grep -q "^nomic-embed-text"' || true
    _doctor_row "openviking-server"    have openviking-server || true
    _doctor_row "  OV server (:1933)"  bash -c 'curl -fsS -m 2 http://127.0.0.1:1933/health 2>/dev/null | grep -q healthy' || true
    _doctor_row "  client config.json" test -f "${HOME}/.openviking/claude-code-memory-plugin/config.json" || true
    _doctor_row "uv"                   have uv || true
    _doctor_row "bun"                  have bun || true
    _doctor_row "graphify"             have graphify || true
    _doctor_row "serena"               check_serena || true
    if claude_cli_ok; then
        _doctor_row "claude CLI"                       true
        _doctor_row "  OpenViking plugin"  bash -c 'claude plugin list 2>/dev/null | grep -qi claude-code-memory-plugin' || true
        _doctor_row "  claude-mem plugin"  bash -c 'claude plugin list 2>/dev/null | grep -qi claude-mem' || true
    else
        _doctor_row "claude CLI" false || true
    fi

    if [ "${#TOOLS_FAILED[@]}" -gt 0 ]; then
        warn "install steps that failed: ${TOOLS_FAILED[*]}"
        failed_required=1
    fi
    info "Restart Claude Code to load newly installed plugins/MCPs."
    return "${failed_required}"
}
