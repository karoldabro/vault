#!/usr/bin/env bash
# probe-md-table.sh — locates a markdown pipe table under a heading and splits it into named columns.
# Shared by probes/similar-symbols.sh (Reuse map) and probes/sql-schema.sh (Data model table).
# Nothing is executed; reads only. Contract: commands/_shared/probe-kit.md.
#
# md_table_rows <file> <heading-ere> prints the header line "0<TAB>col1..." then one "<line><TAB>
# cell1..." per data row, in header column order — see lib/probe-md-table.awk for the exact format.
# The caller decides which columns it needs and what "unreadable" means for its own table shape.

[ -n "${PROBE_MD_TABLE_LOADED:-}" ] && return 0
PROBE_MD_TABLE_LOADED=1

md_table_rows() {
    local file=$1 heading=$2
    local here; here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    LC_ALL=C tr -d '\r' < "$file" | LC_ALL=C awk -v heading="$heading" -f "$here/probe-md-table.awk"
}
