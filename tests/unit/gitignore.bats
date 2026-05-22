#!/usr/bin/env bats
# Tests for the .gitignore files (framework + project-vault template).

load "../helpers/setup.bash"

@test "framework .gitignore exists and covers expected paths" {
    [ -f "/code/.gitignore" ]
    grep -qE '^\.DS_Store$'      /code/.gitignore
    grep -qE '^node_modules/$'   /code/.gitignore
    grep -qE '^tests/tmp/$'      /code/.gitignore
}

@test "project vault gitignore template exists and ignores machine layer" {
    local tpl="/code/templates/vault.gitignore"
    [ -f "${tpl}" ]
    grep -q 'memory/parent'                "${tpl}"
    grep -q '^graphify/$'                  "${tpl}"
    grep -q '\.obsidian/workspace\*\.json' "${tpl}"
}
