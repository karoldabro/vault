#!/usr/bin/env bats
# Tests for bin/change-map.sh — the relation map of a change that feeds the /v-cr review seats.
# Backlog ids T1-T12 of vault/plans/2026-10-24-1903-v-cr-abstract-review.md; titles start with the id.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    MAP="${VAULT_ROOT}/bin/change-map.sh"
    T="$(mktemp -d)"
    . "${VAULT_ROOT}/tests/fixtures/v-cr-seeded/mk-repo.sh"
}

teardown() { rm -rf "$T"; }

# commit <dir> <message> — commit everything with a fixed identity
commit() { git -C "$1" add -A; git -C "$1" -c user.name=t -c user.email=t@t commit -qm "$2"; }

seeded() { mkdir -p "$T/s"; vs_mk_repo "$T/s"; "$MAP" build --repo "$T/s" --base "$VS_BASE" --head HEAD > "$T/map"; }

row() { grep -qxF "$(printf '%s\t' "$@" | sed 's/\t$//')" "$T/map"; }

@test "T1: a body-only change to format_row yields its caller in bin/report.sh line 6" {
    seeded
    awk -F'\t' '$1 == "caller" && $2 == "lib/format.sh" && $3 == "format_row" && $4 == "bin/report.sh" && $5 == "6"' "$T/map" | grep -q .
}

@test "T2: an untested new function yields none rows; a tested file yields its test row" {
    seeded
    row test lib/slug.sh slug_make none - -
    row test lib/slug.sh - none - -
    awk -F'\t' '$1 == "test" && $2 == "lib/format.sh" && $4 == "tests/format.bats"' "$T/map" | grep -q .
}

@test "T3: a new file gets sibling rows from its directory, never a file in the diff, at most 5" {
    seeded
    awk -F'\t' '$1 == "sibling" && $2 == "lib/slug.sh" {print $4}' "$T/map" > "$T/sib"
    grep -qxF lib/pad.sh "$T/sib"
    grep -qxF lib/trim.sh "$T/sib"
    ! grep -qxF lib/format.sh "$T/sib"
    [ "$(wc -l < "$T/sib")" -le 5 ]
}

@test "T4: a test that always changed with the file and is missing from the diff is a co-change row" {
    seeded
    row co-change lib/format.sh - tests/format.bats - 4/4
    mkdir -p "$T/c"; vs_mk_clean_repo "$T/c"
    "$MAP" build --repo "$T/c" --base "$VS_BASE" --head HEAD > "$T/clean"
    ! awk -F'\t' '$1 == "co-change"' "$T/clean" | grep -q .
}

@test "T5: a Markdown file is referenced by path and by [[stem, and its backtick path is a reference" {
    local d="$T/m"; mkdir -p "$d/docs" "$d/bin"; git -C "$d" init -q -b main
    printf '# Guide\nRun `bin/tool.sh` first.\n' > "$d/docs/guide.md"
    printf '#!/bin/sh\necho tool\n' > "$d/bin/tool.sh"
    printf 'See docs/guide.md for setup.\n' > "$d/a.md"
    printf 'Also [[guide]].\n' > "$d/b.md"
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    printf '# Guide\nRun `bin/tool.sh` first, then rest.\n' > "$d/docs/guide.md"; commit "$d" head
    "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    awk -F'\t' '$1 == "referenced-by" && $4 == "a.md"' "$T/map" | grep -q .
    awk -F'\t' '$1 == "referenced-by" && $4 == "b.md"' "$T/map" | grep -q .
    awk -F'\t' '$1 == "references" && $2 == "docs/guide.md" && $4 == "bin/tool.sh" && $5 == "2"' "$T/map" | grep -q .
}

