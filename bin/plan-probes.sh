#!/usr/bin/env bash
# plan-probes.sh — the tier, verify and measure steps of the plan-time probe stage of /v-team PROPOSE.
#
# Usage:  bin/plan-probes.sh budget --critics <n> --rounds <n> --block <file> --out <dir>
#         bin/plan-probes.sh verify <out-dir> [<auditor-rows-file>...]
#         bin/plan-probes.sh measure <transcript.jsonl> --from <timestamp> --to <timestamp>
#         bin/plan-probes.sh probes
#         bin/plan-probes.sh auditors
#
# budget   projects what the stage adds to a PROPOSE and prints `tier: full|block-only|skip`, a `projected:` line and,
#          unless the tier is full, one `note:` line. It writes <dir>/tier.txt.
# verify   reads the block's rows in <out-dir> (bin/probe-panel.sh writes them). It prints `open:` for every
#          `[confirmed]` error row, the block's own copy of each auditor line that equals a block row, and `note:` lines.
#          Exit 1 when an open row exists, 2 when <out-dir>/tier.txt is missing or invalid.
# measure  prints the fresh tokens of a session transcript and its subagent files inside a time window.
# Contract and settings: commands/_shared/plan-probes.md.
#
# Exit: 0 done · 1 verify found an open row · 2 usage error or unreadable input

set -uo pipefail
export LC_ALL=C
IFS=$' \t\n'
T=$'\t'

PLAN_PROBE_LIMIT_PERCENT=${PLAN_PROBE_LIMIT_PERCENT:-50}
PLAN_PROBE_BASE_TOKENS=${PLAN_PROBE_BASE_TOKENS:-390000}
PLAN_PROBE_CRITIC_TOKENS=${PLAN_PROBE_CRITIC_TOKENS:-140000}
PLAN_PROBE_AUDITOR_TOKENS=${PLAN_PROBE_AUDITOR_TOKENS:-36000}
PLAN_PROBE_BYTES_PER_TOKEN=${PLAN_PROBE_BYTES_PER_TOKEN:-4}

die() { printf 'plan-probes: %s\n' "$*" >&2; exit 2; }
usage() { sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
clean() { LC_ALL=C tr '\000-\037\177' ' ' | LC_ALL=C cut -c1-240; }
# keeps tabs and newlines, for lines that carry fields
strip() { LC_ALL=C tr '\000-\010\013-\037\177' ' '; }

# num <name> <value> <min> <max> — a whole number from <min> to <max> without a leading zero, else exit 2 naming <name>.
# The maxima keep every product of the projection inside 64-bit arithmetic.
num() {
    case $2 in
        0) [ "$3" -eq 0 ] || die "$1 must be a whole number from $3 to $4" ;;
        ''|*[!0-9]*|0*) die "$1 must be a whole number from $3 to $4" ;;
    esac
    [ "${#2}" -le 12 ] && [ "$2" -le "$4" ] && [ "$2" -ge "$3" ] || die "$1 must be a whole number from $3 to $4"
}
settings() {
    num PLAN_PROBE_LIMIT_PERCENT "$PLAN_PROBE_LIMIT_PERCENT" 0 1000
    num PLAN_PROBE_BASE_TOKENS "$PLAN_PROBE_BASE_TOKENS" 1 100000000
    num PLAN_PROBE_CRITIC_TOKENS "$PLAN_PROBE_CRITIC_TOKENS" 0 100000000
    num PLAN_PROBE_AUDITOR_TOKENS "$PLAN_PROBE_AUDITOR_TOKENS" 0 100000000
    num PLAN_PROBE_BYTES_PER_TOKEN "$PLAN_PROBE_BYTES_PER_TOKEN" 1 1000000
}

# The plan-time probes and the auditors that read them. Questions: commands/_shared/plan-probes.md.
PLAN_PROBES="similar-symbols spec-symbols spec-tables spec-naming"
AUDITORS="reuse${T}similar-symbols spec-symbols
data-model${T}spec-tables
naming${T}spec-naming"

