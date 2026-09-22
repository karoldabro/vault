#!/usr/bin/env bash
# SC-6 of vault/plans/2026-09-22-0900-stack-packs.md — a real run against woonuxt reports nuxt-tsc absent.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
repo=/home/kdabrow/workspace/nuxt/woonuxt
[ -d "$repo" ] || { echo "woonuxt is not checked out at $repo"; exit 2; }
[ -x "$root/bin/probe.sh" ] || { echo "bin/probe.sh is not executable"; exit 2; }
out=$("$root/bin/probe.sh" diff --repo "$repo" --only nuxt-tsc 2>&1 1>/dev/null) || true
printf '%s\n' "$out" | grep -q '^absent: nuxt-tsc:' || { echo "no absent: nuxt-tsc: line: $out"; exit 1; }
exit 0
