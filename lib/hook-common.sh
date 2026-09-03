#!/usr/bin/env bash
# Shared bootstrap for the framework's Claude Code hooks: scripts/doc-lint-hook.sh,
# scripts/output-lint-hook.sh and scripts/brevity-reminder-hook.sh.
#
# Each hook ships inside the repo and must find the framework from its own location on both install
# shapes — a plugin install sets CLAUDE_PLUGIN_ROOT, a symlink install does not and the script is
# reached through a symlink in ~/.claude/hooks/.
#
# A hook that cannot do its job exits 0. Never block a turn, never prompt.

# hook_off <ENV_VAR_NAME>
# True when the named variable is set to "off". Callers exit 0 on a true result.
hook_off() {
    local _name="$1"
    [ "${!_name:-}" = "off" ]
}

# hook_vault_root <path-to-hook-script>
# Prints the framework root. Pass "${BASH_SOURCE[0]}" of the calling hook.
hook_vault_root() {
    local _self
    _self="$(readlink -f "$1")"
    printf '%s' "${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${_self}")/.." && pwd)}"
}

# hook_json_field <payload> <jq-expression>
# Prints the field, or nothing when jq is missing or the payload does not parse.
hook_json_field() {
    printf '%s' "$1" | jq -r "$2" 2>/dev/null || true
}

# hook_state_path <session_id>
# The per-session brevity state file. Prints nothing and returns 1 for a session id that is not a
# plain token, because this value reaches a filename.
#
# One definition, because the Stop hook writes this path and the UserPromptSubmit hook reads it: two
# copies would let the name drift apart, and the only symptom is a reminder that silently never
# speaks again.
hook_state_path() {
    local _session="${1:-}"
    [ -n "${_session}" ] || return 1
    case "${_session}" in *[!A-Za-z0-9_-]*) return 1 ;; esac
    printf '%s/.claude/brevity-state.%s.json' "${HOME}" "${_session}"
}
