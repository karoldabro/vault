#!/usr/bin/env bash
# lib/forge-detect.sh — pure git-remote-URL → forge-platform parser for /v-cr.
#
# No network, no git invocation, no side effects: source it and call the functions.
# This is the one piece of /v-cr that is pure logic, so it is unit-tested offline
# (tests/unit/forge-detect.bats). Detection POLICY (host allowlist, self-hosted
# confirmation) lives in commands/v-cr/steps/01-detect.md; this file only PARSES and
# MAPS — the caller decides whether a host is trusted before sending any credential.
#
# Public functions:
#   forge_parse_url   <url>          -> prints "host<TAB>path"      (path = owner/repo, .git stripped); rc 1 on a local path
#   forge_platform    <host> [path]  -> prints platform slug         (github|gitlab|bitbucket-cloud|bitbucket-server|unknown)
#   forge_detect      <url>          -> prints "platform<TAB>host<TAB>path"; rc 1 if it can't parse a forge URL
#   forge_validate_host <host>       -> rc 0 if host is a plausible TLS forge host; rc 1 for IP-literals / empty
#
# Self-hosted hosts are mapped via the env var VCR_HOST_MAP, a ';'-separated list of
# 'host=platform' pairs, e.g.  VCR_HOST_MAP="git.acme.com=github;code.acme.io=gitlab"
# This map is USER/GLOBAL config — never populate it from repo-controlled files (SSRF; see sec-3).

# Parse a git remote URL into host + path. Handles the two Git URL syntaxes
# (see `git help clone`, GIT URLS): scheme://[user@]host[:port]/path and the scp-like
# [user@]host:path. The scp form is only recognised when there is no slash before the
# first colon (quoting git-clone), which disambiguates it from a local path.
forge_parse_url() {
    local url="$1" rest host path before_colon
    [ -n "$url" ] || return 1

    if printf '%s' "$url" | grep -qE '^[a-zA-Z][a-zA-Z0-9+.-]*://'; then
        # scheme://[user@]host[:port]/path
        rest="${url#*://}"
        rest="${rest#*@}"          # drop optional user@ (no-op if absent)
        host="${rest%%/*}"         # authority = up to first '/'
        host="${host%%:*}"         # drop :port
        path="${rest#*/}"          # everything after the first '/'
        [ "$path" = "$rest" ] && path=""   # no '/' present → empty path
    else
        before_colon="${url%%:*}"
        case "$before_colon" in
            */*) return 1 ;;       # slash before first colon → local path, not scp
        esac
        case "$url" in
            *:*) ;;                # has a colon → scp-like
            *)   return 1 ;;       # no scheme, no colon → local path
        esac
        rest="${url#*@}"           # drop optional user@ (no-op if absent)
        host="${rest%%:*}"
        path="${rest#*:}"
    fi

    path="${path%.git}"
    path="${path%/}"
    path="${path#/}"
    [ -n "$host" ] || return 1
    printf '%s\t%s\n' "$host" "$path"
}

# Reject hosts that must never receive a credentialed call by default: empty,
# IPv4/IPv6 literals (SSRF / look-alike bypass). Domain look-alikes are rejected by the
# exact-match allowlist in forge_platform, not here.
forge_validate_host() {
    local host="$1"
    [ -n "$host" ] || return 1
    # IPv4 literal
    case "$host" in
        *[!0-9.]*) ;;              # contains a non-(digit/dot) char → not a bare IPv4
        *) return 1 ;;             # only digits and dots → IPv4 literal, reject
    esac
    # IPv6 literal (bracketed or contains '::')
    case "$host" in
        \[*\]|*::*) return 1 ;;
    esac
    return 0
}

# Map a host (+ optional path) to a platform slug. Exact host match only — a look-alike
# like 'github.com.evil.test' will NOT match 'github.com' and falls through to the
# self-hosted map / 'unknown'.
forge_platform() {
    local host="$1" path="${2:-}" pair k v

    case "$host" in
        github.com)    printf 'github\n';          return 0 ;;
        gitlab.com)    printf 'gitlab\n';          return 0 ;;
        bitbucket.org) printf 'bitbucket-cloud\n'; return 0 ;;
    esac

    # User/global self-hosted overrides. Split on ';' WITHOUT relying on IFS word-splitting,
    # so this is identical under bash and zsh (the file is sourced into the caller's shell).
    if [ -n "${VCR_HOST_MAP:-}" ]; then
        local rest="$VCR_HOST_MAP"
        while [ -n "$rest" ]; do
            case "$rest" in
                *\;*) pair="${rest%%;*}"; rest="${rest#*;}" ;;
                *)    pair="$rest";        rest="" ;;
            esac
            k="${pair%%=*}"; v="${pair#*=}"
            if [ "$k" = "$host" ]; then
                case "$v" in
                    github|gitlab|bitbucket-cloud|bitbucket-server) printf '%s\n' "$v"; return 0 ;;
                    bitbucket) printf 'bitbucket-server\n'; return 0 ;;
                esac
            fi
        done
    fi

    # Bitbucket Server / Data Center clone paths carry an '/scm/' segment
    # (https://<host>/scm/<PROJECT>/<repo>.git). A useful hint for an unmapped host —
    # the caller still confirms the self-hosted host before sending credentials.
    case "$path" in
        scm/*|*/scm/*) printf 'bitbucket-server\n'; return 0 ;;
    esac

    printf 'unknown\n'
    return 0
}

# Convenience: URL → "platform<TAB>host<TAB>path". rc 1 if the URL isn't a forge URL.
forge_detect() {
    local parsed host path platform
    parsed="$(forge_parse_url "$1")" || return 1
    host="${parsed%%	*}"
    path="${parsed#*	}"
    platform="$(forge_platform "$host" "$path")"
    printf '%s\t%s\t%s\n' "$platform" "$host" "$path"
}
