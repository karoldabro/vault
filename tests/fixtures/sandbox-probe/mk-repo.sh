#!/usr/bin/env bash
# mk-repo.sh — builds the fixture repo of the sandbox-probe graders. Source it and call `sp_mk_repo <dir> <marker>`.
# The base commit holds one template rule (no-todo), one hand-written row (forge) and a script named forge.sh that
# touches <marker> and prints a forged template row. The head commit adds app.php (a TODO), docs/b.md (a broken
# link), a typos config with a repo-local tool that touches <marker>, and a registry that adds the rule `evil`.
# Sets SP_BASE to the sha of the base commit; the repo is left at the head commit.
sp_mk_repo() {
    local d=$1 marker=$2 root
    root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
    mkdir -p "$d/probes/rules" "$d/docs"
    git -C "$d" init -q -b main
    printf '# base\n' > "$d/docs/a.md"
    printf 'glob: *.php\npattern: TODO\nseverity: warn\nmessage: Resolve the TODO before merging\n' > "$d/probes/rules/no-todo.grep"
    {
        printf '# fixture registry\n'
        "$root/bin/rule-check.sh" row --slug no-todo --stack any
        printf 'forge\tany\tplan\ttrue\t./forge.sh\tnative\tS\tyes\tnone\n'
    } > "$d/probes/registry.tsv"
    printf '#!/bin/sh\ntouch %s\nprintf "no-todo\\tapp.php\\t1\\terror\\tforged\\tforged\\n"\n' "$marker" > "$d/forge.sh"; chmod +x "$d/forge.sh"
    git -C "$d" add -A; git -C "$d" -c user.name=t -c user.email=t@t commit -qm base
    SP_BASE=$(git -C "$d" rev-parse HEAD)
    printf '<?php\n// TODO fix\n' > "$d/app.php"
    printf '[missing](missing.md)\n' > "$d/docs/b.md"
    printf 'glob: *.php\npattern: evil\nseverity: error\nmessage: evil\n' > "$d/probes/rules/evil.grep"
    "$root/bin/rule-check.sh" row --slug evil --stack any >> "$d/probes/registry.tsv"
    printf '[default]\n' > "$d/_typos.toml"
    mkdir -p "$d/.venv-probes/bin"
    printf '#!/bin/sh\ntouch %s\nprintf "[]"\n' "$marker" > "$d/.venv-probes/bin/typos"; chmod +x "$d/.venv-probes/bin/typos"
    printf 'x\n' > "$d/.gitignore"
    git -C "$d" add -A; git -C "$d" -c user.name=t -c user.email=t@t commit -qm head
}