@test "T6: a removed definition still yields caller rows for its remaining uses" {
    local d="$T/r"; mkdir -p "$d/lib" "$d/bin"; git -C "$d" init -q -b main
    printf 'keep() {\n    echo keep\n}\nold_fn() {\n    echo old\n}\n' > "$d/lib/a.sh"
    printf '. lib/a.sh\nold_fn\n' > "$d/bin/b.sh"
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    printf 'keep() {\n    echo keep\n}\n' > "$d/lib/a.sh"; commit "$d" head
    "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    row caller lib/a.sh old_fn bin/b.sh 2 old_fn
}

@test "T7: VCR_MAP_CAP keeps that many rows per relation and map-status reports the withheld count" {
    local d="$T/k"; mkdir -p "$d"; git -C "$d" init -q -b main
    printf 'x\n' > "$d/target.md"
    for i in 1 2 3 4 5; do printf 'see target.md\n' > "$d/r$i.md"; done
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    printf 'y\n' > "$d/target.md"; commit "$d" head
    VCR_MAP_CAP=2 "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    [ "$(awk -F'\t' '$1 == "referenced-by"' "$T/map" | wc -l)" -eq 2 ]
    tail -1 "$T/map" | grep -q $'^map-status\tcapped\t'
    tail -1 "$T/map" | grep -q $'\treferenced-by=2/3\t'
}

@test "T8: a commit with more files than VCR_MAP_MAX_COMMIT_FILES adds no co-change support" {
    local d="$T/w" i n; mkdir -p "$d"; git -C "$d" init -q -b main
    for n in 1 2 3; do
        printf '%s\n' "$n" > "$d/a.sh"; printf '%s\n' "$n" > "$d/b.sh"
        for i in $(seq 1 30); do printf '%s\n' "$n" > "$d/f$i.txt"; done
        commit "$d" "c$n"
    done
    local base; base=$(git -C "$d" rev-parse HEAD)
    printf 'x\n' > "$d/a.sh"; commit "$d" head
    "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    ! awk -F'\t' '$1 == "co-change"' "$T/map" | grep -q .
    VCR_MAP_MAX_COMMIT_FILES=40 "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    awk -F'\t' '$1 == "co-change" && $4 == "b.sh"' "$T/map" | grep -q .
}

@test "T9: slice keeps the persona's relations; map: [] gives only map-status; no key or a bad map exits 2" {
    seeded
    printf -- '---\nid: x\nmap: [caller, co-change]\n---\n# x\n' > "$T/p.md"
    run "$MAP" slice --map "$T/map" --persona "$T/p.md"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | head -1 | cut -f1)" = map-status ]
    ! printf '%s\n' "$output" | awk -F'\t' 'NR > 1 && $1 != "caller" && $1 != "co-change"' | grep -q .
    printf '%s\n' "$output" | grep -q $'^caller\t'
    printf -- '---\nid: y\nmap: []\n---\n' > "$T/e.md"
    run "$MAP" slice --map "$T/map" --persona "$T/e.md"
    [ "$status" -eq 0 ]; [ "$(printf '%s\n' "$output" | wc -l)" -eq 1 ]
    printf -- '---\nid: z\n---\n' > "$T/n.md"
    run "$MAP" slice --map "$T/map" --persona "$T/n.md"
    [ "$status" -eq 2 ]; [[ "$output" == *"has no map: key"* ]]
    printf 'caller\tonly three\tfields\n' > "$T/bad"
    run "$MAP" slice --map "$T/bad" --persona "$T/p.md"
    [ "$status" -eq 2 ]
}

@test "T10: slice --paths keeps those paths; VCR_SLICE_BYTES cuts rows and says how many" {
    seeded
    printf -- '---\nmap: [caller, test, sibling, referenced-by, references, co-change]\n---\n' > "$T/all.md"
    printf 'lib/slug.sh\n' > "$T/paths"
    run "$MAP" slice --map "$T/map" --persona "$T/all.md" --paths "$T/paths"
    ! printf '%s\n' "$output" | awk -F'\t' 'NR > 1 && $2 != "lib/slug.sh"' | grep -q .
    VCR_SLICE_BYTES=200 run "$MAP" slice --map "$T/map" --persona "$T/all.md"
    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | tail -1 | grep -qE '^withheld: [0-9]+ rows$'
}

