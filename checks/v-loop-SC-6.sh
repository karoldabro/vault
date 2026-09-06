#!/usr/bin/env bash
# SC-7 — the staging guard denies every verb of the action it names, not only `git add`.
#
# A campaign commits unattended. `git add -A` was already denied; `git commit -am` reached the same
# outcome through a different verb and returned clean. Wraps the bats file so bin/gate.sh can grade it.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 1
./tests/run.sh tests/unit/staging-hook.bats
