#!/usr/bin/env bats
# Behaviour tests for bin/probe.sh and the probes under probes/. Contract: commands/_shared/probe-kit.md.
#
# Every case builds a repo in a temp directory, runs the kit, and asserts stdout rows, stderr status lines
# and the exit code. Run in the container, whose awk is BusyBox: `./tests/run.sh tests/unit/probe.bats`.

bats_require_minimum_version 1.5.0
load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    PROBE="${VAULT_ROOT}/bin/probe.sh"
    FX="${VAULT_ROOT}/tests/fixtures/probe"
    TMP="$(mktemp -d)"
    REPO="${TMP}/repo"
    TAB=$'\t'
    mkdir -p "${REPO}/probes"
}

teardown() {
    rm -rf "${TMP}"
}

# addrow <id> <stage> <detect> <run> [parser cost trust install] — appends a row to the repo registry.
addrow() {
    printf '%s\tharness\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "${5:-native}" "${6:-S}" "${7:-no}" "${8:-none}" \
        >> "${REPO}/probes/registry.tsv"
}

pr() { run --separate-stderr "${PROBE}" "$@"; }

# rrun <id> — runs only that repo row, with the repo registry allowed.
rrun() { pr run plan --repo "${REPO}" --allow-repo-registry --only "$1"; }

@test "T-1: a bad registry line exits 2 and names the line" {
    printf 'a\tharness\tplan\ttrue\ttrue\tnative\tS\tno\n' > "${REPO}/probes/registry.tsv"
    pr list --repo "${REPO}" --allow-repo-registry
    [ "$status" -eq 2 ]; [[ $stderr == *"registry.tsv:1:"* ]]
    printf 'a\tharness\tplan\ttrue\ttrue\tnative\tS\tno\tnone\textra\n' > "${REPO}/probes/registry.tsv"
    pr list --repo "${REPO}" --allow-repo-registry; [ "$status" -eq 2 ]
    printf 'a\tharness\tnever\ttrue\ttrue\tnative\tS\tno\tnone\n' > "${REPO}/probes/registry.tsv"
    pr list --repo "${REPO}" --allow-repo-registry; [ "$status" -eq 2 ]; [[ $stderr == *"stage"* ]]
    printf 'a\tharness\tplan\ttrue\ttrue\tnative\tX\tno\tnone\n' > "${REPO}/probes/registry.tsv"
    pr list --repo "${REPO}" --allow-repo-registry; [ "$status" -eq 2 ]; [[ $stderr == *"cost"* ]]
    : > "${REPO}/probes/registry.tsv"; addrow a plan true true; addrow a plan true true
    pr list --repo "${REPO}" --allow-repo-registry; [ "$status" -eq 2 ]; [[ $stderr == *"twice"* ]]
}

@test "T-2: exit codes are 0 clean, 1 finding, 2 absent, and every probe that ran says so" {
    addrow clean plan true true
    addrow hit plan true 'printf "hit\ta.md\t3\twarn\tr\tm\n"'
    addrow gone plan true 'no-such-tool-xyz --x' native S no 'touch nothing'
    rrun clean; [ "$status" -eq 0 ]; [ -z "$output" ]; [[ $stderr == *"ran: clean: 0"* ]]
    rrun hit;   [ "$status" -eq 1 ]; [[ $stderr == *"ran: hit: 1"* ]]
    rrun gone;  [ "$status" -eq 2 ]; [[ $stderr == *"absent: gone: touch nothing"* ]]
    pr run plan --repo "${REPO}" --allow-repo-registry
    [ "$status" -eq 2 ]; [ "$output" = "hit${TAB}a.md${TAB}3${TAB}warn${TAB}r${TAB}m" ]
}

@test "T-3: a malformed row, bad severity or non-numeric line fails the probe and prints nothing" {
    addrow five plan true 'printf "a\tb\tc\td\te\n"'
    addrow sev plan true 'printf "p\tf\t1\tfatal\tr\tm\n"'
    addrow num plan true 'printf "p\tf\tx\twarn\tr\tm\n"'
    addrow abs plan true 'printf "p\t/etc/passwd\t1\twarn\tr\tm\n"'
    addrow up plan true 'printf "p\t../x\t1\twarn\tr\tm\n"'
    for id in five sev num abs up; do
        rrun $id; [ "$status" -eq 2 ]; [ -z "$output" ]; [[ $stderr == *"failed: $id"* ]]
    done
}