@test "T11: a token, a tab and a control byte in a caller line stay one scrubbed row; GIT_DIR is ignored" {
    local d="$T/x"; mkdir -p "$d/lib"; git -C "$d" init -q -b main
    printf 'go_fn() {\n    echo a\n}\n' > "$d/lib/a.sh"
    printf 'go_fn ghp_abcdefghijklmnopqrstuvwxyz0123\tTAB\001CTL\n' > "$d/use.sh"
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    printf 'go_fn() {\n    echo b\n}\n' > "$d/lib/a.sh"; commit "$d" head
    mkdir -p "$T/other"; git -C "$T/other" init -q
    GIT_DIR="$T/other/.git" "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    local r; r=$(awk -F'\t' '$1 == "caller" && $4 == "use.sh"' "$T/map")
    [ -n "$r" ]
    [ "$(printf '%s' "$r" | awk -F'\t' '{print NF}')" -eq 6 ]
    [[ "$r" == *"[REDACTED]"* ]]
    [[ "$r" != *ghp_abcdef* ]]
}

@test "T12: a bad ref or a non-git repo exits 2; status prints coverage lines and refuses a map without status" {
    seeded
    run "$MAP" build --repo "$T/s" --base nosuchref --head HEAD
    [ "$status" -eq 2 ]
    mkdir -p "$T/plain"
    run "$MAP" build --repo "$T/plain" --base HEAD --head HEAD
    [ "$status" -eq 2 ]
    run "$MAP" status --map "$T/map"
    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | grep -qx 'map_status: complete'
    printf '%s\n' "$output" | grep -qx 'map_caller: [0-9]*/0'
    printf 'caller\ta\tb\tc\td\te\n' > "$T/nostatus"
    run "$MAP" status --map "$T/nostatus"
    [ "$status" -eq 2 ]
}

@test "T23: a git grep that fails after the refs resolve makes map-status partial and names the query" {
    seeded
    mkdir -p "$T/bin"
    printf '#!/bin/sh\nfor a; do [ "$a" = grep ] && exit 128; done\nexec git "$@"\n' > "$T/bin/fakegit"; chmod +x "$T/bin/fakegit"
    PROBE_GIT_BIN="$T/bin/fakegit" "$MAP" build --repo "$T/s" --base "$VS_BASE" --head HEAD > "$T/pmap"
    tail -1 "$T/pmap" | grep -q $'^map-status\tpartial\tgit grep '
}

@test "T24: a deleted file still yields caller and test rows for the definitions it removed" {
    local d="$T/del"; mkdir -p "$d/lib"; git -C "$d" init -q -b main
    printf 'gone_fn() {\n    echo gone\n}\n' > "$d/lib/del.sh"; printf 'gone_fn\n' > "$d/use.sh"
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    git -C "$d" rm -q lib/del.sh; commit "$d" head
    "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    row caller lib/del.sh gone_fn use.sh 1 gone_fn
    row test lib/del.sh gone_fn none - -
}

@test "T25: a path with a colon or non-ASCII bytes keeps its row fields in place" {
    local d="$T/odd"; mkdir -p "$d/lib"; git -C "$d" init -q -b main
    printf 'co_fn() {\n    echo a\n}\n' > "$d/lib/a:b.sh"; printf 'ca_fn() {\n    echo a\n}\n' > "$d/lib/café.sh"
    printf 'co_fn\nca_fn\n' > "$d/use.sh"
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    printf 'co_fn() {\n    echo b\n}\n' > "$d/lib/a:b.sh"; printf 'ca_fn() {\n    echo b\n}\n' > "$d/lib/café.sh"; commit "$d" head
    "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    row caller lib/a:b.sh co_fn use.sh 1 co_fn
    row caller lib/café.sh ca_fn use.sh 2 ca_fn
    ! awk -F'\t' '$1 == "caller" && $4 ~ /^lib\//' "$T/map" | grep -q .
}

