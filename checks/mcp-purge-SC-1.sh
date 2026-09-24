#!/usr/bin/env bash
# SC-1 of vault/plans/2026-09-24-1651-remove-mcp-tools.md — no file in the repo names the removed
# memory plugin or the removed edit MCP, except the files whose job is to name them.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
pattern='claude-mem|claudemem|claude_mem|mcp-search|thedotmack|get_observations|morphllm|morph_edit|morph-mcp|fast[ -]apply|\bmorph\b|with-morph|\bbun\b|graphify|graph\.json'
# Tool names that are also ordinary words match case-sensitively: `magic` is a real vault's name.
cased='Context7|`Sequential`|`Magic`'
# The files allowed to name them: the uninstall guide, the decision that removed them, this plan's
# own files and checks, the session that records the removal, and the one test file that proves the
# removed flags are refused. `graphify-out/` is the old graph
# output itself, deleted by following the uninstall guide.
allow='^(docs/uninstall-removed-tools\.md|vault/decisions/ADR-032-remove-memory-and-edit-mcps\.md|vault/plans/2026-09-24-1651-remove-mcp-tools\..*|checks/mcp-purge-SC-[0-9]+\.sh|vault/sessions/2026-09-24-[0-9]{4}-remove-mcp-tools\.md|tests/unit/setup-autoinstall\.bats)$'
files=$(git ls-files -co --exclude-standard -- ':!graphify-out') || exit 2
hits=$(printf '%s\n' "$files" | grep -vE "$allow" | while IFS= read -r f; do
    [ -f "$f" ] || continue
    { grep -IliE "$pattern" -- "$f" || grep -IlE "$cased" -- "$f"; } 2>/dev/null
done)
if [ -n "$hits" ]; then
    printf 'still names a removed tool:\n%s\n' "$hits"
    exit 1
fi
exit 0