@test "T-4: an absent tool prints its install command and installs nothing" {
    addrow needs plan true 'no-such-tool-xyz' native S no "touch ${TMP}/marker"
    rrun needs
    [ "$status" -eq 2 ]; [[ $stderr == *"absent: needs: touch ${TMP}/marker"* ]]
    [ ! -e "${TMP}/marker" ]
}

@test "T-5: a repo registry needs the flag, and --no-repo-code skips it and every yes row" {
    addrow mine plan true "touch ${TMP}/ran-mine"
    printf 'a note\n' > "${REPO}/note.md"
    pr run plan --repo "${REPO}"; [ ! -e "${TMP}/ran-mine" ]
    pr run plan --repo "${REPO}" --allow-repo-registry; [ -e "${TMP}/ran-mine" ]; rm -f "${TMP}/ran-mine"
    pr run plan --repo "${REPO}" --allow-repo-registry --no-repo-code
    [ ! -e "${TMP}/ran-mine" ]; [[ $stderr == *"skipped: mine"* ]]
    pr run plan --repo "${REPO}" --no-repo-code --only md-links
    [[ $stderr == *"ran: md-links"* ]]
    pr run plan --repo "${VAULT_ROOT}" --no-repo-code --only claude-validate
    [[ $stderr == *"skipped: claude-validate"* ]]
}

@test "T-6: scale prints size and the cost class that fits, and --max-cost skips dearer rows" {
    git -C "${REPO}" init -q
    for i in 1 2 3; do printf 'x\n' > "${REPO}/f$i.txt"; done
    addrow cheap plan true "touch ${TMP}/cheap" native S
    addrow mid plan true "touch ${TMP}/mid" native M
    git -C "${REPO}" add f1.txt f2.txt f3.txt probes/registry.tsv
    PROBE_SCALE_L=10 PROBE_SCALE_M=20 pr scale --repo "${REPO}"
    [[ $output == *"files${TAB}4"* ]]; [[ $output == *"max-cost${TAB}L"* ]]
    PROBE_SCALE_L=2 PROBE_SCALE_M=3 pr scale --repo "${REPO}"; [[ $output == *"max-cost${TAB}S"* ]]
    pr run plan --repo "${REPO}" --allow-repo-registry --max-cost S
    [ -e "${TMP}/cheap" ]; [ ! -e "${TMP}/mid" ]; [[ $stderr == *"skipped: mid"* ]]
}

@test "T-7: a symlink, a symlinked directory and a hostile name leak nothing, in a plain directory and in git" {
    mkdir -p "${TMP}/outside"; printf '[x](TOPSECRET-missing.md)\n' > "${TMP}/outside/secret.md"
    ln -s "${TMP}/outside/secret.md" "${REPO}/leak.md"; ln -s "${TMP}/outside" "${REPO}/linkdir"
    printf '[x](gone.md)\n' > "${REPO}/real.md"
    printf '[x](gone-tab.md)\n' > "${REPO}/a${TAB}b.md"
    printf '[x](gone-nl.md)\n' > "${REPO}/x"$'\n'"y.md"
    pr run plan --repo "${REPO}" --only md-links
    [ "$status" -eq 1 ]; [[ $output != *TOPSECRET* ]]; [[ $output == *"real.md"* ]]
    [[ $output != *"leak.md"* ]]; [[ $output != *"linkdir"* ]]; [[ $stderr == *"skipped: files: 2"* ]]
    git -C "${REPO}" init -q; git -C "${REPO}" add leak.md linkdir real.md
    pr run plan --repo "${REPO}" --only md-links
    [ "$status" -eq 1 ]; [[ $output != *TOPSECRET* ]]; [[ $output != *"leak.md"* ]]
}

