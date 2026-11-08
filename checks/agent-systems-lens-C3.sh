#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question. C3 of vault/plans/2026-10-20-1934-agent-systems-lens.md.
# Reads one saved agent-systems review (default: the plan's c3-run file; first argument overrides).
# Parser rules: the plan's `## C3 parser rules`. Met when the file holds `PERSONA: agent-systems`, at
# least 3 FINDINGS blocks are confirmed with a command or a path:line in their check field, and one of
# them names `judge_model` or `sendable_score` in its check or issue field.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
run="${1:-$root/vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md}"
[ -f "$run" ] || { printf 'no saved lens run at %s\n' "$run"; exit 2; }
grep -Eq '^[[:space:]]*PERSONA:[[:space:]]*agent-systems[[:space:]]*$' "$run" \
    || { printf 'the run is not an agent-systems review\n'; exit 1; }

cmd_re='`[a-z][^`]* [^`]*`'
path_re='[A-Za-z0-9_./~-]+\.[A-Za-z0-9]+:[0-9]+([-,][0-9]+)*'
counted=0 judge=0 in_findings=0 in_block=0 id_indent=0 key='' grounding='' check='' issue=''

close_block() {
    [ "$in_block" -eq 1 ] || return 0
    if [ "$grounding" = confirmed ] \
        && { printf '%s' "$check" | grep -Eq "$cmd_re" || printf '%s' "$check" | grep -Eq "$path_re"; }; then
        counted=$((counted + 1))
        printf '%s\n%s' "$check" "$issue" | grep -Eq 'judge_model|sendable_score' && judge=$((judge + 1))
    fi
    in_block=0 key='' grounding='' check='' issue=''
}

while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ ^[A-Z_]+: ]]; then
        close_block
        [[ $line =~ ^FINDINGS: ]] && in_findings=1 || in_findings=0
        continue
    fi
    [ "$in_findings" -eq 1 ] || continue
    if [[ $line =~ ^([[:space:]]*)-[[:space:]]+id: ]]; then
        close_block
        in_block=1
        id_indent=${#BASH_REMATCH[1]}
        continue
    fi
    [ "$in_block" -eq 1 ] || continue
    if [[ $line =~ ^[[:space:]]+(severity|grounding|check|target|issue|recommendation):[[:space:]]*(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        case "$key" in
            grounding) grounding="${value%%[[:space:]]*}" ;;
            check) check="$value" ;;
            issue) issue="$value" ;;
        esac
        continue
    fi
    # A continuation line belongs to the field only when it sits deeper than the block's `- id:`.
    [[ $line =~ ^([[:space:]]*) ]]
    if [ "${#BASH_REMATCH[1]}" -le "$id_indent" ]; then
        key=''
        continue
    fi
    case "$key" in
        check) check="$check"$'\n'"$line" ;;
        issue) issue="$issue"$'\n'"$line" ;;
    esac
done < "$run"
close_block

[ "$counted" -ge 3 ] || { printf '%s confirmed findings with evidence, need 3\n' "$counted"; exit 1; }
[ "$judge" -ge 1 ] || { printf 'no confirmed finding names judge_model or sendable_score\n'; exit 1; }
printf '%s confirmed findings with evidence, %s on the judge\n' "$counted" "$judge"
exit 0