pp_budget() {
    local critics="" rounds="" block="" out=""
    while [ $# -gt 0 ]; do
        case $1 in
            --critics|--rounds|--block|--out)
                [ $# -ge 2 ] || die "$1 needs a value"
                case $1 in --critics) critics=$2 ;; --rounds) rounds=$2 ;; --block) block=$2 ;; --out) out=$2 ;; esac
                shift 2 ;;
            *) die "unknown option: $1" ;;
        esac
    done
    settings
    [ -n "$critics" ] || die "--critics is required"; num --critics "$critics" 1 1000000
    [ -n "$rounds" ] || die "--rounds is required"; num --rounds "$rounds" 1 1000000
    [ -n "$block" ] || die "--block is required"
    [ -n "$out" ] || die "--out is required"
    [ -f "$block" ] && [ -r "$block" ] || die "--block needs a readable file: $block"

    local bytes bt n aud=0 base limit_pct added_block added_full added tier pct note id aname probes trig
    bytes=$(wc -c < "$block" | tr -d ' ')
    bt=$(( (bytes + PLAN_PROBE_BYTES_PER_TOKEN - 1) / PLAN_PROBE_BYTES_PER_TOKEN ))
    n=$((critics * rounds))
    while IFS=$T read -r aname probes; do
        [ -n "$aname" ] || continue
        trig=0
        for id in $probes; do
            if grep -q "^$id$T" "$block"; then trig=1; fi
        done
        aud=$((aud + trig))
    done <<< "$AUDITORS"
    base=$((PLAN_PROBE_BASE_TOKENS + PLAN_PROBE_CRITIC_TOKENS * n))
    limit_pct=$PLAN_PROBE_LIMIT_PERCENT
    added_block=$((bt * (n + 1)))
    added_full=$((added_block + aud * PLAN_PROBE_AUDITOR_TOKENS))
    if [ $((added_full * 100)) -le $((base * limit_pct)) ]; then tier=full; added=$added_full
    elif [ $((added_block * 100)) -le $((base * limit_pct)) ]; then tier=block-only; added=$added_full
    else tier=skip; added=$added_block; fi
    pct=$((added * 100 / base))
    mkdir -p -- "$out" || die "cannot create $out"
    [ ! -L "$out/tier.txt" ] || die "$out/tier.txt is a symlink"
    printf '%s\n' "$tier" > "$out/tier.txt"
    printf 'tier: %s\n' "$tier"
    printf 'projected: added=%s baseline=%s percent=%s\n' "$added" "$base" "$pct"
    case $tier in
        block-only) note="plan-time probes ran without the auditor: they would add about $pct% to this planning run against a $limit_pct% limit (round cost projected)" ;;
        skip) note="plan-time probes were skipped: they would add about $pct% to this planning run against a $limit_pct% limit (round cost projected)" ;;
        *) note="" ;;
    esac
    [ -z "$note" ] || printf 'note: %s\n' "$note"
    return 0
}

