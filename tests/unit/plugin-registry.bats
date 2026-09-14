#!/usr/bin/env bats
# Behaviour of the plugin extension points.
#
# Contract: vault/architecture/plugin-extension-contract.md.
#
# Everything is built under $TEST_HOME. The repo is mounted read-only at /code, so a test that
# asserted "nothing was written" against the mount would pass without the code doing anything.

load "../helpers/setup.bash"

setup() {
    make_test_home
    VAULT_ROOT="${VAULT_ROOT:-/code}"
    export VAULT_HOME="${TEST_HOME}/vault-home"
    REGISTRY="${VAULT_HOME}/_global/plugins.tsv"
    PLUGIN_SH="${VAULT_ROOT}/bin/vault-plugin.sh"
    GATE_SH="${VAULT_ROOT}/bin/gate.sh"
    LIB="${VAULT_ROOT}/lib/plugin-registry.sh"
}

teardown() { cleanup_test_home; }

# --- fixtures ---------------------------------------------------------------------------

# make_plugin <name> <points> — a plugin whose init point echoes its three arguments.
make_plugin() {
    local name=$1 points=$2 dir="${TEST_HOME}/$1"
    mkdir -p "${dir}/extend"
    printf 'name\tpoints\n%s\t%s\n' "${name}" "${points}" > "${dir}/extend/plugin.tsv"
    cat > "${dir}/extend/init.sh" <<'EOS'
#!/usr/bin/env bash
arr=(shebang proof)
echo "ARGS ${1:-} ${2:-} ${3:-} ${arr[1]}"
EOS
    chmod +x "${dir}/extend/init.sh"
    printf 'key\twhy\n%s\t%s\n' "guard_release_pattern" "which branch the gate refuses on" \
        > "${dir}/extend/dod-keys.tsv"
    printf '%s\n' "${dir}"
}

# make_repo — a repo with a complete VAULT.md and NO trailing newline, the fault case.
make_repo() {
    local dir="${TEST_HOME}/repo-$1"
    mkdir -p "${dir}"
    sed -e 's/{{slug}}/testrepo/' -e 's/{{dod_profile}}/code/' \
        -e 's/{{test_command}}/make test/' -e 's/{{lint_command}}/make lint/' \
        -e 's/{{delivery_command}}/make ship/' \
        "${VAULT_ROOT}/templates/VAULT.md" > "${dir}/VAULT.md"
    printf '%s' "$(cat "${dir}/VAULT.md")" > "${dir}/VAULT.md"
    printf '%s\n' "${dir}"
}

# A realistic init point: merges the plugins scalar and writes the key that merge makes required.
install_merging_init() {
    cat > "$1/extend/init.sh" <<'EOS'
#!/usr/bin/env bash
set -u
repo=${1:-}; [ -n "$repo" ] || exit 0
vm="$repo/VAULT.md"; [ -f "$vm" ] || exit 0
[ -n "$(tail -c1 "$vm")" ] && printf '\n' >> "$vm"
if ! grep -q '^plugins:' "$vm"; then
    printf 'plugins: qg\n' >> "$vm"
elif ! sed -n 's/^plugins:[[:space:]]*//p' "$vm" | head -1 | grep -qw qg; then
    sed -i 's/^\(plugins:.*\)$/\1, qg/' "$vm"
fi
grep -q '^guard_release_pattern:' "$vm" \
    || printf 'guard_release_pattern: refs/heads/release/*\n' >> "$vm"
exit 0
EOS
    chmod +x "$1/extend/init.sh"
}

run_point() {
    run bash -c ". '${LIB}'; vault_plugin_run_point $*; echo HOSTRC=\$?"
}

# --- SC-1: the init point runs with the documented arguments -----------------------------

@test "init point receives repo path, vault dir and slug in order" {
    local dir; dir=$(make_plugin qg init,dod-keys)
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]

    run_point init /the/repo /the/vault theslug
    [[ "$output" == *"ARGS /the/repo /the/vault theslug proof"* ]]
    [[ "$output" == *"HOSTRC=0"* ]]
}

# `proof` above comes from a bash array. A point forced through `sh` would die on it, so this
# doubles as the check that the point runs under its own shebang.
@test "init point is skipped when the plugin does not declare it" {
    local dir; dir=$(make_plugin qg dod-keys)
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]

    run_point init /the/repo /the/vault theslug
    [[ "$output" != *"ARGS"* ]]
    [[ "$output" == *"HOSTRC=0"* ]]
}

# --- SC-2: a failing point never takes the host with it ----------------------------------

@test "a point exiting 1 warns once and leaves vault-init at exit 0" {
    local dir; dir=$(make_plugin qg init)
    printf '#!/usr/bin/env bash\nexit 1\n' > "${dir}/extend/init.sh"
    chmod +x "${dir}/extend/init.sh"
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]

    run_point init /r /v s
    [[ "$output" == *"qg: init declined"* ]]
    [[ "$output" == *"HOSTRC=0"* ]]
    [ "$(printf '%s\n' "$output" | grep -c 'init declined')" -eq 1 ]
}

