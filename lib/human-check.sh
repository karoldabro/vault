#!/usr/bin/env bash
# human-check.sh — the check behind `bin/gate.sh human`. Sourced by gate.sh, never run on its own.
#
# Contract: commands/_shared/human-plan.md owns the gate order and the message text. This file
# implements it and states none of it again.
#
# It uses these from gate.sh and lib/arch-check.sh: GATE_VAULT_ROOT, violations, die, arch_fm_value,
# arch_cleanup.

HUMAN_TMP=""

human_cleanup() { [ -z "$HUMAN_TMP" ] || rm -rf "$HUMAN_TMP"; }

# human_refuse <plan> <problem>
human_refuse() {
    printf 'REFUSED human %s: %s\n' "$1" "$2" >&2
    violations=$((violations + 1))
}

# human_first_diff <fresh> <page>: the 1-based line where the two files first differ.
human_first_diff() {
    awk -v a="$1" -v b="$2" 'BEGIN {
        while ((getline x < a) > 0) { n++; if ((getline y < b) <= 0 || x != y) { print n; exit } }
        if ((getline y < b) > 0) print n + 1; else print n
    }'
}

# cmd_human <plan> [--repo <root>]
cmd_human() {
    local plan="" repo="" raw as hp id page name fresh n ok=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --repo) [ -z "$repo" ] || die "--repo given twice"
                    repo=${2:-}; [ -n "$repo" ] || die "--repo needs a directory"; shift 2 ;;
            -*)     die "unknown option: $1" ;;
            *)      [ -z "$plan" ] || die "human takes one plan"; plan=$1; shift ;;
        esac
    done
    [ -n "$plan" ] || die "no plan given"
    repo=${repo:-$PWD}
    [ -d "$repo" ] || die "not a directory: $repo"
    { [ -f "$plan" ] && [ -r "$plan" ]; } || die "cannot read: $plan"

    human_cleanup
    HUMAN_TMP=$(mktemp -d)
    trap 'human_cleanup; arch_cleanup' EXIT
    raw="$HUMAN_TMP/plan.raw"
    tr -d '\r' < "$plan" > "$raw"

    as=$(arch_fm_value "$raw" arch_spec)
    [ -n "$as" ] || return 0
    hp=$(arch_fm_value "$raw" human_plan)
    page="${plan%.md}.human.html"
    name=$(basename "$page")

    if [ -z "$hp" ]; then human_refuse "$plan" "plan names no human_plan"; return 0; fi
    case "$hp" in
        https://claude.ai/artifact/*) id=${hp#https://claude.ai/artifact/}; [[ $id =~ ^[A-Za-z0-9]+$ ]] && ok=1 ;;
        file:*)                       [ "${hp#file:}" = "$name" ] && ok=1 ;;
    esac
    if [ "$ok" != 1 ]; then
        human_refuse "$plan" "human_plan must be an https://claude.ai/artifact/<id> URL or file:<page name>"; return 0
    fi
    if [ ! -f "$page" ]; then human_refuse "$plan" "human page is missing: $page"; return 0; fi

    fresh="$HUMAN_TMP/fresh.html"
    if ! "$GATE_VAULT_ROOT/bin/render-human.sh" "$plan" --repo "$repo" --stdout > "$fresh" 2> "$HUMAN_TMP/err"; then
        n=$(cat "$HUMAN_TMP/err")
        die "render failed: ${n#gate: }"
    fi
    if ! cmp -s "$fresh" "$page"; then
        n=$(human_first_diff "$fresh" "$page")
        human_refuse "$plan" "human page is stale: first difference at line ${n:-1}"; return 0
    fi
    printf 'human: ok %s\n' "$page"
    return 0
}
