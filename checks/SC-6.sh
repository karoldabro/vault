#!/usr/bin/env bash
# SC-6: the instruction corpus carries fewer rule-lines than the 173 it started with, and more
# requirements than prohibitions. Fails until D-01 builds the counter. Red now, green when it lands.
set -uo pipefail
[ -x bin/rule-count.sh ] || { printf 'bin/rule-count.sh does not exist yet (D-01)\n'; exit 1; }
./bin/rule-count.sh --assert