@test "T-8: md-links reports a missing target and skips fences, urls and anchors" {
    printf 'a\n' > "${REPO}/there.md"
    { printf '[ok](there.md) [gone](gone.md) [web](http://x.example/a) [up](#top) [mail](mailto:a@b.c)\n'
      printf '```\n[fenced](fenced-gone.md)\n```\n[out](../../../../etc/passwd)\n'; } > "${REPO}/doc.md"
    pr run plan --repo "${REPO}" --only md-links
    [ "$status" -eq 1 ]
    [[ $output == *"doc.md${TAB}1${TAB}error${TAB}broken-link${TAB}link target not found: gone.md"* ]]
    [[ $output != *"fenced-gone"* ]]; [[ $output != *"http"* ]]
    [[ $output == *"link leaves the repository"* ]]
    [ "$(printf '%s\n' "$output" | grep -c '')" -eq 2 ]
}

@test "T-9: dead-files reports a file no other file mentions and skips entry points" {
    mkdir -p "${REPO}/lib" "${REPO}/commands"
    printf 'source a.sh\n' > "${REPO}/lib/b.sh"; printf 'x\n' > "${REPO}/lib/a.sh"
    printf 'x\n' > "${REPO}/lib/README.md"; printf 'x\n' > "${REPO}/commands/entry.md"
    pr run plan --repo "${REPO}" --only dead-files
    [ "$status" -eq 1 ]; [[ $output == *"lib/b.sh${TAB}0${TAB}info${TAB}unreferenced-file"* ]]
    [[ $output != *"lib/a.sh"* ]]; [[ $output != *"README"* ]]; [[ $output != *"entry.md"* ]]
    mkdir -p "${REPO}/commands/x"; printf 'x\n' > "${REPO}/commands/x/orphan.md"
    printf '\033@@FILE\tcommands/x/orphan.md\nmentions orphan.md\n' > "${REPO}/notes.txt"
    pr run plan --repo "${REPO}" --only dead-files
    [[ $output != *"commands/x/orphan.md"* ]]
}

@test "T-10: token-size reports a file over the limit and none under it" {
    mkdir -p "${REPO}/lib"; head -c 100 /dev/zero | tr '\0' 'a' > "${REPO}/lib/big.md"; printf 'small\n' > "${REPO}/lib/small.md"
    PROBE_TOKEN_MAX=10 pr run plan --repo "${REPO}" --only token-size
    [ "$status" -eq 1 ]; [[ $output == *"lib/big.md${TAB}0${TAB}warn${TAB}large-file"* ]]; [[ $output != *"small.md"* ]]
    pr run plan --repo "${REPO}" --only token-size; [ "$status" -eq 0 ]
}

@test "T-16: each parser turns its captured fixture into rows and prints nothing for empty input" {
    run bash -c '. "$1/lib/probe-parsers.sh"; PROBE_CCN=4 parse_lizard_csv lizard /x < "$2/lizard.csv"' _ "${VAULT_ROOT}" "${FX}"
    [ "$status" -eq 0 ]; [ "$(printf '%s\n' "$output" | grep -c '')" -eq 3 ]
    [[ ${lines[0]} == "lizard${TAB}a.php${TAB}2${TAB}warn${TAB}high-complexity${TAB}"* ]]
    run bash -c '. "$1/lib/probe-parsers.sh"; parse_typos_json typos /x < "$2/typos.jsonl"' _ "${VAULT_ROOT}" "${FX}"
    [ "${lines[0]}" = "typos${TAB}f/a.txt${TAB}1${TAB}warn${TAB}typo${TAB}\"recieve\" should be \"receive\"" ]
    run bash -c '. "$1/lib/probe-parsers.sh"; parse_typos_json typos /x < /dev/null' _ "${VAULT_ROOT}"
    [ "$status" -eq 0 ]; [ -z "$output" ]
    run bash -c '. "$1/lib/probe-parsers.sh"; parse_claude_validate cv /work/repo < "$2/claude-validate.json"' _ "${VAULT_ROOT}" "${FX}"
    [ "${lines[0]}" = "cv${TAB}.claude-plugin/plugin.json${TAB}0${TAB}error${TAB}plugin-version${TAB}Invalid input" ]
    [[ ${lines[1]} == "cv${TAB}commands/step.md${TAB}0${TAB}warn${TAB}plugin-frontmatter${TAB}No frontmatter"* ]]
}