@test "a point exiting above 1 says it could not run, not that it declined" {
    local dir; dir=$(make_plugin qg init)
    printf '#!/usr/bin/env bash\nexit 7\n' > "${dir}/extend/init.sh"
    chmod +x "${dir}/extend/init.sh"
    run "${PLUGIN_SH}" add "${dir}"

    run_point init /r /v s
    [[ "$output" == *"could not run (exit 7)"* ]]
    [[ "$output" != *"declined"* ]]
    [[ "$output" == *"HOSTRC=0"* ]]
}

@test "a sourced point cannot abort the host through set -e" {
    local dir; dir=$(make_plugin qg init)
    printf '#!/usr/bin/env bash\nexit 3\n' > "${dir}/extend/init.sh"
    chmod +x "${dir}/extend/init.sh"
    run "${PLUGIN_SH}" add "${dir}"

    run bash -c "set -euo pipefail; . '${LIB}'; vault_plugin_run_point init /r /v s; echo SURVIVED"
    [[ "$output" == *"SURVIVED"* ]]
}

@test "a point reading stdin does not consume the host input" {
    local dir; dir=$(make_plugin qg init)
    printf '#!/usr/bin/env bash\ncat\nexit 0\n' > "${dir}/extend/init.sh"
    chmod +x "${dir}/extend/init.sh"
    run "${PLUGIN_SH}" add "${dir}"

    run bash -c "printf 'HOSTLINE\n' | { . '${LIB}'; vault_plugin_run_point init /r /v s >/dev/null; read -r kept; echo \"KEPT=\$kept\"; }"
    [[ "$output" == *"KEPT=HOSTLINE"* ]]
}

@test "a registry row whose path no longer exists warns once and keeps the row" {
    local dir; dir=$(make_plugin qg init)
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]
    rm -rf "${dir}"

    run_point init /r /v s
    [[ "$output" == *"qg: init file is gone"* ]]
    [[ "$output" == *"HOSTRC=0"* ]]
    run grep -c '^qg' "${REGISTRY}"
    [ "$output" -eq 1 ]
}

# --- SC-3: a plugin key binds only where the repo opted in -------------------------------

@test "a plugin key refuses a repo listing the plugin" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo optin)
    run "${PLUGIN_SH}" add "${dir}"
    printf '\nplugins: qg\n' >> "${repo}/VAULT.md"

    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"omits guard_release_pattern"* ]]
    [[ "$output" == *"which branch the gate refuses on"* ]]
}

@test "a plugin key passes a repo that does not list it" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo optout)
    run "${PLUGIN_SH}" add "${dir}"

    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 0 ]
}

@test "absent with a reason satisfies a plugin-declared key" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo absent)
    run "${PLUGIN_SH}" add "${dir}"
    printf '\nplugins: qg\nguard_release_pattern: absent: no release branch here\n' >> "${repo}/VAULT.md"

    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 0 ]
}

@test "a plugins value with a space after the comma matches both names" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo spaced)
    run "${PLUGIN_SH}" add "${dir}"
    printf '\nplugins: other, qg\n' >> "${repo}/VAULT.md"

    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"omits guard_release_pattern"* ]]
    [[ "$output" == *"'other', which is not registered"* ]]
}

@test "a VAULT.md with two plugins lines is refused, not first-wins" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo twolines)
    run "${PLUGIN_SH}" add "${dir}"
    printf '\nplugins: qg\nplugins: other\nguard_release_pattern: x\n' >> "${repo}/VAULT.md"

    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"2 'plugins:' lines"* ]]
}

# --- SC-4: registration refuses what is not a plugin, and writes nothing ------------------

@test "add on a directory with no extend/plugin.tsv writes no registry row" {
    mkdir -p "${TEST_HOME}/bare"
    run "${PLUGIN_SH}" add "${TEST_HOME}/bare"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a plugin"* ]]
    run test -e "${REGISTRY}"
    [ "$status" -ne 0 ]
}

@test "add on a plugin declaring a point whose file is absent writes no registry row" {
    local dir; dir=$(make_plugin qg init,dod-keys)
    rm -f "${dir}/extend/init.sh"
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
    run test -e "${REGISTRY}"
    [ "$status" -ne 0 ]
}

@test "add on a plugin whose point file is not executable writes no registry row" {
    local dir; dir=$(make_plugin qg init)
    chmod -x "${dir}/extend/init.sh"
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not executable"* ]]
    run test -e "${REGISTRY}"
    [ "$status" -ne 0 ]
}

