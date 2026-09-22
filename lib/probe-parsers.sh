#!/usr/bin/env bash
# probe-parsers.sh — turns the output of an external tool into finding rows.
# Sourced by bin/probe.sh. A registry row names one of these functions in its `parser` cell. Each reads the
# tool's standard output on stdin and prints rows through probe_finding. Called as: parse_<name> <id> <repo>.
# Return 3 when jq is needed and absent. Contract: commands/_shared/probe-kit.md.

[ -n "${PROBE_PARSERS_LOADED:-}" ] && return 0
PROBE_PARSERS_LOADED=1
# shellcheck source=probe-emit.sh
. "$(dirname "${BASH_SOURCE[0]}")/probe-emit.sh"

# lizard --csv: one function per line. Fields: nloc, ccn, token, param, length, location, file, function,
# long name, start line, end line. A function over PROBE_CCN (10), PROBE_NLOC (60) or PROBE_PARAMS (5) is a finding.
parse_lizard_csv() {
    local id=$1 repo=$2 f l r m
    LC_ALL=C awk -v ccn="${PROBE_CCN:-10}" -v nloc="${PROBE_NLOC:-60}" -v par="${PROBE_PARAMS:-5}" '
        function csv(line, f,   n, i, c, cur, inq) {
            n = 0; cur = ""; inq = 0
            for (i = 1; i <= length(line); i++) {
                c = substr(line, i, 1)
                if (inq) { if (c == "\"") { if (substr(line, i + 1, 1) == "\"") { cur = cur "\""; i++ } else inq = 0 } else cur = cur c }
                else if (c == "\"") inq = 1
                else if (c == ",") { f[++n] = cur; cur = "" }
                else cur = cur c
            }
            f[++n] = cur
            return n
        }
        NF == 0 { next }
        { n = csv($0, f); if (n < 11) next
          if (f[2] + 0 > ccn)  printf "%s\t%s\thigh-complexity\t%s has complexity %s, the limit is %s\n", f[7], f[10], f[8], f[2], ccn
          if (f[1] + 0 > nloc) printf "%s\t%s\tlong-function\t%s has %s lines, the limit is %s\n", f[7], f[10], f[8], f[1], nloc
          if (f[4] + 0 > par)  printf "%s\t%s\tmany-parameters\t%s has %s parameters, the limit is %s\n", f[7], f[10], f[8], f[4], par }
    ' | while IFS=$'\t' read -r f l r m; do
        f=${f#"$repo"/}; probe_finding "$id" "${f#./}" "$l" warn "$r" "$m"
    done
}

# typos --format json: one object per line with path, line_num, typo and corrections.
parse_typos_json() {
    local id=$1 repo=$2 f l t c
    command -v jq >/dev/null 2>&1 || return 3
    jq -r 'select(.type == "typo") | [.path, (.line_num | tostring), .typo, ((.corrections // []) | join(","))] | map(. // "") | join("\u001f")' |
    while IFS=$'\037' read -r f l t c; do
        f=${f#"$repo"/}; probe_finding "$id" "${f#./}" "$l" warn typo "\"$t\" should be \"$c\""
    done
}

# claude plugin validate --json: manifest and contents entries, each with errors and warnings.
parse_claude_validate() {
    local id=$1 repo=$2 f sev path msg rule
    command -v jq >/dev/null 2>&1 || return 3
    jq -r '([.manifest] + (.contents // [])) | map(select(. != null))[] as $e
        | (($e.errors // [])[] | [$e.file, "error", .path, .message]),
          (($e.warnings // [])[] | [$e.file, "warn", .path, .message])
        | map(. // "") | join("\u001f")' |
    while IFS=$'\037' read -r f sev path msg; do
        f=${f#"$repo"/}
        case $f in /*|'') f=.claude-plugin/plugin.json ;; esac
        rule=plugin-$(printf '%s' "$path" | LC_ALL=C tr 'A-Z' 'a-z' | LC_ALL=C tr -c 'a-z0-9' '-')
        probe_finding "$id" "$f" 0 "$sev" "$rule" "$msg"
    done
}

# phpstan --error-format=json: files.<path>.messages[] with message, line, identifier. No severity
# field on a message (only ignorable); every message is treated as severity error.
parse_phpstan_json() {
    local id=$1 repo=$2 f l ident msg
    command -v jq >/dev/null 2>&1 || return 3
    jq -r '.files // {} | to_entries[] as $e | $e.value.messages[]
        | [$e.key, (.line // 0 | tostring), (.identifier // ""), .message] | map(. // "") | join("\u001f")' |
    while IFS=$'\037' read -r f l ident msg; do
        f=${f#"$repo"/}; f=${f#./}
        probe_finding "$id" "$f" "$l" error "${ident:-phpstan}" "$msg"
    done
}

# phparkitect check --format=json: {"details": {"<FQCN>": [{"error", "line"}]}}, keyed by class name —
# no file field at all. Laravel-only row: a class under App\ maps to app/ (Laravel's own PSR-4
# convention). A class outside App\ is skipped; this parser cannot name its file.
parse_phparkitect_json() {
    local id=$1 repo=$2 fqcn l msg f
    command -v jq >/dev/null 2>&1 || return 3
    jq -r '.details // {} | to_entries[] as $e | $e.value[]
        | [$e.key, (.line // 0 | tostring), .error] | map(. // "") | join("\u001f")' |
    while IFS=$'\037' read -r fqcn l msg; do
        case $fqcn in
            'App\'*)
                f="app/${fqcn#App\\}"
                f=$(printf '%s' "$f" | tr '\\' '/')
                probe_finding "$id" "${f}.php" "$l" error arkitect "$msg"
                ;;
        esac
    done
}

# ruff check --output-format json: array of {filename, location:{row,column}, code, message, severity}.
parse_ruff_json() {
    local id=$1 repo=$2 f l sev code msg
    command -v jq >/dev/null 2>&1 || return 3
    jq -r '.[] | [.filename, (.location.row // 0 | tostring), (.severity // "error"), .code, .message] | map(. // "") | join("\u001f")' |
    while IFS=$'\037' read -r f l sev code msg; do
        f=${f#"$repo"/}; f=${f#./}
        case $sev in error) ;; *) sev=warn ;; esac
        probe_finding "$id" "$f" "$l" "$sev" "$code" "$msg"
    done
}

# dart analyze --format=machine: SEVERITY|TYPE|CODE|PATH|LINE|COL|LEN|MESSAGE, one line per finding.
# A literal pipe inside PATH or MESSAGE is backslash-escaped by the tool; this split does not unescape
# it, so a finding whose path or message holds a real "|" is a known miss.
parse_dart_machine() {
    local id=$1 repo=$2
    awk -F'|' '
        NF < 8 { next }
        { sev = ($1 == "ERROR") ? "error" : ($1 == "WARNING") ? "warn" : "info"
          printf "%s\t%s\t%s\t%s\t%s\n", $4, $5, sev, $3, $8 }
    ' | while IFS=$'\t' read -r f l sev code msg; do
        f=${f#"$repo"/}; f=${f#./}
        probe_finding "$id" "$f" "$l" "$sev" "$code" "$msg"
    done
}

# vue-tsc/tsc --noEmit, piped (non-TTY, so TypeScript's non-pretty form): one line per diagnostic,
# path(line,col): error|warning TSxxxx: message.
parse_tsc_text() {
    local id=$1 repo=$2
    sed -E -n 's/^(.+)\(([0-9]+),[0-9]+\): (error|warning) (TS[0-9]+): (.*)$/\1\t\2\t\3\t\4\t\5/p' |
    while IFS=$'\t' read -r f l sev code msg; do
        f=${f#"$repo"/}; f=${f#./}
        case $sev in error) ;; *) sev=warn ;; esac
        probe_finding "$id" "$f" "$l" "$sev" "$code" "$msg"
    done
}
