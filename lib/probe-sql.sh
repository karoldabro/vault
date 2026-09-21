#!/usr/bin/env bash
# probe-sql.sh — reads SQL text into facts. Sourced by probes/sql-schema.sh. Nothing is executed.
#
# sql_facts <label> <path> prints tab separated facts, the program is lib/probe-sql.awk:
#   T <file> <table> <line> - - -                            a table declared by CREATE TABLE
#   C <file> <table> <line> <column> <type> <notnull> <decl> a column; <decl> is the line of its CREATE TABLE, 0 for ALTER TABLE ADD
#   K <file> <table> <line> <column> <kind> <ref>            a key on its first column: PK, UQ, IX or FK (ref is table.column)
# Read: CREATE TABLE, CREATE [UNIQUE] INDEX, ALTER TABLE ADD. DROP and RENAME are ignored.
# Names keep their case; quotes and schema prefixes are removed. Contract: commands/_shared/probe-kit.md.

[ -n "${PROBE_SQL_LOADED:-}" ] && return 0
PROBE_SQL_LOADED=1

sql_facts() {
    local here; here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    PROBE_SQL_LABEL=$1 LC_ALL=C awk -f "$here/probe-sql.awk" < "$2"
}
