#!/usr/bin/env bash
# render-human.sh — write the human plan page for one plan.
#
# Usage:  bin/render-human.sh <plan> [--repo <root>] [--stdout]
#
# Reads the plan and the architecture spec it names, and writes <plan name>.human.html beside the plan,
# or prints the same bytes with --stdout. --repo (default: the working directory) locates the profile
# the spec names. Contract: commands/_shared/human-plan.md.
#
# Exit: 0 written, 2 the plan is unreadable, has no text under ## Task, or a needed file is missing.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=gate.sh
. "$ROOT/bin/gate.sh"
# shellcheck source=../lib/human-render.sh
. "$ROOT/lib/human-render.sh"

plan="" repo="" to_stdout=0
while [ $# -gt 0 ]; do
    case "$1" in
        --repo)   [ -z "$repo" ] || die "--repo given twice"
                  repo=${2:-}; [ -n "$repo" ] || die "--repo needs a directory"; shift 2 ;;
        --stdout) to_stdout=1; shift ;;
        -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*)       die "unknown option: $1" ;;
        *)        [ -z "$plan" ] || die "render-human takes one plan"; plan=$1; shift ;;
    esac
done
[ -n "$plan" ] || die "no plan given"
repo=${repo:-$PWD}
[ -d "$repo" ] || die "not a directory: $repo"

human_render "$plan" "$repo" "$to_stdout"
