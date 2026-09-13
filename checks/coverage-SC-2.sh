#!/usr/bin/env bash
# SC-2 (delivery) — the shipped approval gate grades a real plan through the real path.
#
# SC-1 proves the behaviour on fixtures. This proves the thing an operator actually hits: the
# `--phase approve` path, on a plan committed in this repo, through the installed `bin/gate.sh`.
#
# Two halves, because each covers the other's blind spot. A gate wired to nothing passes the first;
# a gate that refuses everything passes a "nonzero means it bit" second. So the refusal must be
# exit 1 — not the exit 2 that an unreadable table or an unknown subcommand returns — and it must
# name the criterion it rejected.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
plan="$root/vault/plans/2026-09-13-1447-coverage-and-failed-sessions.md"
fail=0

[ -x "$gate" ] || { printf '  MISSING  %s\n' "$gate"; exit 1; }
[ -r "$plan" ] || { printf '  MISSING  %s\n' "$plan"; exit 1; }

out=$("$gate" all "$plan" --phase approve 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then
    printf '  FAIL  the approve phase exited %s on its own plan\n%s\n' "$rc" "$out"; fail=1
fi

# Empty every `covers` cell in a copy. The gate must then refuse, with exit 1, naming a criterion.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
awk '
    /^## Work items/ { inwork = 1 }
    inwork && /^## / && !/^## Work items/ { inwork = 0 }
    inwork && /^\| W-/ {
        n = split($0, c, "|")
        for (i = 1; i <= n; i++) if (c[i] ~ /SC-[0-9]/) c[i] = "  "
        line = c[1]
        for (i = 2; i <= n; i++) line = line "|" c[i]
        print line; next
    }
    { print }
' "$plan" > "$tmp/uncovered.md"

if cmp -s "$plan" "$tmp/uncovered.md"; then
    printf '  FAIL  no `covers` cell was emptied — this half cannot prove the gate bites\n'; fail=1
else
    bout=$("$gate" all "$tmp/uncovered.md" --phase approve 2>&1); brc=$?
    if [ "$brc" -ne 1 ]; then
        printf '  FAIL  the approve phase exited %s on a plan covering nothing; a refusal is exit 1\n%s\n' "$brc" "$bout"; fail=1
    elif ! printf '%s\n' "$bout" | grep -qE 'SC-[0-9]+ is named in no work item'; then
        printf '  FAIL  the refusal names no criterion, so it may be refusing something else\n%s\n' "$bout"; fail=1
    fi
fi

[ "$fail" -eq 0 ] || exit 1
printf '  OK  the approve phase passes its own plan and refuses an uncovered copy with exit 1\n'