@test "T-17: diff keeps findings in changed and untracked files and exits 2 outside git" {
    g() { git -C "${REPO}" -c user.email=t@t -c user.name=t "$@"; }
    g init -q; printf '[x](gone-a.md)\n' > "${REPO}/a.md"; printf '[x](gone-b.md)\n' > "${REPO}/b.md"
    g add a.md b.md; g commit -q -m base
    printf 'more\n' >> "${REPO}/a.md"; printf '[x](gone-c.md)\n' > "${REPO}/c.md"
    pr diff --repo "${REPO}" --only md-links
    [ "$status" -eq 1 ]; [[ $output == *"a.md"* ]]; [[ $output == *"c.md"* ]]; [[ $output != *"b.md"* ]]
    mkdir -p "${TMP}/plain"; printf '[x](gone.md)\n' > "${TMP}/plain/a.md"
    pr diff --repo "${TMP}/plain" --only md-links; [ "$status" -eq 2 ]; [[ $stderr == *git* ]]
}

@test "T-18: a probe past the timeout is stopped with its child, reported failed, and the run exits 2" {
    addrow slow plan true 'sleep 31.7 & wait'
    PROBE_TIMEOUT=1 rrun slow
    [ "$status" -eq 2 ]; [[ $stderr == *"failed: slow: timed out"* ]]
    sleep 3
    run bash -c 'ps | grep "sleep 31.7" | grep -v grep'
    [ "$status" -ne 0 ]
}

@test "T-19: a repo path holding shell syntax runs no command" {
    weird="${TMP}/r\$(touch ${TMP}/pwned) x'y"
    mkdir -p "${weird}"; printf '[x](gone.md)\n' > "${weird}/a.md"
    pr run plan --repo "${weird}" --only md-links
    [ "$status" -eq 1 ]; [ ! -e "${TMP}/pwned" ]; [[ $output == *"a.md"* ]]
}

@test "T-20: diff runs no command from the repo's git configuration" {
    g() { git -C "${REPO}" -c user.email=t@t -c user.name=t "$@"; }
    g init -q; printf 'a\n' > "${REPO}/a.md"; g add a.md; g commit -q -m base
    g config core.fsmonitor "touch ${TMP}/fsmonitor-ran; echo"
    printf 'more\n' >> "${REPO}/a.md"
    pr diff --repo "${REPO}" --only md-links
    [ ! -e "${TMP}/fsmonitor-ran" ]
}

@test "T-21: a probe cannot forge another probe's row, and a failed probe prints none" {
    addrow liar plan true 'printf "other\ta.md\t1\twarn\tr\tm\n"'
    addrow split plan true 'printf "p\ta.md\t1\twarn\tr\tone\ntail of a split message\n"'
    rrun liar; [ "$output" = "liar${TAB}a.md${TAB}1${TAB}warn${TAB}r${TAB}m" ]
    rrun split; [ "$status" -eq 2 ]; [ -z "$output" ]
}

@test "T-22: a repo row repeating a framework id exits 2, and list and detect run no repo cell without the flag" {
    addrow md-links plan true true
    pr list --repo "${REPO}" --allow-repo-registry; [ "$status" -eq 2 ]; [[ $stderr == *twice* ]]
    : > "${REPO}/probes/registry.tsv"; addrow probing plan "touch ${TMP}/detect-ran" true
    pr list --repo "${REPO}" --allow-repo-registry; [ ! -e "${TMP}/detect-ran" ]
    pr detect --repo "${REPO}"; [ ! -e "${TMP}/detect-ran" ]
    pr detect --repo "${REPO}" --allow-repo-registry; [ -e "${TMP}/detect-ran" ]
}

@test "T-23: a probe printing past the output limit is stopped and fails the run" {
    addrow flood plan true 'yes A | head -c 200000'
    PROBE_OUT_MAX=4096 rrun flood
    [ "$status" -eq 2 ]; [[ $stderr == *"failed: flood"* ]]
}

@test "T-24: option values are checked" {
    pr run plan --repo "${REPO}" --only 'A b'; [ "$status" -eq 2 ]
    pr run plan --repo "${REPO}" --max-cost X; [ "$status" -eq 2 ]
    git -C "${REPO}" init -q
    pr diff --repo "${REPO}" --base -x; [ "$status" -eq 2 ]
}

