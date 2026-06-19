#!/usr/bin/env bats
# Tests for lib/forge-detect.sh — the pure git-remote-URL → forge-platform parser used by /v-cr.
# Guards skeptic-t2 (SSH alias / vanity host / look-alike) and the SSRF-relevant host validation.

setup() {
    source /code/lib/forge-detect.sh
}

@test "parses HTTPS GitHub remote" {
    run forge_detect "https://github.com/org/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "github	github.com	org/repo" ]
}

@test "parses scp-like SSH GitHub remote" {
    run forge_detect "git@github.com:org/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "github	github.com	org/repo" ]
}

@test "GitLab subgroup path is preserved (arbitrary depth)" {
    run forge_detect "git@gitlab.com:group/sub/deeper/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "gitlab	gitlab.com	group/sub/deeper/repo" ]
}

@test "Bitbucket Cloud is detected" {
    run forge_detect "https://bitbucket.org/workspace/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "bitbucket-cloud	bitbucket.org	workspace/repo" ]
}

@test "Bitbucket Server is detected via the /scm/ path hint" {
    run forge_detect "https://git.example.com/scm/PROJ/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "bitbucket-server	git.example.com	scm/PROJ/repo" ]
}

@test "look-alike host does NOT match github.com (SSRF guard)" {
    run forge_detect "git@github.com.evil.test:org/repo.git"
    [ "$status" -eq 0 ]
    [[ "$output" == unknown* ]]
    [[ "$output" == *github.com.evil.test* ]]
}

@test "local paths are rejected (not a forge URL)" {
    run forge_detect "/home/me/repo"
    [ "$status" -eq 1 ]
    run forge_detect "../relative/repo"
    [ "$status" -eq 1 ]
}

@test "self-hosted host map (VCR_HOST_MAP) resolves multi-entry under this shell" {
    export VCR_HOST_MAP="git.acme.com=github;code.acme.io=gitlab;bb.acme.com=bitbucket"
    run forge_platform "git.acme.com" "team/app"
    [ "$output" = "github" ]
    run forge_platform "code.acme.io" "g/p"
    [ "$output" = "gitlab" ]
    run forge_platform "bb.acme.com" "PROJ/r"
    [ "$output" = "bitbucket-server" ]
    run forge_platform "unmapped.example.com" "x/y"
    [ "$output" = "unknown" ]
}

@test "host validation rejects IPv4/IPv6 literals and empty, accepts a domain" {
    run forge_validate_host "github.com";  [ "$status" -eq 0 ]
    run forge_validate_host "10.0.0.5";     [ "$status" -eq 1 ]
    run forge_validate_host "[::1]";        [ "$status" -eq 1 ]
    run forge_validate_host "";             [ "$status" -eq 1 ]
}
