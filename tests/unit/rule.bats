#!/usr/bin/env bats
# Behaviour and text guards for /v-rule: probes/rule-grep.sh, bin/rule-check.sh and commands/v-rule.md.
# Contract: commands/_shared/probe-kit.md "Rule files". The graders under checks/rule-SC-*.sh build fixture repos
# and decide each criterion; a case here runs one and prints its message when it fails.
# Run in the container: `./tests/run.sh tests/unit/rule.bats`.

load "../helpers/setup.bash"

setup() { export VAULT_ROOT="${VAULT_ROOT:-/code}"; RC="${VAULT_ROOT}/bin/rule-check.sh"; RG="${VAULT_ROOT}/probes/rule-grep.sh"; TMP="$(mktemp -d)"; }
teardown() { rm -rf "${TMP}"; }

grade() { run "${VAULT_ROOT}/checks/rule-SC-$1.sh"; [ "$status" -eq 0 ] || { echo "$output"; false; }; }
repo() { # repo <dir> <number of files that hold the bad line>
    mkdir -p "$1"; git -C "$1" init -q; git -C "$1" config user.email t@t; git -C "$1" config user.name t
    printf 'readme\n' > "$1/readme.txt"; local i
    for i in $(seq 1 "${2:-1}"); do printf '<?php DB::table("t%s");\n' "$i" > "$1/f$i.php"; done
    git -C "$1" add -A; git -C "$1" commit -qm base
}
draft() {
    mkdir -p "$1"; printf 'glob: *.php\npattern: DB::table\\(\nseverity: warn\nmessage: Use the repository\n' > "$1/s.grep"
    printf '<?php $x = DB::table("u");\n' > "$1/bad.php"; printf '<?php $x = 1;\n' > "$1/good.php"
}

@test "SC-1 the runner prints rows, skips probes/ and rejects a malformed rule" { grade 1; }
@test "SC-2 accept needs a firing bad fixture, a silent good fixture and at most 20 findings" { grade 2; }
@test "SC-3 install writes the rule, two fixtures and one template row, and refuses unsafe targets" { grade 3; }
@test "SC-4 verify reads a probe key back" { grade 4; }
@test "SC-5 own-comments keeps only the operator's user id" { grade 5; }
@test "SC-6 an installed rule reaches a review as an advisory row only under own with the variable" { grade 6; }
@test "SC-7 the skill text, its single homes and the master plan rows" { grade 7; }

@test "T-1 a rule that runs past PROBE_RULE_TIMEOUT exits 2 and the kit reports it failed" {
    repo "${TMP}/r"; mkdir -p "${TMP}/r/probes/rules" "${TMP}/bin"; draft "${TMP}/d"; cp "${TMP}/d/s.grep" "${TMP}/r/probes/rules/s.grep"
    printf '#!/bin/sh\ncase "$*" in *"-n -I"*) sleep 5 ;; *) for g in /usr/bin/grep /bin/grep; do [ -x $g ] && exec $g "$@"; done ;; esac\n' > "${TMP}/bin/grep"; chmod +x "${TMP}/bin/grep"
    PATH="${TMP}/bin:${PATH}" PROBE_RULE_TIMEOUT=1 run "${RG}" --check s --rule probes/rules/s.grep --repo "${TMP}/r"
    [ "$status" -eq 2 ]; [[ "$output" == *"timed out"* ]]
    printf 's\tany\tplan\ttrue\t"$PROBE_FRAMEWORK/probes/rule-grep.sh" --check s --rule probes/rules/s.grep\tnative\tS\tyes\tnone\n' > "${TMP}/r/probes/registry.tsv"
    PATH="${TMP}/bin:${PATH}" PROBE_RULE_TIMEOUT=1 run "${VAULT_ROOT}/bin/probe.sh" run plan --repo "${TMP}/r" --only s --allow-repo-registry
    [ "$status" -eq 2 ]; [[ "$output" == *"failed: s"* ]]
}