@test "T-25: run refuses the stage diff, and diff runs plan, diff and review rows" {
    pr run diff --repo "${REPO}"; [ "$status" -eq 2 ]; [[ $stderr == *"probe.sh diff"* ]]
    g() { git -C "${REPO}" -c user.email=t@t -c user.name=t "$@"; }
    g init -q; printf 'a\n' > "${REPO}/a.md"; g add a.md; g commit -q -m base; printf 'b\n' >> "${REPO}/a.md"
    addrow p plan true true; addrow d diff true true; addrow r review true true
    pr diff --repo "${REPO}" --allow-repo-registry
    [[ $stderr == *"ran: p: 0"* ]]; [[ $stderr == *"ran: d: 0"* ]]; [[ $stderr == *"ran: r: 0"* ]]
}

@test "T-26: a tool row survives its own nonzero exit, and a native row exiting 2 fails" {
    cp "${FX}/lizard.csv" "${REPO}/l.csv"
    addrow tool plan true 'cat l.csv; exit 2' parse_lizard_csv S yes
    addrow bad plan true 'exit 127' parse_lizard_csv S yes
    addrow nat plan true 'sh -c "exit 2"'
    PROBE_CCN=4 rrun tool; [ "$status" -eq 1 ]; [[ $stderr == *"ran: tool: 3"* ]]
    rrun bad; [ "$status" -eq 2 ]; [[ $stderr == *"failed: bad"* ]]
    rrun nat; [ "$status" -eq 2 ]; [[ $stderr == *"failed: nat"* ]]
}

@test "T-27: an install command with an escape sequence prints without control bytes" {
    addrow esc plan true 'no-such-tool-xyz' native S no $'install \033[2J now'
    rrun esc
    [ "$status" -eq 2 ]; [[ $stderr == *"absent: esc: install"* ]]; [[ $stderr != *$'\033'* ]]
}

@test "T-28: a native row is present, a missing tool is absent, and list evaluates no repo text" {
    addrow evil plan true '$(touch '"${TMP}"'/evaluated)'
    addrow gone plan true 'no-such-tool-xyz' native S no 'do it'
    pr list --repo "${REPO}" --allow-repo-registry
    [[ $output == *"md-links${TAB}plan${TAB}M${TAB}framework${TAB}ok"* ]]
    [[ $output == *"gone${TAB}plan${TAB}S${TAB}repo${TAB}absent: do it"* ]]
    [ ! -e "${TMP}/evaluated" ]
}

@test "T-29: diff runs no filter command that the repo's config defines" {
    g() { git -C "${REPO}" -c user.email=t@t -c user.name=t "$@"; }
    g init -q; printf 'a\n' > "${REPO}/a.md"; printf '*.md filter=evil\n' > "${REPO}/.gitattributes"
    g add a.md .gitattributes; g commit -q -m base
    g config filter.evil.clean "touch ${TMP}/clean-ran; cat"
    g config filter.evil.process "touch ${TMP}/process-ran"
    g config filter.evil.required true
    printf 'more\n' >> "${REPO}/a.md"
    pr diff --repo "${REPO}" --only md-links
    [ "$status" -eq 0 ]; [[ $stderr == *"ran: md-links: 0"* ]]
    [ ! -e "${TMP}/clean-ran" ]; [ ! -e "${TMP}/process-ran" ]
}

@test "T-29b: a filter whose name holds an equals sign or a space runs nothing either" {
    g() { git -C "${REPO}" -c user.email=t@t -c user.name=t "$@"; }
    g init -q; printf 'a\n' > "${REPO}/a.md"; printf 'a.md filter=a=b\n' > "${REPO}/.gitattributes"
    g add a.md .gitattributes; g commit -q -m base
    printf '[filter "a=b"]\n\tclean = touch %s/eq-ran\n[filter "sp ace=x"]\n\tclean = touch %s/sp-ran\n' "${TMP}" "${TMP}" >> "${REPO}/.git/config"
    printf 'more\n' >> "${REPO}/a.md"
    pr diff --repo "${REPO}" --only md-links
    [ "$status" -eq 0 ]; [[ $stderr == *"ran: md-links: 0"* ]]
    [ ! -e "${TMP}/eq-ran" ]; [ ! -e "${TMP}/sp-ran" ]
}