pp_verify() {
    local out=${1:-}
    [ -n "$out" ] || die "verify needs <out-dir>"
    shift || true
    [ -d "$out" ] && [ -r "$out" ] || die "not a readable directory: $out"
    [ -r "$out/tier.txt" ] || die "$out/tier.txt is missing: run 'plan-probes.sh budget' first"
    case $(head -1 "$out/tier.txt" | tr -d '\r') in full|block-only|skip) ;; *) die "$out/tier.txt holds no tier" ;; esac
    local rows; for rows in "$@"; do [ -r "$rows" ] || die "not a readable file: $rows"; done
    local g open=0
    for g in confirmed advisory; do [ -e "$out/$g.tsv" ] || : > "$out/$g.tsv" 2>/dev/null || true; done

    # An open row is a [confirmed] error row of the block. No verdict and no tier changes that.
    while IFS= read -r line || [ -n "$line" ]; do
        [ -n "$line" ] || continue
        IFS=$'\t' read -r p f l s r m <<< "$line"
        [ "$s" = error ] || continue
        open=$((open + 1))
        printf 'open: %s %s:%s %s\n' "$(printf '%s' "$p" | clean)" "$(printf '%s' "$f" | clean)" "$(printf '%s' "$l" | clean)" "$(printf '%s' "$m" | clean)"
    done < <(cat "$out/confirmed.tsv" 2>/dev/null)

    # Each auditor line is kept only when its row equals a block row byte for byte and its verdict is on the
    # list. Applied to every rows-file independently, in argument order; dropped counts sum across all of them.
    local total_dropped=0 kept_probes; kept_probes=$(mktemp "${TMPDIR:-/tmp}/plan-probes.XXXXXX") || die "cannot create a temp file"
    for rows in "$@"; do
        local dropped kept; kept=$(mktemp "${TMPDIR:-/tmp}/plan-probes.XXXXXX") || die "cannot create a temp file"
        LC_ALL=C awk -F'\t' -v OFS='\t' '
            FILENAME == ARGV[1] { block[$0] = 1; next }
            { line = $0
              if (line == "" || line ~ /\r$/) next
              v = $1; row = substr(line, length(v) + 2)
              if (v != "applies" && v != "does-not-apply" && v != "unclear") next
              if (!(row in block)) next
              if (seen[line]++) next
              print v, row }
        ' <(cat "$out/confirmed.tsv" "$out/advisory.tsv" 2>/dev/null) "$rows" > "$kept"
        strip < "$kept"
        LC_ALL=C awk -F'\t' '{ print $2 }' "$kept" >> "$kept_probes"
        rm -f "$kept"
        dropped=$(LC_ALL=C awk -F'\t' '
            FILENAME == ARGV[1] { block[$0] = 1; next }
            { line = $0; if (line == "") next
              v = $1; row = substr(line, length(v) + 2)
              if (line !~ /\r$/ && (v == "applies" || v == "does-not-apply" || v == "unclear") && (row in block)) next
              d++ }
            END { print d + 0 }
        ' <(cat "$out/confirmed.tsv" "$out/advisory.tsv" 2>/dev/null) "$rows")
        total_dropped=$((total_dropped + dropped))
    done
    [ "$total_dropped" -eq 0 ] || printf 'note: %s auditor lines were dropped: not a block row or not a valid verdict\n' "$total_dropped"

    # A triggered auditor (one of its probes has a block row) with no kept line of its own: nothing
    # represented it among the rows-files passed, and that verdict silently never reaches the operator.
    local aname probes id triggered has_kept
    while IFS=$T read -r aname probes; do
        [ -n "$aname" ] || continue
        triggered=0; has_kept=0
        for id in $probes; do
            if grep -q "^$id$T" "$out/confirmed.tsv" "$out/advisory.tsv" 2>/dev/null; then triggered=1; fi
            if grep -qx "$id" "$kept_probes" 2>/dev/null; then has_kept=1; fi
        done
        [ "$triggered" -eq 0 ] || [ "$has_kept" -eq 1 ] || printf 'note: the %s auditor triggered but no rows-file for it was passed to verify\n' "$(printf '%s' "$aname" | clean)"
    done <<< "$AUDITORS"
    rm -f "$kept_probes"

    # A tool that is absent or a run that is incomplete: the panel wrote the reason to operator.txt.
    if [ -s "$out/operator.txt" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            [ -n "$line" ] || continue
            printf 'note: %s\n' "$(printf '%s' "$line" | clean)"
        done < "$out/operator.txt"
    fi
    [ "$open" -eq 0 ] || return 1
    return 0
}

pp_measure() {
    local tr=${1:-}; shift || true
    local from="" to=""
    while [ $# -gt 0 ]; do
        case $1 in
            --from|--to) [ $# -ge 2 ] || die "$1 needs a value"; if [ "$1" = --from ]; then from=$2; else to=$2; fi; shift 2 ;;
            *) die "unknown option: $1" ;;
        esac
    done
    [ -n "$tr" ] && [ -f "$tr" ] && [ -r "$tr" ] || die "measure needs a readable transcript: $tr"
    command -v jq >/dev/null 2>&1 || die "jq is absent"
    [ -n "$from" ] || die "--from is required"; [ -n "$to" ] || die "--to is required"
    local ts='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?Z$'
    [[ $from =~ $ts ]] || die "--from is not a UTC timestamp like 2026-09-21T12:16:00Z"
    [[ $to =~ $ts ]] || die "--to is not a UTC timestamp like 2026-09-21T12:16:00Z"
    local files=("$tr") f dir=${tr%.jsonl}/subagents
    if [ -d "$dir" ]; then
        while IFS= read -r f; do files+=("$f"); done < <(find "$dir" -maxdepth 1 -type f -name 'agent-*.jsonl' | LC_ALL=C sort)
    fi
    local prog='
      def n(x): (x | tonumber? // 0);
      def secs: (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) + ((capture("\\.(?<f>[0-9]+)Z$")? | ("0." + .f) | tonumber) // 0);
      ($from | secs) as $a | ($to | secs) as $b |
      if $a > $b then error("from is after to") else . end |
      split("\n") | map(select(length > 0) | (try fromjson catch null)) as $all
      | ($all | map(select(. == null)) | length) as $bad
      | ($all | map(select(. != null))
        | [ .[] | select(type == "object" and .type == "assistant" and (.message | type) == "object"
                         and (.message.id | type) == "string" and (.message.usage | type) == "object"
                         and (.timestamp | type) == "string")
                | {id: .message.id, t: (.timestamp | try secs catch null), u: .message.usage}
                | select(.t != null) ]
        | group_by(.id)
        | map({t: (map(.t) | min), u: (max_by(n(.u.output_tokens)) | .u)})
        | map(select(.t >= $a and .t <= $b))
        | {messages: length,
           fresh: (map(n(.u.input_tokens) + n(.u.cache_creation_input_tokens) + n(.u.output_tokens)) | add // 0),
           cache_read: (map(n(.u.cache_read_input_tokens)) | add // 0),
           bad: $bad})'
    local tf=0 tc=0 tm=0 res
    for f in "${files[@]}"; do
        res=$(jq -Rs --arg from "$from" --arg to "$to" "$prog" "$f" 2>&1) || die "cannot read $f: $(printf '%s' "$res" | head -1)"
        local fr cr ms bad
        fr=$(jq -r .fresh <<< "$res"); cr=$(jq -r .cache_read <<< "$res"); ms=$(jq -r .messages <<< "$res"); bad=$(jq -r .bad <<< "$res")
        [ "$bad" -eq 0 ] || printf 'plan-probes: skipped %s line(s) that are not JSON in %s\n' "$bad" "$(basename "$f")" >&2
        printf '%s\tfresh=%s\tcache_read=%s\tmessages=%s\n' "$(printf '%s' "$(basename "$f")" | clean)" "$fr" "$cr" "$ms"
        tf=$((tf + fr)); tc=$((tc + cr)); tm=$((tm + ms))
    done
    printf 'total\tfresh=%s\tcache_read=%s\tmessages=%s\n' "$tf" "$tc" "$tm"
}

case ${1:-} in
    budget)   shift; pp_budget "$@" ;;
    verify)   shift; pp_verify "$@" ;;
    measure)  shift; pp_measure "$@" ;;
    probes)   printf '%s\n' $PLAN_PROBES ;;
    auditors) printf '%s\n' "$AUDITORS" ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 2 ;;
esac
