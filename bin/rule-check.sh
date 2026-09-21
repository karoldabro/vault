#!/usr/bin/env bash
# rule-check.sh — the mechanical half of /v-rule: accepts, installs and verifies a rule, and filters comments.
# Contract: commands/_shared/probe-kit.md section "Rule files"; plan vault/plans/2026-09-21-1430-v-rule.md.
#
# Usage:  bin/rule-check.sh row --slug <s> [--stack <x>]
#         bin/rule-check.sh accept --repo <root> --slug <s> --rule <file> --bad <file> --good <file>
#         bin/rule-check.sh install --repo <root> --slug <s> --draft <dir> [--stack <x>]
#         bin/rule-check.sh verify --repo <root> (--slug <s> | --indication <file>)
#         bin/rule-check.sh own-comments --operator-id <n> < comments.json
#
# accept   prints `accepted <slug>: <n> of <files> files at <sha>`, or `refused <slug>: <why>` and exit 1.
# install  runs accept on a private copy of the draft, then writes the rule, two fixtures and one registry row.
# verify   prints one line: ok, drift, framework, hand-written, mislabelled, orphan or broken.
# Env:     RULE_MAX_FINDINGS (default: half of PROBE_PANEL_ROWS, so 20)
# Exit:    0 ok · 1 refused or broken · 2 usage error

set -uo pipefail
export LC_ALL=C
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$root/lib/probe-scope.sh"
PROBE_GIT_BIN=$(command -v git || true)
runner="$root/probes/rule-grep.sh"
STACKS=" any harness sql php laravel nuxt flutter python node "
T=$'\t'

