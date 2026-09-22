#!/usr/bin/env bats
# Behaviour and text guards for the plan-time probe stage. Contract: commands/_shared/plan-probes.md.
#
# The graders under checks/plan-probe-SC-*.sh build fixtures and decide each criterion; a case here runs one and prints
# its message when it fails. Run in the container: `./tests/run.sh tests/unit/plan-probes.bats`.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"; TMP="$(mktemp -d)"
    PP="${VAULT_ROOT}/bin/plan-probes.sh"; PANEL="${VAULT_ROOT}/bin/probe-panel.sh"; SIM="${VAULT_ROOT}/probes/similar-symbols.sh"
    T=$(printf '\t')
}

teardown() { rm -rf "${TMP}"; }

grade() { run "${VAULT_ROOT}/checks/plan-probe-SC-$1.sh"; [ "$status" -eq 0 ] || { echo "$output"; false; }; }

@test "T-10 the plan stage prints the review block with no posture and no base, and the diff stage is unchanged" { grade 1; }
@test "T-11 spec-symbols reads the cell grammar and names a spec outside the repo by its base name" { grade 2; }
@test "T-4 T-5 T-6 T-7 verify blocks on a confirmed error only, prints the block's rows, and needs a tier" { grade 3; }
@test "T-1 T-2 T-3 budget picks the tier at the exact limit and refuses bad input" { grade 4; }
@test "T-8 T-9 measure counts each message once inside the window across subagent files" { grade 5; }
@test "the stage on two real past specs stays under 50% of their recorded baselines" { grade 6; }
@test "T-14 step (b2) sits between (b) and (c), plan-probes.md lists the auditors, the rule count is unchanged" { grade 7; }

@test "T-12 shuffling Reuse-map rows and adding an unrelated row leave the other rows unchanged" {
    repo="${TMP}/repo"; mkdir -p "${repo}/lib"; printf 'alpha_one() { :; }\n' > "${repo}/lib/x.sh"
    head_="# x\n\n## Reuse map\n\n| need | existing symbol | decision | reason |\n|------|-----------------|----------|--------|\n"
    printf "${head_}| a | lib/x.sh gone_one | reuse | r |\n| b | lib/y.sh alpha_one | reuse | r |\n" > "${TMP}/one.md"
    printf "${head_}| b | lib/y.sh alpha_one | reuse | r |\n| c | lib/x.sh alpha_one | reuse | r |\n| a | lib/x.sh gone_one | reuse | r |\n" > "${TMP}/two.md"
    run "${SIM}" --check spec-symbols --repo "${repo}" --spec "${TMP}/one.md"
    [ "$status" -eq 1 ]; a=$(printf '%s\n' "$output" | cut -f4- | sort)
    run "${SIM}" --check spec-symbols --repo "${repo}" --spec "${TMP}/two.md"
    [ "$status" -eq 1 ]; b=$(printf '%s\n' "$output" | cut -f4- | sort)
    [ "$a" = "$b" ]
    [[ "$a" == *"reuse-symbol-missing"* && "$a" == *"reuse-path-missing"* ]]
}

@test "T-13 the stopwords in on by at from remove noise rows, and a row for an unlisted file stays" {
    repo="${TMP}/repo"; mkdir -p "${repo}/lib"
    printf 'load_in_place() { :; }\nrun_thing() { :; }\n' > "${repo}/lib/x.sh"
    printf '# x\n\n## Reuse map\n\n| need | existing symbol | decision | reason |\n|------|-----------------|----------|--------|\n| put it in a box | - | new | searched lib |\n| run a thing | - | new | searched lib |\n' > "${TMP}/s.md"
    run "${SIM}" --check similar-symbols --repo "${repo}" --spec "${TMP}/s.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"run_thing"* ]]
    [[ "$output" != *"load_in_place"* ]]
}

@test "verify treats an empty block as clean and a missing rows file as an error" {
    d="${TMP}/o"; mkdir -p "${d}"; printf 'full\n' > "${d}/tier.txt"
    run "${PP}" verify "${d}"; [ "$status" -eq 0 ]; [ -z "$output" ]
    run "${PP}" verify "${d}" "${TMP}/no-such-file"; [ "$status" -eq 2 ]
}

@test "budget prints its settings error on stderr and the probes and auditors lists are stable" {
    run "${PP}" probes; [ "$status" -eq 0 ]; [ "$output" = "$(printf 'similar-symbols\nspec-symbols\nspec-tables\nspec-naming')" ]
    run "${PP}" auditors; [ "$status" -eq 0 ]
    [ "$output" = "$(printf 'reuse%ssimilar-symbols spec-symbols\ndata-model%sspec-tables\nnaming%sspec-naming' "$T" "$T" "$T")" ]
    run "${PP}" nonsense; [ "$status" -eq 2 ]
}

@test "budget counts two distinct triggered auditors, not the probes that triggered them" {
    one="${TMP}/one"; two="${TMP}/two"
    { printf 'similar-symbols%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; printf 'unknown-idx%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; } > "$one"
    { printf 'similar-symbols%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; printf 'spec-tables%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; } > "$two"
    [ "$(wc -c < "$one")" -eq "$(wc -c < "$two")" ]
    a1=$("${PP}" budget --critics 1 --rounds 1 --block "$one" --out "${TMP}/o1" | sed -n 's/^projected: added=\([0-9]*\).*/\1/p')
    a2=$("${PP}" budget --critics 1 --rounds 1 --block "$two" --out "${TMP}/o2" | sed -n 's/^projected: added=\([0-9]*\).*/\1/p')
    [ "$((a2 - a1))" -eq 36000 ]
}