@test "T26: in Python a call written like a shell definition does not become the changed symbol" {
    local d="$T/py"; mkdir -p "$d"; git -C "$d" init -q -b main
    printf 'def real():\n    setup()\n    return 1\n' > "$d/m.py"; printf 'from m import real\nreal()\n' > "$d/use.py"
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    printf 'def real():\n    setup()\n    return 2\n' > "$d/m.py"; commit "$d" head
    "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    awk -F'\t' '$1 == "caller" && $3 == "real" && $4 == "use.py"' "$T/map" | grep -q .
    ! awk -F'\t' '$1 == "caller" && $3 == "setup"' "$T/map" | grep -q .
}

@test "T27: siblings stop at five, newest commit first, and the --paths slice still exits 0 with rows" {
    local d="$T/sib" i; mkdir -p "$d/lib"; git -C "$d" init -q -b main
    for i in 1 2 3 4 5 6 7; do
        printf 'f%s() {\n    echo %s\n}\n' "$i" "$i" > "$d/lib/f$i.sh"
        GIT_COMMITTER_DATE="2026-01-0${i}T00:00:00Z" GIT_AUTHOR_DATE="2026-01-0${i}T00:00:00Z" commit "$d" "c$i"
    done
    local base; base=$(git -C "$d" rev-parse HEAD)
    printf 'n() {\n    echo n\n}\n' > "$d/lib/new.sh"; commit "$d" head
    "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    awk -F'\t' '$1 == "sibling" {print $4}' "$T/map" > "$T/siblist"
    [ "$(wc -l < "$T/siblist")" -eq 5 ]
    [ "$(head -1 "$T/siblist")" = lib/f7.sh ]
    ! grep -qxF lib/f1.sh "$T/siblist"
    printf -- '---\nmap: [sibling]\n---\n' > "$T/p.md"; printf 'lib/new.sh\n' > "$T/paths"
    run "$MAP" slice --map "$T/map" --persona "$T/p.md" --paths "$T/paths"
    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | grep -q $'^sibling\tlib/new.sh\t'
}

@test "T28: a moved file is not its own caller, a quoted path keeps its rows, and the caller cap is per symbol" {
    local d="$T/mv" i; mkdir -p "$d/lib"; git -C "$d" init -q -b main
    printf 'rf() {\n    echo a\n}\n' > "$d/lib/old.sh"; printf 'q_fn() {\n    echo a\n}\n' > "$d/lib/b\"q.sh"
    printf 'die() {\n    exit 1\n}\nzz_real() {\n    echo z\n}\n' > "$d/lib/c.sh"
    { for i in $(seq 1 25); do printf 'die\n'; done; printf 'zz_real\nq_fn\nrf\n'; } > "$d/use.sh"
    commit "$d" base; local base; base=$(git -C "$d" rev-parse HEAD)
    git -C "$d" mv lib/old.sh lib/new.sh
    printf 'q_fn() {\n    echo b\n}\n' > "$d/lib/b\"q.sh"
    printf 'die() {\n    exit 2\n}\nzz_real() {\n    echo y\n}\n' > "$d/lib/c.sh"; commit "$d" head
    VCR_MAP_CAP=20 "$MAP" build --repo "$d" --base "$base" --head HEAD > "$T/map"
    ! awk -F'\t' '$1 == "caller" && $3 == "rf" && $4 == "lib/new.sh"' "$T/map" | grep -q .
    awk -F'\t' '$1 == "caller" && $2 == "lib/b\"q.sh" && $4 == "use.sh"' "$T/map" | grep -q .
    [ "$(awk -F'\t' '$1 == "caller" && $3 == "die"' "$T/map" | wc -l)" -eq 20 ]
    awk -F'\t' '$1 == "caller" && $3 == "zz_real" && $4 == "use.sh"' "$T/map" | grep -q .
    tail -1 "$T/map" | grep -q $'^map-status\tcapped\t'
}
