#!/usr/bin/env bash
# SC-2 of vault/plans/2026-09-24-1651-remove-mcp-tools.md — the real installer, run as a user runs
# it, installs Serena under --full, nothing under --light, and refuses the removed flags.
# Runs setup.sh in dry-run mode against a throwaway HOME, so nothing is installed.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[ -x "$root/setup.sh" ] || { echo "setup.sh is missing"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
envs=(env HOME="$tmp/home" VAULT_HOME="$tmp/home/vault" SETUP_SKIP_INSTALL_SH=1)
mkdir -p "$tmp/home"
fail=0
full=$("${envs[@]}" "$root/setup.sh" --full --dry-run 2>&1) || { echo "--full --dry-run exited nonzero"; echo "$full"; fail=1; }
# A tool already on this machine prints `present` instead of its install command, so the check
# reads the section header the Serena step opens, which prints either way.
grep -q '=== Serena' <<<"$full"   || { echo "--full does not reach the Serena step"; fail=1; }
if grep -qiE 'claude-mem|thedotmack|bun\.com|morph|graphify|pipx' <<<"$full"; then echo "--full still installs a removed tool"; fail=1; fi
light=$("${envs[@]}" "$root/setup.sh" --light --dry-run 2>&1) || { echo "--light --dry-run exited nonzero"; echo "$light"; fail=1; }
if grep -qiE '=== Serena|graphify|claude-mem|bun\.com|pipx' <<<"$light"; then echo "--light installs a tool"; fail=1; fi
"${envs[@]}" "$root/setup.sh" --with-claude-mem >/dev/null 2>&1
[ $? -eq 2 ] || { echo "--with-claude-mem is still accepted"; fail=1; }
for flag in --with-graphify --minimal; do
    "${envs[@]}" "$root/setup.sh" "$flag" >/dev/null 2>&1
    [ $? -eq 2 ] || { echo "$flag is still accepted"; fail=1; }
done
exit "$fail"
