#!/usr/bin/env bash
# vault-md.sh — read one `key: value` line from a repo's VAULT.md.
#
# Sourced by bin/probe.sh and bin/vault-check.sh, never run on its own.

# vault_md_key <repo> <key>: the raw value of the first `key:` line of <repo>/VAULT.md, CR and
# padding removed. Returns 1 when the file or the key is absent, so a caller can tell absent from
# empty.
vault_md_key() {
    local file="$1/VAULT.md" key=$2 line
    [ -f "$file" ] && [ -r "$file" ] || return 1
    line=$(awk -v k="$key" 'index($0, k ":") == 1 { print; exit }' "$file")
    [ -n "$line" ] || return 1
    line=${line#*:}
    line=${line%$'\r'}
    line="${line#"${line%%[![:space:]]*}"}"
    printf '%s' "${line%"${line##*[![:space:]]}"}"
}