@test "T-2 RULE_MAX_FINDINGS above 20 accepts 21 findings, and the refusal names the limit" {
    repo "${TMP}/r" 21; draft "${TMP}/d"
    run "${RC}" accept --repo "${TMP}/r" --slug s --rule "${TMP}/d/s.grep" --bad "${TMP}/d/bad.php" --good "${TMP}/d/good.php"
    [ "$status" -eq 1 ]; [[ "$output" == *"limit 20"* ]]
    RULE_MAX_FINDINGS=30 run "${RC}" accept --repo "${TMP}/r" --slug s --rule "${TMP}/d/s.grep" --bad "${TMP}/d/bad.php" --good "${TMP}/d/good.php"
    [ "$status" -eq 0 ]
}

@test "T-3 glob: * crosses /, and several glob lines are alternatives" {
    repo "${TMP}/r"; mkdir -p "${TMP}/r/app/deep"; printf 'DB::table(1)\n' > "${TMP}/r/app/deep/x.php"; printf 'DB::table(2)\n' > "${TMP}/r/y.js"
    printf 'glob: app/*.php\nglob: *.js\npattern: DB::table\nseverity: info\nmessage: m\n' > "${TMP}/g.grep"
    run "${RG}" --check g --rule "${TMP}/g.grep" --repo "${TMP}/r" --count-files
    [ "$status" -eq 0 ]; [ "$output" = 2 ]
}

@test "T-4 install writes nothing when the fixture extensions differ or the slug is unsafe" {
    repo "${TMP}/r"; draft "${TMP}/d"; mv "${TMP}/d/good.php" "${TMP}/d/good.txt"
    run "${RC}" install --repo "${TMP}/r" --slug s --draft "${TMP}/d"
    [ "$status" -eq 1 ]; [ ! -e "${TMP}/r/probes" ]
    draft "${TMP}/e"
    for slug in 'a;id' 'a$(id)' '..' "$(printf 'a\tb')"; do
        run "${RC}" install --repo "${TMP}/r" --slug "$slug" --draft "${TMP}/e"; [ "$status" -eq 1 ]; [ ! -e "${TMP}/r/probes" ]
    done
}

@test "T-5 verify prints mislabelled and exits 1 for a hand-written row that says no" {
    repo "${TMP}/r"; mkdir -p "${TMP}/r/probes"
    printf 'liar\tany\tplan\ttrue\t./x.sh\tnative\tS\tno\tnone\n' > "${TMP}/r/probes/registry.tsv"
    run "${RC}" verify --repo "${TMP}/r" --slug liar
    [ "$status" -eq 1 ]; [ "$output" = "mislabelled liar" ]
}

@test "T-6 own-comments drops a comment whose user is null" {
    run bash -c "printf '%s' '[{\"id\":1,\"user\":null,\"body\":\"x\"},{\"id\":2,\"user\":{\"id\":5,\"type\":\"User\"},\"body\":\"y\"}]' | '${RC}' own-comments --operator-id 5 | jq -r '[.[].id] | join(\",\")'"
    [ "$status" -eq 0 ]; [ "$output" = "2" ]
}

@test "T-7 no review command names /v-rule (master plan D-12)" {
    cd "${VAULT_ROOT}"
    for f in v-cr v-team v-work v-do v-loop v-method v-pm; do
        run bash -c "grep -rl 'v-rule' commands/$f.md commands/$f 2>/dev/null || true"; [ -z "$output" ] || { echo "$output"; false; }
    done
}

@test "T-8 the row template lives in probe-kit.md once, and rule-check.sh row prints it" {
    cd "${VAULT_ROOT}"
    [ "$(grep -rlF -- '--rule probes/rules/' commands | tr -d ' ')" = "commands/_shared/probe-kit.md" ]
    run "${RC}" row --slug abc --stack php
    [ "$output" = "$(printf 'abc\tphp\tplan\ttest -f probes/rules/abc.grep\t"$PROBE_FRAMEWORK/probes/rule-grep.sh" --check abc --rule probes/rules/abc.grep\tnative\tS\tyes\tnone')" ]
    grep -qF 'test -f probes/rules/<slug>.grep' commands/_shared/probe-kit.md
}