@test "verify applies the keep rule to three rows files independently, sums dropped lines, and notes a triggered auditor with no file passed" {
    d="${TMP}/o"; mkdir -p "${d}"; printf 'full\n' > "${d}/tier.txt"
    row1="spec-tables${T}f${T}1${T}warn${T}dup-column-set${T}m"
    row2="spec-naming${T}f${T}2${T}warn${T}naming-snake-case${T}m"
    row3="similar-symbols${T}f${T}3${T}warn${T}similar-symbol${T}m"
    printf '%s\n%s\n%s\n' "$row1" "$row2" "$row3" > "${d}/advisory.tsv"; : > "${d}/confirmed.tsv"
    printf 'applies\t%s\n' "$row1" > "${TMP}/r1"
    printf 'does-not-apply\t%s\n' "$row2" > "${TMP}/r2"
    printf 'unclear\t%s\nbogus\tnot-a-block-row\n' "$row3" > "${TMP}/r3"
    run "${PP}" verify "${d}" "${TMP}/r1" "${TMP}/r2" "${TMP}/r3"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies${T}${row1}"* ]]
    [[ "$output" == *"does-not-apply${T}${row2}"* ]]
    [[ "$output" == *"unclear${T}${row3}"* ]]
    [[ "$output" == *"note: 1 auditor lines were dropped"* ]]
    [[ "$output" != *"note: the naming auditor triggered"* ]]

    run "${PP}" verify "${d}" "${TMP}/r1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"note: the naming auditor triggered but no rows-file for it was passed to verify"* ]]
}

@test "the propose step names the three commands, and the stage text keeps the rules in one home" {
    loop="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"; md="${VAULT_ROOT}/commands/_shared/plan-probes.md"
    grep -q 'probe-panel.sh run --stage plan' "${loop}"
    grep -q 'plan-probes.sh budget' "${loop}"
    grep -q 'plan-probes.sh verify' "${loop}"
    grep -q 'critic-panel.md' "${md}"
    ! grep -q 'plans/YYYY-MM-DD-HHMM' "${md}"
    grep -q 'plans/YYYY-MM-DD-HHMM' "${loop}"
}

@test "T-15 a Reuse-map path with ./, :line, #L or a trailing colon is read, and a pipe escaped in a cell keeps its column" {
    repo="${TMP}/repo"; mkdir -p "${repo}/src"; printf 'fooBar() { :; }\n' > "${repo}/src/a.js"
    printf '## Reuse map (draft)\n\n| need | existing symbol | decision | reason |\n|------|-----------------|----------|--------|\n| a | ./src/a.js fooBar | **reuse** | ok |\n| b | src/a.js:42 fooBar | reuse | ok |\n| c | src/a.js#L3 fooBar | reuse | ok |\n| d | src/a.js: fooBar | extend | ok |\n| e \\| f | src/a.js missing1 | reuse | gap |\n' > "${TMP}/s.md"
    run "${SIM}" --check spec-symbols --repo "${repo}" --spec "${TMP}/s.md"
    [ "$status" -eq 1 ]; [ "$(printf '%s\n' "$output" | wc -l)" -eq 1 ]
    [[ "$output" == *"reuse-symbol-missing"*"missing1"* ]]
}

@test "T-16 a Reuse map without the two columns gives a warning row, and a directory is not a spec" {
    printf '## Reuse map\n\n| need | note |\n|------|------|\n| a | b |\n' > "${TMP}/s.md"
    run "${SIM}" --check spec-symbols --repo "${TMP}" --spec "${TMP}/s.md"
    [ "$status" -eq 1 ]; [[ "$output" == *"reuse-map-unreadable"* ]]
    run "${PANEL}" run --stage plan --spec "${TMP}" --repo "${TMP}"; [ "$status" -eq 2 ]
}

@test "T-17 verify reads a last line with no newline, and budget refuses values that would overflow" {
    d="${TMP}/o"; mkdir -p "${d}"; printf 'full\n' > "${d}/tier.txt"; printf 'p\tf\t1\terror\tr\tm' > "${d}/confirmed.tsv"
    run "${PP}" verify "${d}"; [ "$status" -eq 1 ]; [[ "$output" == "open: p f:1 m" ]]
    : > "${TMP}/b"
    PLAN_PROBE_BASE_TOKENS=0 run "${PP}" budget --critics 1 --rounds 1 --block "${TMP}/b" --out "${TMP}/x"; [ "$status" -eq 2 ]
    run "${PP}" budget --critics 1000000000 --rounds 1000000000 --block "${TMP}/b" --out "${TMP}/x"; [ "$status" -eq 2 ]
    mkdir -p "${TMP}/x"; ln -s "${TMP}/victim" "${TMP}/x/tier.txt"
    run "${PP}" budget --critics 1 --rounds 1 --block "${TMP}/b" --out "${TMP}/x"; [ "$status" -eq 2 ]; [ ! -e "${TMP}/victim" ]
}
