#!/usr/bin/env bash
# Shared detection for "is the vault framework installed as a Claude Code plugin?"
#
# There are two install modes and they are mutually exclusive. A plugin install
# supplies the commands through Claude Code's own loader; install.sh supplies them
# by symlinking into ~/.claude/commands/. Running both installs every command
# twice, under two different names, resolving to two different copies of the files.
#
# Sourced by install.sh and setup.sh. No side effects, no output.

# Overridable so tests can point at a throwaway tree.
VAULT_CLAUDE_DIR="${VAULT_CLAUDE_DIR:-${HOME:-}/.claude}"

# vault_running_from_plugin_cache <framework_root>
# True when the framework files being run live inside Claude Code's plugin cache.
# That directory is versioned and garbage-collected, so symlinking out of it would
# leave dangling links at the next plugin update.
vault_running_from_plugin_cache() {
    case "${1:-}" in
        */.claude/plugins/*) return 0 ;;
        *) return 1 ;;
    esac
}

# vault_plugin_installed
# True when the vault plugin is recorded in this user's Claude Code settings.
# enabledPlugins is keyed "<plugin>@<marketplace>", so "vault@" is an exact-enough
# probe without requiring jq. Checked at both settings scopes Claude Code writes.
vault_plugin_installed() {
    local f
    for f in "${VAULT_CLAUDE_DIR}/settings.json" "${VAULT_CLAUDE_DIR}/settings.local.json"; do
        [ -f "${f}" ] || continue
        grep -q '"vault@' "${f}" 2>/dev/null && return 0
    done
    return 1
}