@test "T-9 RULE_MAX_FINDINGS defaults to half of PROBE_PANEL_ROWS" {
    repo "${TMP}/r" 6; draft "${TMP}/d"
    PROBE_PANEL_ROWS=10 run "${RC}" accept --repo "${TMP}/r" --slug s --rule "${TMP}/d/s.grep" --bad "${TMP}/d/bad.php" --good "${TMP}/d/good.php"
    [ "$status" -eq 1 ]; [[ "$output" == *"limit 5"* ]]
}

@test "T-10 the probe kit does not lose its temp directory when it stops its watchdog" {
    repo "${TMP}/r"; printf '# a\n' > "${TMP}/r/a.md"
    local i bad=0
    for i in $(seq 1 40); do "${VAULT_ROOT}/bin/probe.sh" run plan --repo "${TMP}/r" --only token-size >/dev/null 2>&1; [ $? -ne 2 ] || bad=$((bad + 1)); done
    [ "$bad" -eq 0 ]
}

@test "T-11 verify accepts a relative --repo, and install keeps a registry that lacks a trailing newline" {
    repo "${TMP}/r"; draft "${TMP}/d"; mkdir -p "${TMP}/r/probes"
    printf 'old\tany\tplan\ttrue\ttrue\tnative\tS\tyes\tnone' > "${TMP}/r/probes/registry.tsv"
    run "${RC}" install --repo "${TMP}/r" --slug s --draft "${TMP}/d"; [ "$status" -eq 0 ]
    [ "$(grep -c '^old' "${TMP}/r/probes/registry.tsv")" -eq 1 ]; [ "$(grep -c '^s' "${TMP}/r/probes/registry.tsv")" -eq 1 ]
    cd "${TMP}/r"; run "${RC}" verify --repo . --slug s
    [ "$status" -eq 0 ]; [[ "$output" == "ok s "* ]]
}

@test "T-12 a matched line holding the bytes 0x01 or 0x02 cannot forge a finding row" {
    repo "${TMP}/r"; printf 'DB::table(9)\001\002evil\001x.php\n' > "${TMP}/r/z.php"
    printf 'glob: z.php\npattern: DB::table\nseverity: warn\nmessage: m\n' > "${TMP}/g.grep"
    run "${RG}" --check g --rule "${TMP}/g.grep" --repo "${TMP}/r"
    [ "$status" -eq 1 ]; [ "$(printf '%s\n' "$output" | grep -c '')" -eq 1 ]
    [ "$(printf '%s\n' "$output" | cut -f2)" = "z.php" ]
}

@test "T-13 a non-numeric RULE_MAX_FINDINGS and an unknown stack exit 2" {
    repo "${TMP}/r"; draft "${TMP}/d"
    RULE_MAX_FINDINGS=abc run "${RC}" accept --repo "${TMP}/r" --slug s --rule "${TMP}/d/s.grep" --bad "${TMP}/d/bad.php" --good "${TMP}/d/good.php"
    [ "$status" -eq 2 ]
    run "${RC}" row --slug s --stack bogus; [ "$status" -eq 2 ]
}

@test "T-14 install and accept refuse a draft fixture that is a symlink, and copy nothing" {
    repo "${TMP}/r"; draft "${TMP}/d"; printf 'API_KEY=secret\n' > "${TMP}/secret"; rm "${TMP}/d/bad.php"; ln -s "${TMP}/secret" "${TMP}/d/bad.php"
    run "${RC}" install --repo "${TMP}/r" --slug s --draft "${TMP}/d"; [ "$status" -eq 1 ]; [ ! -e "${TMP}/r/probes" ]
    run "${RC}" accept --repo "${TMP}/r" --slug s --rule "${TMP}/d/s.grep" --bad "${TMP}/d/bad.php" --good "${TMP}/d/good.php"; [ "$status" -eq 1 ]
}
