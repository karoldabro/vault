#!/usr/bin/env bash
# release-check.sh — fail when shipped files changed but plugin.json's version did not.
#
# Claude Code resolves a plugin's version from .claude-plugin/plugin.json and caches on it. If the
# string is unchanged, `/plugin update` and the background auto-update BOTH skip the plugin and
# report "already latest". Pushing to main without a bump therefore reaches nobody, silently — the
# failure mode recorded in vault/decisions/ADR-020-claude-code-plugin-distribution.md.
#
# This turns that silence into an exit code. It compares the working tree against what is published
# (the base ref, default origin/main):
#
#   * no shipped file differs  -> pass. Docs-only and test-only work needs no release.
#   * shipped files differ AND the version differs -> pass.
#   * shipped files differ AND the version is identical -> FAIL. Bump plugin.json.
#
# "Shipped" = everything the plugin cache serves to a user. tests/, vault/ and docs/ are excluded:
# they ride along in the cache but change nothing a user invokes, so requiring a version bump for a
# typo fix in a session log would train people to bump meaninglessly.
#
# There are no release tags in this repo, which is why the base is a branch and not `git describe`.
#
# Usage:  bin/release-check.sh [--base <ref>] [--no-fetch]
# Env:    RELEASE_CHECK_BASE   base ref to compare against    default: origin/main
#
# Exit: 0 pass (or skipped — an unreachable base ref is a warning, never a failure)
#       1 shipped files changed without a version bump

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${RELEASE_CHECK_BASE:-origin/main}"
MANIFEST=".claude-plugin/plugin.json"
do_fetch=1

# Paths that ship in the plugin cache but are not part of what a user invokes.
NOT_SHIPPED='^(tests/|vault/|docs/)'

while [ $# -gt 0 ]; do
    case "$1" in
        --base)     BASE="$2"; shift 2 ;;
        --no-fetch) do_fetch=0; shift ;;
        -h|--help)  sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)          printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

cd "${VAULT_ROOT}"

version_of() {
    # $1 = a git ref, or "-" for the working tree.
    if [ "$1" = "-" ]; then
        grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "${MANIFEST}" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    else
        git show "$1:${MANIFEST}" 2>/dev/null \
            | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

if [ "$do_fetch" -eq 1 ] && [ "${BASE}" != "${BASE#origin/}" ]; then
    git fetch --quiet origin "${BASE#origin/}" 2>/dev/null || true
fi

if ! git rev-parse --verify --quiet "${BASE}" >/dev/null; then
    printf '  [warn] base ref %s is unreachable — skipping the release check\n' "${BASE}" >&2
    exit 0
fi

published="$(version_of "${BASE}")"
current="$(version_of -)"

if [ -z "${current}" ]; then
    printf '  [warn] no version field in %s — skipping\n' "${MANIFEST}" >&2
    exit 0
fi

# Tracked differences plus not-yet-added files: an untracked new command still ships once committed,
# so leaving it out would let the very first version of a feature slip past unbumped.
changed="$( { git diff --name-only "${BASE}" -- .; git ls-files --others --exclude-standard; } \
    | sort -u | grep -Ev "${NOT_SHIPPED}" || true)"

if [ -z "${changed}" ]; then
    printf '  [ok]  no shipped files changed since %s — no release needed\n' "${BASE}"
    exit 0
fi

if [ "${published}" != "${current}" ]; then
    printf '  [ok]  %s -> %s, %s shipped file(s) changed\n' \
        "${published:-<none>}" "${current}" "$(printf '%s\n' "${changed}" | wc -l | tr -d ' ')"
    exit 0
fi

printf '\n  [FAIL] %s shipped file(s) changed since %s, but the plugin version is still %s.\n' \
    "$(printf '%s\n' "${changed}" | wc -l | tr -d ' ')" "${BASE}" "${current}" >&2
printf '         Claude Code caches on that string: publishing this reaches nobody and\n' >&2
printf '         `/plugin update` will report "already latest". Bump %s.\n\n' "${MANIFEST}" >&2
printf '%s\n' "${changed}" | sed 's/^/           /' >&2
printf '\n' >&2
exit 1
