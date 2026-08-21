#!/usr/bin/env bash
# PostToolUse hook: lint a markdown document Claude just wrote, and hand the findings back to it.
#
# Prose rules alone do not shorten documents — the vault framework has shipped a communication
# contract since ADR-018 and plans still reached 1,500 lines. This is the trigger that makes the
# document standard enforceable rather than optional.
#
# Never blocks and never prompts. It prints findings to stderr with exit 2, which Claude Code feeds
# back to the model as tool feedback; the write has already happened either way.
#
# Ships in the framework repo as scripts/doc-lint-hook.sh. A plugin install picks it up from
# hooks/hooks.json; a symlink install links it into ~/.claude/hooks/ and registers it in
# settings.json, the same way commands/ and output-styles/ are installed.
#
# Rules: commands/_shared/document-standard.md
# Linter: bin/doc-lint.sh  (skips records, instruction files and non-documents)
# Off:    DOC_LINT=off, or a `.doc-lint` file in the repo to exempt named checks with a reason.

set -uo pipefail

[ "${DOC_LINT:-}" = "off" ] && exit 0

# Resolve the framework from this script's own location, following the install symlink. The hook
# ships inside the repo, so it always finds its own linter — no env var, no hardcoded home path.
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
VAULT_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$SELF")/.." && pwd)}"
LINT="${VAULT_ROOT}/bin/doc-lint.sh"
[ -x "$LINT" ] || exit 0

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)"

[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0
case "$file" in *.md|*.markdown) ;; *) exit 0 ;; esac

out="$("$LINT" "$file" 2>&1)" && exit 0

# Cap the feedback. A brevity tool that answers with ninety lines has failed at its own job, and a
# long hook message costs the same context the standard exists to protect. Past a dozen findings the
# per-line detail stops informing: one line per check with a count says the same thing.
n="$(printf '%s\n' "$out" | grep -cE '^  [A-Z]' || true)"
if [ "${n:-0}" -gt 12 ]; then
    body="$(printf '%s\n' "$out" | head -1
            printf '%s\n' "$out" | grep -E '^  [A-Z]' \
              | awk '{code=$1; loc=$2; $1=""; $2=""; sub(/^  */,""); 
                     if (!(code in msg)) { msg[code]=$0; first[code]=loc }
                     cnt[code]++ }
                    END { for (c in cnt)
                            printf "  %-6s x%-4s %s (first: %s)\n", c, cnt[c], msg[c], first[c] }' \
              | sort)"
else
    body="$out"
fi

# Exit 2 so the text reaches the model as feedback rather than the user as noise.
{
    printf 'doc-lint on the file you just wrote:\n\n%s\n\n' "$body"
    printf 'Fix these before handing the path over. Rules:\n'
    printf '%s/commands/_shared/document-standard.md\n' "$VAULT_ROOT"
    printf 'History and process belong in a sibling record file, not in this one.\n'
    [ "${n:-0}" -gt 12 ] && printf 'Full list: %s "%s"\n' "$LINT" "$file"
} >&2
exit 2