@test "T-30: an option without its value exits 2 instead of hanging" {
    run timeout 5 "${PROBE}" run plan --repo; [ "$status" -eq 2 ]
    run timeout 5 "${PROBE}" run plan --only; [ "$status" -eq 2 ]
    run timeout 5 "${VAULT_ROOT}/probes/similar-symbols.sh" --check similar-symbols --names; [ "$status" -eq 2 ]
}

@test "T-31: a tracked path whose directory became a symlink is not read" {
    g() { git -C "${REPO}" -c user.email=t@t -c user.name=t "$@"; }
    g init -q; mkdir -p "${REPO}/sub" "${TMP}/outside"; printf '[x](TOPSECRET.md)\n' > "${REPO}/sub/x.md"
    g add sub/x.md; g commit -q -m base
    printf '[x](TOPSECRET.md)\n' > "${TMP}/outside/x.md"; rm -r "${REPO}/sub"; ln -s "${TMP}/outside" "${REPO}/sub"
    pr run plan --repo "${REPO}" --only md-links
    [ "$status" -eq 0 ]; [[ $output != *TOPSECRET* ]]; [[ $output != *"sub/x.md"* ]]
}

@test "T-32: diff in a subdirectory of a git worktree sees the files under it" {
    g() { git -C "${TMP}/top" -c user.email=t@t -c user.name=t "$@"; }
    mkdir -p "${TMP}/top/pkg"; g init -q; printf '[x](gone.md)\n' > "${TMP}/top/pkg/a.md"; printf '[x](gone.md)\n' > "${TMP}/top/b.md"
    g add pkg/a.md b.md; g commit -q -m base; printf 'more\n' >> "${TMP}/top/pkg/a.md"; printf 'more\n' >> "${TMP}/top/b.md"
    pr diff --repo "${TMP}/top/pkg" --only md-links
    [ "$status" -eq 1 ]; [[ $output == *"a.md"* ]]; [[ $output != *"b.md"* ]]
}

@test "T-33: a file named like an awk assignment does not hide the files after it" {
    printf '[x](gone-a.md)\n' > "${REPO}/a=b.md"; printf '[x](gone-z.md)\n' > "${REPO}/z.md"
    pr run plan --repo "${REPO}" --only md-links
    [ "$status" -eq 1 ]; [[ $output == *"a=b.md"* ]]; [[ $output == *"z.md"* ]]
}

@test "T-34: an unknown probe id is refused" {
    pr run plan --repo "${REPO}" --only no-such-probe; [ "$status" -eq 2 ]; [[ $stderr == *"no probe named"* ]]
    pr run review --repo "${REPO}" --only md-links; [ "$status" -eq 2 ]
}

@test "T-35: a signal stops the running probe's whole group and removes the temp directory" {
    addrow slow plan true 'sleep 33.3 & wait'
    mkdir -p "${TMP}/tmpdir"
    TMPDIR="${TMP}/tmpdir" "${PROBE}" run plan --repo "${REPO}" --allow-repo-registry --only slow >/dev/null 2>&1 &
    pid=$!; sleep 2; kill -TERM "$pid"; wait "$pid" || true; sleep 1
    run bash -c 'ps | grep "sleep 33.3" | grep -v grep'; [ "$status" -ne 0 ]
    [ -z "$(ls "${TMP}/tmpdir")" ]
}

@test "T-37: md-links skips inline code, keeps parenthesised urls whole and resolves wikilinks from the root" {
    mkdir -p "${REPO}/docs" "${REPO}/notes"; printf 'x\n' > "${REPO}/docs/x_(1).md"; printf 'x\n' > "${REPO}/notes/idea.md"
    printf 'see `[[../nowhere/x]]` and [a](docs/x_(1).md) and [[notes/idea]] and [[notes/missing]]\n' > "${REPO}/doc.md"
    pr run plan --repo "${REPO}" --only md-links
    [ "$status" -eq 1 ]; [[ $output != *"nowhere"* ]]; [[ $output != *"x_(1)"* ]]; [[ $output != *"notes/idea"* ]]
    [[ $output == *"wikilink target not found: notes/missing"* ]]
}

@test "T-39: a tool row that exits nonzero with no output fails instead of reporting clean" {
    addrow broken plan true 'sh -c "echo boom >&2; exit 1"' parse_typos_json S yes
    rrun broken
    [ "$status" -eq 2 ]; [[ $stderr == *"failed: broken: exit 1 with no output"* ]]
}