die() { printf 'rule-check: %s\n' "$*" >&2; exit 2; }
clean() { printf '%s' "$1" | LC_ALL=C tr -c 'A-Za-z0-9._:/ -' '?' | cut -c1-80; }
refuse() { printf 'refused %s: %s\n' "$(clean "$slug")" "$*" >&2; exit 1; }
plain() { # plain <file> <max bytes> — a regular file, not a link, at most <max> bytes
    [ -f "$1" ] && [ ! -L "$1" ] && [ "$(wc -c < "$1" | tr -d ' ')" -le "$2" ]
}
opts() { # opts <name...> — reads --name value pairs into variables o_<name>
    local n; for n in "$@"; do eval "o_${n//-/_}="; done
    while [ $# -gt 0 ] && [ -n "${OPTS_ARGS:-}" ]; do break; done
    while [ ${#ARGS[@]} -gt 0 ]; do
        case ${ARGS[0]} in
            --*) n=${ARGS[0]#--}; case " $* " in *" $n "*) ;; *) die "unknown option: ${ARGS[0]}" ;; esac
                [ ${#ARGS[@]} -ge 2 ] || die "${ARGS[0]} needs a value"
                eval "o_${n//-/_}=\${ARGS[1]}"; ARGS=("${ARGS[@]:2}") ;;
            *) die "unexpected argument: ${ARGS[0]}" ;;
        esac
    done
}
frontmatter() { awk -v k="$2" 'NR==1 && $0 !~ /^---\r?$/ {exit} NR>1 && /^---\r?$/ {exit} {sub(/\r$/,""); if (index($0, k ":")==1) {v=substr($0, length(k)+2); sub(/^ +/,"",v); sub(/ *#.*$/,"",v); print v; exit}}' "$1"; }
fw_id() { awk -F'\t' -v s="$1" '!/^#/ && $1==s {f=1} END{exit !f}' "$root/probes/registry.tsv"; }
template() { printf '%s\t%s\tplan\ttest -f probes/rules/%s.grep\t"$PROBE_FRAMEWORK/probes/rule-grep.sh" --check %s --rule probes/rules/%s.grep\tnative\tS\tyes\tnone\n' "$1" "$2" "$1" "$1" "$1"; }
slug_ok() { [[ $1 =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]]; }
sha7() { probe_git "$1" rev-parse --short=7 HEAD 2>/dev/null; }
files_of() { "$root/bin/probe.sh" scale --repo "$1" 2>/dev/null | awk -F'\t' '$1=="files" {print $2}'; }
maxf() { local m=${RULE_MAX_FINDINGS:-$(( ${PROBE_PANEL_ROWS:-40} / 2 ))}; [[ $m =~ ^[0-9]+$ ]] || die "RULE_MAX_FINDINGS must be digits"; echo "$m"; }
stack_ok() { case $STACKS in *" $1 "*) return 0 ;; esac; return 1; }
abs() { readlink -f -- "$1"; }
fixture_rows() { "$runner" --check "$slug" --rule "$1" --repo "$2" --fixture "$3" 2>/dev/null | grep -c ''; }

# check_draft <repo> <rule> <bad> <good> — the D-8 gate; sets NREC to "<n> of <files> files at <sha>".
check_draft() {
    local repo=$1 rule=$2 bad=$3 good=$4 nfiles n f sha msg
    slug_ok "$slug" || refuse "slug must match ^[a-z0-9][a-z0-9-]{0,39}\$"
    fw_id "$slug" && refuse "slug is a framework probe id"
    [ -d "$repo" ] && probe_in_git "$repo" || refuse "not a git repository"
    sha=$(sha7 "$repo"); [ -n "$sha" ] || refuse "the repository has no commit"
    plain "$rule" 8192 && plain "$bad" 65536 && plain "$good" 65536 || refuse "rule, bad and good must be regular files (no link) of at most 8 KiB, 64 KiB and 64 KiB"
    [ "${bad##*.}" = "${good##*.}" ] || refuse "bad and good fixtures must share one extension"
    nfiles=$("$runner" --check "$slug" --rule "$rule" --repo "$repo" --count-files 2>"$TMPD/err") || refuse "rule is malformed: $(head -c 200 "$TMPD/err")"
    [ "$nfiles" -gt 0 ] || refuse "glob matches no file"
    [ "$(fixture_rows "$rule" "$repo" "$bad")" -ge 1 ] || refuse "bad fixture does not fire"
    [ "$(fixture_rows "$rule" "$repo" "$good")" -eq 0 ] || refuse "good fixture fires"
    "$runner" --check "$slug" --rule "$rule" --repo "$repo" > "$TMPD/rows" 2>"$TMPD/err"; [ $? -le 1 ] || refuse "rule failed: $(head -c 200 "$TMPD/err")"
    n=$(grep -c "" "$TMPD/rows"); msg=$(maxf) || exit 2
    [ "$n" -le "$msg" ] || refuse "fires everywhere: $n findings, limit $msg"
    f=$(files_of "$repo"); NREC="$n of ${f:-0} files at $sha"
}

cmd_accept() {
    opts repo slug rule bad good; slug=$o_slug
    [ -n "$o_repo" ] && [ -n "$slug" ] && [ -n "$o_rule" ] && [ -n "$o_bad" ] && [ -n "$o_good" ] || die "accept needs --repo --slug --rule --bad --good"
    [ -d "$o_repo" ] || refuse "not a directory"
    check_draft "$(cd "$o_repo" && pwd -P)" "$(abs "$o_rule")" "$(abs "$o_bad")" "$(abs "$o_good")"; printf 'accepted %s: %s\n' "$slug" "$NREC"
}

no_link_path() { # no_link_path <repo> <rel> — every existing component of <rel> under <repo> is a real directory or absent
    local p=$1 c; for c in $(printf '%s' "$2" | tr '/' ' '); do p="$p/$c"; [ ! -L "$p" ] || return 1; [ ! -e "$p" ] || [ -d "$p" ] || return 1; done
}

cmd_install() {
    opts repo slug draft stack; slug=$o_slug; local repo=$o_repo stack=${o_stack:-any} d bad good ext reg rel
    [ -n "$repo" ] && [ -n "$slug" ] && [ -n "$o_draft" ] || die "install needs --repo --slug --draft"
    stack_ok "$stack" || refuse "stack must be one of:$STACKS"
    slug_ok "$slug" || refuse "slug must match ^[a-z0-9][a-z0-9-]{0,39}\$"
    fw_id "$slug" && refuse "slug is a framework probe id"
    [ -d "$repo" ] || refuse "not a directory"; repo=$(cd "$repo" && pwd -P)
    [ "$repo" != "$root" ] && ! [ "$repo/probes/registry.tsv" -ef "$root/probes/registry.tsv" ] || refuse "the framework checkout takes probes through /v-work"
    d=$TMPD/draft; mkdir -m 700 "$d"; [ -d "$o_draft" ] || die "--draft is not a directory"
    bad=$(ls "$o_draft"/bad.* 2>/dev/null); good=$(ls "$o_draft"/good.* 2>/dev/null)
    plain "$o_draft/$slug.grep" 8192 || refuse "the draft holds no regular $slug.grep of at most 8 KiB"
    cp -- "$o_draft/$slug.grep" "$d/rule"
    [ "$(printf '%s\n' "$bad" | grep -c .)" -eq 1 ] && [ "$(printf '%s\n' "$good" | grep -c .)" -eq 1 ] || refuse "the draft needs one bad.<ext> and one good.<ext>"
    ext=${bad##*.}; [[ $ext =~ ^[a-z0-9]{1,8}$ ]] || refuse "fixture extension must match ^[a-z0-9]{1,8}\$"
    [ "${good##*.}" = "$ext" ] || refuse "bad and good fixtures must share one extension"
    plain "$bad" 65536 && plain "$good" 65536 || refuse "a fixture is a link, not a file, or larger than 64 KiB"
    cp -- "$bad" "$d/bad.$ext"; cp -- "$good" "$d/good.$ext"
    check_draft "$repo" "$d/rule" "$d/bad.$ext" "$d/good.$ext"
    rel=probes/rules; no_link_path "$repo" "probes/rules/fixtures/$slug" || refuse "a path component is a symlink or a file"
    [ ! -e "$repo/probes/rules/$slug.grep" ] && [ ! -L "$repo/probes/rules/$slug.grep" ] || refuse "$rel/$slug.grep already exists"
    reg=$repo/probes/registry.tsv
    if [ -e "$reg" ] || [ -L "$reg" ]; then
        probe_safe_file "$repo" probes/registry.tsv || refuse "the registry is not a regular file"
        awk -F'\t' -v s="$slug" '!/^#/ && $1==s {f=1} END{exit f}' "$reg" || refuse "the registry already holds $slug"
    fi
    mkdir -p "$repo/probes/rules/fixtures/$slug" || refuse "cannot create the rules directory"
    put() { local t; t=$(mktemp "$(dirname "$2")/.rc.XXXXXX") && cp -- "$1" "$t" && mv -T -- "$t" "$2"; }
    put "$d/rule" "$repo/probes/rules/$slug.grep" && put "$d/bad.$ext" "$repo/probes/rules/fixtures/$slug/bad.$ext" && put "$d/good.$ext" "$repo/probes/rules/fixtures/$slug/good.$ext" || die "write failed"
    { if [ -f "$reg" ]; then cat "$reg"; [ -z "$(tail -c1 "$reg")" ] || printf '\n'; else printf '# The probe registry of this repo. Contract: commands/_shared/probe-kit.md. Rows written by /v-rule.\n# id\tstack\tstage\tdetect\trun\tparser\tcost\texecutes-repo-code\tinstall\n'; fi
      template "$slug" "$stack"; } > "$TMPD/reg"
    put "$TMPD/reg" "$reg" || { rm -rf "$repo/probes/rules/$slug.grep" "$repo/probes/rules/fixtures/$slug"; die "registry write failed, nothing kept"; }
    printf 'wrote probes/rules/%s.grep\nwrote probes/rules/fixtures/%s/bad.%s\nwrote probes/rules/fixtures/%s/good.%s\nwrote probes/registry.tsv\nrecord: %s\n' "$slug" "$slug" "$ext" "$slug" "$ext" "$NREC"
}

cmd_verify() {
    opts repo slug indication; local repo=${o_repo:-} id="" rec="" reg row st n f sha b g now old dir
    [ -n "$repo" ] && { [ -n "$o_slug" ] || [ -n "$o_indication" ]; } || die "verify needs --repo and --slug or --indication"
    [ -d "$repo" ] || die "--repo is not a directory"; repo=$(cd "$repo" && pwd -P)
    if [ -n "$o_indication" ]; then
        [ -r "$o_indication" ] || die "cannot read $o_indication"
        slug=$(clean "$(frontmatter "$o_indication" slug)"); id=$(frontmatter "$o_indication" probe); rec=$(frontmatter "$o_indication" probe_count)
        [ -n "$id" ] || { printf 'no-probe %s\n' "$slug"; return 0; }
    else slug=$o_slug; id=$o_slug; fi
    [[ $id =~ ^[a-z0-9-]+$ ]] || { printf 'broken %s: the probe id is not [a-z0-9-]+\n' "$slug"; return 1; }
    reg=$repo/probes/registry.tsv; row=""
    probe_safe_file "$repo" probes/registry.tsv && row=$(awk -F'\t' -v s="$id" '!/^#/ && $1==s {print; exit}' "$reg")
    if [ -z "$row" ]; then
        if fw_id "$id"; then printf 'framework %s\n' "$id"; return 0; fi
        printf 'orphan %s %s\n' "$slug" "$id"; return 1
    fi
    st=$(printf '%s' "$row" | cut -f2)
    if [ "$row" != "$(template "$id" "$st")" ]; then
        if [ "$(printf '%s' "$row" | cut -f8)" = no ]; then printf 'mislabelled %s\n' "$id"; return 1; fi
        printf 'hand-written %s\n' "$id"; return 0
    fi
    probe_safe_file "$repo" "probes/rules/$id.grep" || { printf 'broken %s: the rule file is missing\n' "$slug"; return 1; }
    dir=$repo/probes/rules/fixtures/$id; b=$(ls "$dir"/bad.* 2>/dev/null); g=$(ls "$dir"/good.* 2>/dev/null)
    plain "$b" 65536 && plain "$g" 65536 || { printf 'broken %s: a fixture is a link or too large\n' "$slug"; return 1; }
    [ "$(printf '%s\n' "$b" | grep -c .)" -eq 1 ] && [ "$(printf '%s\n' "$g" | grep -c .)" -eq 1 ] || { printf 'broken %s: the fixtures are missing\n' "$slug"; return 1; }
    slug=$id
    [ "$(fixture_rows "$repo/probes/rules/$id.grep" "$repo" "$b")" -ge 1 ] || { printf 'broken %s: the bad fixture does not fire\n' "$slug"; return 1; }
    [ "$(fixture_rows "$repo/probes/rules/$id.grep" "$repo" "$g")" -eq 0 ] || { printf 'broken %s: the good fixture fires\n' "$slug"; return 1; }
    "$root/bin/probe.sh" run plan --repo "$repo" --only "$id" --allow-repo-registry > "$TMPD/rows" 2> "$TMPD/err"; [ $? -le 1 ] || { printf 'broken %s: the kit could not run the rule: %s\n' "$slug" "$(head -c 200 "$TMPD/err" | tr '\n\t' '  ')"; return 1; }
    n=$(grep -c '' "$TMPD/rows"); f=$(files_of "$repo"); sha=$(sha7 "$repo")
    old=${rec%% of *}
    if [[ $rec =~ ^[0-9]+\ of\  ]] && [ "$old" != "$n" ]; then printf 'drift %s: %s -> %s\n' "$id" "$old" "$n"; return 0; fi
    printf 'ok %s %s of %s files at %s\n' "$id" "$n" "${f:-0}" "${sha:-nogit}"
}

cmd_own() {
    opts operator-id; local me=$o_operator_id
    [[ $me =~ ^[0-9]+$ ]] || die "--operator-id must be digits"
    command -v jq >/dev/null 2>&1 || die "jq is not installed"
    jq -e -c --argjson me "$me" 'if type=="array" then [ .[] | select(.user != null and .user.id == $me and .user.type == "User" and (.performed_via_github_app == null) and (((.body // "") | contains("<!-- v-cr:")) | not)) ] else error("not an array") end' 2>/dev/null || die "input is not a JSON array of comments"
}

cmd_row() { opts slug stack; slug=$o_slug; slug_ok "$slug" || die "--slug is invalid"; stack_ok "${o_stack:-any}" || die "--stack is not in the list"; template "$slug" "${o_stack:-any}"; }

[ $# -ge 1 ] || { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }
cmd=$1; shift; ARGS=("$@"); slug=""
TMPD=$(mktemp -d "${TMPDIR:-/tmp}/rule-check.XXXXXX") || die "cannot create a temp directory"
trap 'rm -rf "$TMPD"' EXIT
case $cmd in
    accept) cmd_accept ;; install) cmd_install ;; verify) cmd_verify ;; own-comments) cmd_own ;; row) cmd_row ;;
    -h|--help|help) sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
    *) die "unknown command: $cmd" ;;
esac
