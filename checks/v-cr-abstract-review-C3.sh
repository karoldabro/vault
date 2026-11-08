#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question. C3 of vault/plans/2026-10-24-1903-v-cr-abstract-review.md.
# Reads two saved reviews: the seeded run and the clean control run (defaults: the plan's c3-run and
# c3-control-run files; arguments 1 and 2 override). Rebuilds both fixture repos with
# tests/fixtures/v-cr-seeded/mk-repo.sh and re-checks every anchor at the fixture head.
# Met when both runs' `Spawned:` lines name the five review seats, and in the seeded run:
#   change-impact        has a confirmed finding citing bin/report.sh:<n> whose head line calls format_row
#   test-gap             has a confirmed finding naming slug_make, and the fixture has no test naming it
#   pattern-conformance  has a confirmed finding naming _need_args and citing lib/slug.sh:<n> that exists
# and the control run has no confirmed BLOCKER or MAJOR finding, with or without evidence.
# A seeded-run finding counts only when its check field holds a backticked command or a path:line.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
plan="$root/vault/plans/2026-10-24-1903-v-cr-abstract-review"
run="${1:-$plan.c3-run.md}"
control="${2:-$plan.c3-control-run.md}"
mk="$root/tests/fixtures/v-cr-seeded/mk-repo.sh"
for f in "$run" "$control"; do [ -f "$f" ] || { printf 'no saved review at %s\n' "$f"; exit 2; }; done
[ -f "$mk" ] || { printf 'fixture builder %s not written yet\n' "$mk"; exit 1; }

tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
# shellcheck source=/dev/null
. "$mk"
mkdir -p "$tmp/seeded" "$tmp/clean"
vs_mk_repo "$tmp/seeded" >/dev/null 2>&1 || { printf 'vs_mk_repo failed\n'; exit 2; }
vs_mk_clean_repo "$tmp/clean" >/dev/null 2>&1 || { printf 'vs_mk_clean_repo failed\n'; exit 2; }
seeded="$tmp/seeded"

seats_ok() { # <file>
    local spawned seat
    spawned=$(grep -E '^[[:space:]]*Spawned:' "$1" | head -1)
    [ -n "$spawned" ] || { printf '%s has no Spawned: line\n' "$1"; return 1; }
    for seat in change-impact test-gap architecture-fit pattern-conformance intent-trace; do
        printf '%s' "$spawned" | grep -qw -- "$seat" || { printf 'Spawned: in %s does not name %s\n' "$1" "$seat"; return 1; }
    done
}

# Prints one line per confirmed finding with evidence: persona<TAB>severity<TAB>flattened check+target+issue.
confirmed() { # <file> [any] — with `any`, a confirmed finding counts without evidence in its check field
    awk -v any="${2:-}" '
        function flush() {
            if (inb && g == "confirmed" && (any == "any" || chk ~ /`[a-z][^`]* [^`]*`/ || chk ~ /[A-Za-z0-9_.\/~-]+\.[A-Za-z0-9]+:[0-9]+/))
                printf "%s\t%s\t%s %s\n", persona, sev, chk, txt
            inb = 0; g = ""; sev = ""; chk = ""; txt = ""; key = ""
        }
        /^[[:space:]]*PERSONA:/ { flush(); p = $0; sub(/^[[:space:]]*PERSONA:[[:space:]]*/, "", p); sub(/[[:space:]].*/, "", p); n = split(p, parts, "/"); persona = parts[n]; inf = 0; next }
        /^[A-Z_]+:/ { flush(); inf = ($0 ~ /^FINDINGS:/); next }
        !inf { next }
        /^[[:space:]]*-[[:space:]]+id:/ { flush(); inb = 1; match($0, /^[[:space:]]*/); ind = RLENGTH; next }
        !inb { next }
        /^[[:space:]]+(severity|grounding|check|target|issue|recommendation):/ {
            line = $0; sub(/^[[:space:]]+/, "", line); key = line; sub(/:.*/, "", key); val = line; sub(/^[a-z]+:[[:space:]]*/, "", val)
            if (key == "grounding") { g = val; sub(/[[:space:]].*/, "", g) }
            else if (key == "severity") { sev = val; sub(/[[:space:]].*/, "", sev) }
            else if (key == "check") chk = val
            else if (key == "target" || key == "issue") txt = txt " " val
            next
        }
        { match($0, /^[[:space:]]*/); if (RLENGTH <= ind) { key = ""; next }
          if (key == "check") chk = chk " " $0; else if (key == "target" || key == "issue") txt = txt " " $0 }
        END { flush() }
    ' "$1"
}

seats_ok "$run" || exit 1
seats_ok "$control" || exit 1

rows=$(confirmed "$run")
hit_impact=0 hit_test=0 hit_pattern=0
while IFS=$'\t' read -r persona _sev text; do
    case $persona in
        change-impact)
            for n in $(printf '%s' "$text" | grep -oE 'bin/report\.sh:[0-9]+' | cut -d: -f2); do
                git -C "$seeded" show HEAD:bin/report.sh | sed -n "${n}p" | grep -q 'format_row' && hit_impact=1
            done ;;
        test-gap)
            printf '%s' "$text" | grep -q 'slug_make' \
                && [ -z "$(git -C "$seeded" grep -lw slug_make HEAD -- tests 2>/dev/null)" ] && hit_test=1 ;;
        pattern-conformance)
            if printf '%s' "$text" | grep -q '_need_args'; then
                total=$(git -C "$seeded" show HEAD:lib/slug.sh 2>/dev/null | wc -l)
                for n in $(printf '%s' "$text" | grep -oE 'lib/slug\.sh:[0-9]+' | cut -d: -f2); do
                    [ "$n" -ge 1 ] && [ "$n" -le "$total" ] && hit_pattern=1
                done
            fi ;;
    esac
done <<< "$rows"

missing=''
[ "$hit_impact" -eq 1 ] || missing="$missing change-impact:bin/report.sh"
[ "$hit_test" -eq 1 ] || missing="$missing test-gap:slug_make"
[ "$hit_pattern" -eq 1 ] || missing="$missing pattern-conformance:_need_args"
[ -z "$missing" ] || { printf 'no confirmed finding with a valid anchor for:%s\n' "$missing"; exit 1; }

dirty=$(confirmed "$control" any | awk -F'\t' '$2 == "BLOCKER" || $2 == "MAJOR"' | wc -l | tr -d ' ')
[ "$dirty" -eq 0 ] || { printf 'the clean control run has %s confirmed BLOCKER or MAJOR findings\n' "$dirty"; exit 1; }
printf 'all three planted defects found with valid anchors; the control run is clean\n'
exit 0