@test "add on a path traversing a symlink writes no registry row" {
    local dir; dir=$(make_plugin qg init)
    ln -s "${dir}" "${TEST_HOME}/link-to-qg"
    run "${PLUGIN_SH}" add "${TEST_HOME}/link-to-qg"
    [ "$status" -eq 1 ]
    [[ "$output" == *"symlink"* ]]
    run test -e "${REGISTRY}"
    [ "$status" -ne 0 ]
}

@test "no code path other than vault-plugin.sh writes the registry" {
    run grep -rlE 'plugins\.tsv' "${VAULT_ROOT}/bin" "${VAULT_ROOT}/lib"
    [ "$status" -eq 0 ]
    # The library names the path; only the CLI may write to it.
    run bash -c "grep -nE '>>?[[:space:]]*\"?\\\$(reg|REGISTRY)' '${VAULT_ROOT}/lib/plugin-registry.sh'"
    [ "$status" -ne 0 ]
}

@test "the registry is created mode 0600" {
    local dir; dir=$(make_plugin qg init)
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]
    run stat -c '%a' "${REGISTRY}"
    [ "$output" = "600" ]
}

@test "re-registering a name replaces its row rather than adding a second" {
    local dir; dir=$(make_plugin qg init)
    run "${PLUGIN_SH}" add "${dir}"
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]
    run grep -c '^qg' "${REGISTRY}"
    [ "$output" -eq 1 ]
}

# --- SC-5: the points probe ---------------------------------------------------------------

@test "a plugin naming an unimplemented point is refused and the point is named" {
    local dir; dir=$(make_plugin qg init,setup)
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"'setup' is not implemented"* ]]
    [[ "$output" == *"init dod-keys"* ]]
    run test -e "${REGISTRY}"
    [ "$status" -ne 0 ]
}

@test "a plugin declaring only init and dod-keys registers" {
    local dir; dir=$(make_plugin qg init,dod-keys)
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]
    run grep -c '^qg' "${REGISTRY}"
    [ "$output" -eq 1 ]
}

# --- SC-7: what the point leaves behind ---------------------------------------------------

@test "an init point leaves the repo passing gate.sh config" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo sc7)
    install_merging_init "${dir}"
    run "${PLUGIN_SH}" add "${dir}"
    [ "$status" -eq 0 ]

    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 0 ]

    run_point init "${repo}" /v testrepo
    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 0 ]
    run grep -c '^guard_release_pattern:' "${repo}/VAULT.md"
    [ "$output" -eq 1 ]
}

@test "an init point appending to a VAULT.md with no trailing newline does not fuse two keys" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo nonl)
    install_merging_init "${dir}"
    run "${PLUGIN_SH}" add "${dir}"

    # make_repo strips the trailing newline on purpose.
    run bash -c "tail -c1 '${repo}/VAULT.md' | wc -l"
    [ "$output" -eq 0 ]

    run_point init "${repo}" /v testrepo
    run grep -c '^plugins: qg$' "${repo}/VAULT.md"
    [ "$output" -eq 1 ]
}

@test "running vault-init twice changes the plugins line only once" {
    local dir repo; dir=$(make_plugin qg init,dod-keys); repo=$(make_repo twice)
    install_merging_init "${dir}"
    run "${PLUGIN_SH}" add "${dir}"

    run_point init "${repo}" /v testrepo
    run_point init "${repo}" /v testrepo

    run grep -c '^plugins:' "${repo}/VAULT.md"
    [ "$output" -eq 1 ]
    run grep -c 'qg' "${repo}/VAULT.md"
    [ "$output" -eq 1 ]
}

# --- the registry itself ------------------------------------------------------------------

@test "an empty registry runs nothing and prints nothing" {
    mkdir -p "$(dirname "${REGISTRY}")"
    printf 'name\tpath\tpoints\n' > "${REGISTRY}"
    run_point init /r /v s
    [ "$output" = "HOSTRC=0" ]
}

@test "a registry whose line 1 is not the header yields no plugins" {
    mkdir -p "$(dirname "${REGISTRY}")"
    printf '# name\tpath\tpoints\nqg\t/nowhere\tinit\n' > "${REGISTRY}"
    run bash -c ". '${LIB}'; vault_plugin_list; echo RC=\$?"
    [[ "$output" != *"/nowhere"* ]]
}

@test "a registry holding two rows with the same name is refused" {
    mkdir -p "$(dirname "${REGISTRY}")"
    printf 'name\tpath\tpoints\nqg\t/a\tinit\nqg\t/b\tinit\n' > "${REGISTRY}"
    run bash -c ". '${LIB}'; vault_plugin_list"
    [ "$status" -eq 1 ]
    [[ "$output" == *"more than one row named"* ]]
}

