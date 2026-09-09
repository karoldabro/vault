#!/usr/bin/env bash
# SC-1 — the routing, bucketing and merge cases pass.
#
# Wraps tests/unit/cr-rule-routing.bats so bin/gate.sh can grade it. The bats file is the
# authority; this script exists only because a criterion must name a committed executable.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bats="$root/tests/unit/cr-rule-routing.bats"

[ -f "$bats" ] || { printf '  MISSING  %s does not exist yet\n' "$bats"; exit 1; }
"$root/tests/run.sh" tests/unit/cr-rule-routing.bats
