#!/usr/bin/env bash
# SC-2 of vault/plans/2026-09-22-0900-stack-packs.md — a real PHPStan run inside recycling-api's own
# Docker image, via that repo's own repo-scoped registry row. Exit 0 met, 1 not met, 2 cannot read.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
repo=/home/kdabrow/workspace/recycling-api
[ -d "$repo" ] || { echo "recycling-api is not checked out at $repo"; exit 2; }
[ -x "$root/bin/probe.sh" ] || { echo "bin/probe.sh is not executable"; exit 2; }
changed=$(mktemp)
printf 'app/Http/Controllers/SeoMediaController.php\0' > "$changed"
out=$(PROBE_TIMEOUT=180 "$root/bin/probe.sh" diff --repo "$repo" --allow-repo-registry --only laravel-phpstan-docker \
    --changed-list "$changed" 2>&1 1>/dev/null) || true
rm -f "$changed"
printf '%s\n' "$out" | grep -q '^ran: laravel-phpstan-docker:' || { echo "no ran: laravel-phpstan-docker: line: $out"; exit 1; }
exit 0