@test "a plugin path containing a space registers, runs, and does not corrupt the next row" {
    local spaced="${TEST_HOME}/with space"
    mkdir -p "${spaced}/extend"
    printf 'name\tpoints\n%s\t%s\n' "spaced" "init" > "${spaced}/extend/plugin.tsv"
    printf '#!/usr/bin/env bash\necho SPACED_OK\n' > "${spaced}/extend/init.sh"
    chmod +x "${spaced}/extend/init.sh"
    run "${PLUGIN_SH}" add "${spaced}"
    [ "$status" -eq 0 ]

    local other; other=$(make_plugin qg init)
    run "${PLUGIN_SH}" add "${other}"
    [ "$status" -eq 0 ]

    run_point init /r /v s
    [[ "$output" == *"SPACED_OK"* ]]
    [[ "$output" == *"ARGS /r /v s proof"* ]]
}

@test "a row whose field count differs from the header is skipped, not mis-parsed" {
    mkdir -p "$(dirname "${REGISTRY}")"
    printf 'name\tpath\tpoints\nshort\t/a\nqg\t/b\tinit\n' > "${REGISTRY}"
    run bash -c ". '${LIB}'; vault_plugin_list"
    [[ "$output" != *"short"* ]]
    [[ "$output" == *"qg"* ]]
}

# --- the shipped skeleton -----------------------------------------------------------------

@test "the shipped plugin template registers and runs without edits beyond its example rows" {
    cp -r "${VAULT_ROOT}/templates/plugin" "${TEST_HOME}/tmpl"
    chmod +x "${TEST_HOME}/tmpl/extend/init.sh"
    # The template ships its rows commented; a real plugin uncomments them.
    sed -i 's/^# my-plugin\t/my-plugin\t/' "${TEST_HOME}/tmpl/extend/plugin.tsv"
    sed -i 's/^# my_setting\t/my_setting\t/' "${TEST_HOME}/tmpl/extend/dod-keys.tsv"

    run "${PLUGIN_SH}" add "${TEST_HOME}/tmpl"
    [ "$status" -eq 0 ]

    local repo; repo=$(make_repo tmpl)
    run_point init "${repo}" /v testrepo
    run_point init "${repo}" /v testrepo

    run grep -c '^plugins:' "${repo}/VAULT.md"
    [ "$output" -eq 1 ]
    run "${GATE_SH}" config "${repo}"
    [ "$status" -eq 0 ]
}

@test "the template's headers are exactly what the parser binds" {
    run head -1 "${VAULT_ROOT}/templates/plugin/extend/plugin.tsv"
    [ "$output" = "$(printf 'name\tpoints')" ]
    run head -1 "${VAULT_ROOT}/templates/plugin/extend/dod-keys.tsv"
    [ "$output" = "$(printf 'key\twhy')" ]
}

# --- install: one repo name, the script does the rest -------------------------------------

@test "install refuses a bare name that the marketplace does not list, and clones nothing" {
    run "${PLUGIN_SH}" install totally-made-up --dir "${TEST_HOME}/plugs"
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot resolve"* ]]
    run test -e "${TEST_HOME}/plugs"
    [ "$status" -ne 0 ]
}

@test "install on a path that is not a plugin refuses and writes no registry row" {
    mkdir -p "${TEST_HOME}/notaplugin"
    run "${PLUGIN_SH}" install "${TEST_HOME}/notaplugin"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a framework plugin"* ]]
    run test -e "${REGISTRY}"
    [ "$status" -ne 0 ]
}

@test "install without a terminal registers nothing unless --yes is given" {
    local dir; dir=$(make_plugin qg init,dod-keys)
    # bats gives the test no tty on stdin, which is the piped-run case exactly.
    run "${PLUGIN_SH}" install "${dir}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no terminal to confirm at"* ]]
    run test -e "${REGISTRY}"
    [ "$status" -ne 0 ]
}

@test "install names the plugin, its path and its points before asking" {
    local dir; dir=$(make_plugin qg init,dod-keys)
    run "${PLUGIN_SH}" install "${dir}"
    [[ "$output" == *"plugin  qg"* ]]
    [[ "$output" == *"points  init,dod-keys"* ]]
    [[ "$output" == *"trusts every future commit"* ]]
}

@test "install --yes on a local path registers it" {
    local dir; dir=$(make_plugin qg init,dod-keys)
    run "${PLUGIN_SH}" install "${dir}" --yes
    [ "$status" -eq 0 ]
    run grep -c '^qg' "${REGISTRY}"
    [ "$output" -eq 1 ]
}

@test "install never pulls a clone it already has" {
    local dir; dir=$(make_plugin qg init)
    mkdir -p "${TEST_HOME}/plugs"
    cp -r "${dir}" "${TEST_HOME}/plugs/qg"
    run "${PLUGIN_SH}" install "${TEST_HOME}/plugs/qg" --yes
    [ "$status" -eq 0 ]
    [[ "$output" != *"cloning"* ]]
}
