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

#------------------------------------------------------------------------------
# OpenViking removal (2026-08-03) — the framework must not reference it again.
#
# Allowed to name it: the remover, its doc + test, the pointer lines that tell a
# user where the remover is, and the historical record (plans/sessions/decisions),
# which is never rewritten.
#------------------------------------------------------------------------------
@test "no live framework file references OpenViking or its ollama backend" {
    cd "${VAULT_ROOT}"
    run bash -c '
      grep -rl -iE "openviking|memory_recall|memory_store|memory_health|ov find|ollama" \
        --include="*.md" --include="*.sh" --include="*.bats" . 2>/dev/null \
      | grep -v graphify-out \
      | grep -vE "^\./(bin/remove-openviking\.sh|docs/removing-openviking\.md|tests/integration/remove-openviking\.bats|tests/unit/gitignore\.bats)$" \
      | grep -vE "^\./(vault/plans|vault/sessions|vault/decisions|sessions)/" \
      | grep -vE "^\./(README\.md|INSTALL\.md|vault-guide\.md|tool-playbook\.md|bin/vault-uninstall\.sh|lib/installers\.sh)$" \
      | grep -vE "^\./tests/(integration/setup\.bats|integration/vault-uninstall\.bats|unit/setup-autoinstall\.bats)$"
    '
    [ -z "$output" ]
}

@test "the pointer files mention OpenViking only to say it is gone" {
    cd "${VAULT_ROOT}"
    # Each of these may name it, but only alongside the removal path.
    for f in README.md INSTALL.md vault-guide.md tool-playbook.md; do
        grep -qi "remov" "$f"
    done
    # No command file may reference it at all.
    run bash -c 'grep -rli "openviking\|memory_recall\|memory_store\|memory_health\|ov find" commands/ 2>/dev/null'
    [ -z "$output" ]
}

@test "the OpenViking-only commands are gone" {
    cd "${VAULT_ROOT}"
    [ ! -e commands/v-sync.md ]
    [ ! -e commands/v-backfill.md ]
    [ ! -e vault/indications/openviking-three-part-install.md ]
}
