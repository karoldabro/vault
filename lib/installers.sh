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
# and the doctor see tools installed earlier in the same run (uv edits shell rc
# files that only a fresh login shell would pick up).
ensure_session_path() {
    local d
    for d in "${HOME}/.local/bin" "/usr/local/bin"; do
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
# Claude Code CLI
#------------------------------------------------------------------------------
claude_cli_ok() {
    have claude || return 1
    # Probe the subcommand surface rather than trusting a version string alone.
    claude plugin --help >/dev/null 2>&1
}

#------------------------------------------------------------------------------
# Consent gate — shared by every removal script (bin/vault-uninstall.sh,
# One implementation of "ask before destroying".
#------------------------------------------------------------------------------
# consent_gate <what-will-be-removed> <dry_run> <assume_yes>
#
# Sets two things IN THE CALLER'S SHELL:
#   VAULT_SETUP_DRY_RUN — so run() either executes or echoes
#   CONSENT_MODE        — "apply" or "plan-only", for the closing message
#
#   --dry-run           → plan-only, no prompt.
#   --yes               → apply.
#   neither, TTY        → prompt; anything but y/Y is plan-only.
#   neither, no TTY     → plan-only (never destroy unattended).
#
# MUST be called directly, never as "$(consent_gate ...)" — a command
# substitution runs in a subshell, where both assignments would be discarded.
consent_gate() {
    local what="$1" dry_run="${2:-0}" assume_yes="${3:-0}" reply=""
    if [ "${dry_run}" -eq 1 ]; then
        export VAULT_SETUP_DRY_RUN=1; CONSENT_MODE="plan-only"; return 0
    fi
    if [ "${assume_yes}" -eq 1 ]; then
        export VAULT_SETUP_DRY_RUN=0; CONSENT_MODE="apply"; return 0
    fi
    printf '\n%s\nProceed? [y/N] ' "${what}"
    if read -r reply </dev/tty 2>/dev/null && { [ "${reply}" = "y" ] || [ "${reply}" = "Y" ]; }; then
        export VAULT_SETUP_DRY_RUN=0; CONSENT_MODE="apply"
    else
        export VAULT_SETUP_DRY_RUN=1; CONSENT_MODE="plan-only"
    fi
}

# safe_rm_under_home <path>... — refuse to delete anything that is not a real
# path *under* a sane $HOME. Guards the classic expansion bug: with HOME unset or
# empty, "${HOME}/.foo" becomes "/.foo" and set -u does NOT catch it.
safe_rm_under_home() {
    local p
    if [ -z "${HOME:-}" ] || [ "${HOME}" = "/" ]; then
        warn "HOME is empty or '/' — refusing to delete anything"; return 1
    fi
    for p in "$@"; do
        case "$p" in
            "${HOME}"/?*) ;;
            *) warn "refusing to delete '${p}' — not under ${HOME}"; return 1 ;;
        esac
        [ -e "$p" ] || { info "already absent: ${p}"; continue; }
        run rm -rf "$p"
    done
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
    local cfg="${VAULT_HOME:-${HOME}/vault}/_global/config.md" mode=""
    [ -f "${cfg}" ] && mode="$(sed -n 's/^install_mode:[[:space:]]*//p' "${cfg}" | head -1)"
    [ -n "${mode}" ] && info "install: ${mode}"

    # Serena ships only in the --full (developer) profile. An empty box next to
    # it on a light install is expected, not a fault — the label says so, and it
    # never affects the exit code. See ADR-021.
    _doctor_row "uv"                       have uv || true
    _doctor_row "serena (developer)"       check_serena || true
    _doctor_row "claude CLI"               claude_cli_ok || true

    if [ "${#TOOLS_FAILED[@]}" -gt 0 ]; then
        warn "install steps that failed: ${TOOLS_FAILED[*]}"
        failed_required=1
    fi
    return "${failed_required}"
}
