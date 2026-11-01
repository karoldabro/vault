#!/usr/bin/env bash
# mk-repo.sh — builds the fixture repos of vault/plans/2026-10-24-1903-v-cr-abstract-review.md (Test design
# dossier). Source it and call `vs_mk_repo <dir>` or `vs_mk_clean_repo <dir>`; each sets VS_BASE to the sha of
# the base commit and leaves the repo at the head commit.
#
# Base: commit 1 creates lib/args.sh, lib/format.sh, lib/pad.sh, lib/trim.sh, bin/report.sh and two tests;
# commits 2-4 each change lib/format.sh and tests/format.bats together.
# vs_mk_repo head plants three defects: format_row needs a third argument and bin/report.sh:6 still passes
# two (P1); lib/slug.sh adds slug_make with no test (P2) and no _need_args guard (P3).
# vs_mk_clean_repo head makes the same change with the caller, the guards and the tests updated, and adds
# tests/report.bats for the script's new argument.

vs__git() { # <dir> <message> — commit everything with a fixed author and date
    GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' \
        git -C "$1" -c user.name=fixture -c user.email=fixture@example.com add -A
    GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' \
        git -C "$1" -c user.name=fixture -c user.email=fixture@example.com commit -qm "$2"
}

vs__format() { # <dir> <revision> — lib/format.sh with the two-column format_row
    cat > "$1/lib/format.sh" <<EOF
#!/usr/bin/env bash
# format_row <name> <count> — revision $2
. "\$(dirname "\${BASH_SOURCE[0]}")/args.sh"
format_row() {
    _need_args 2 \$# || return 2
    printf '%s | %s\n' "\$1" "\$2"
}
EOF
    cat > "$1/tests/format.bats" <<EOF
#!/usr/bin/env bats
# revision $2
@test "format_row prints two columns" {
    . lib/format.sh
    run format_row a b
    [ "\$output" = "a | b" ]
}
EOF
}

vs__base() { # <dir>
    local d=$1
    mkdir -p "$d/lib" "$d/bin" "$d/tests"
    git -C "$d" init -q -b main
    cat > "$d/lib/args.sh" <<'EOF'
#!/usr/bin/env bash
# _need_args <want> <got> — returns 2 when fewer arguments arrived than wanted.
_need_args() {
    [ "$2" -ge "$1" ] && return 0
    printf 'need %s args\n' "$1" >&2
    return 2
}
EOF
    cat > "$d/lib/pad.sh" <<'EOF'
#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/args.sh"
pad_left() {
    _need_args 2 $# || return 2
    printf '%*s\n' "$1" "$2"
}
EOF
    cat > "$d/lib/trim.sh" <<'EOF'
#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/args.sh"
trim_space() {
    _need_args 1 $# || return 2
    printf '%s\n' "$1" | sed 's/^ *//; s/ *$//'
}
EOF
    cat > "$d/bin/report.sh" <<'EOF'
#!/usr/bin/env bash
. "$(dirname "$0")/../lib/format.sh"
name=$1
count=$2
# one row per call
format_row "$name" "$count"
EOF
    chmod +x "$d/bin/report.sh"
    cat > "$d/tests/pad.bats" <<'EOF'
#!/usr/bin/env bats
@test "pad_left pads to width" {
    . lib/pad.sh
    run pad_left 3 a
    [ "$output" = "  a" ]
}
EOF
    vs__format "$d" 1; vs__git "$d" "base: libraries, report and tests"
    vs__format "$d" 2; vs__git "$d" "format: revision 2"
    vs__format "$d" 3; vs__git "$d" "format: revision 3"
    vs__format "$d" 4; vs__git "$d" "format: revision 4"
    VS_BASE=$(git -C "$d" rev-parse HEAD)
}

vs__format_head() { # <dir> — the three-column format_row; the change edits only body lines
    cat > "$1/lib/format.sh" <<'EOF'
#!/usr/bin/env bash
# format_row <name> <count> <unit>
. "$(dirname "${BASH_SOURCE[0]}")/args.sh"
format_row() {
    _need_args 3 $# || return 2
    printf '%s | %s | %s\n' "$1" "$2" "$3"
}
EOF
}

vs_mk_repo() { # <dir>
    vs__base "$1"
    vs__format_head "$1"
    cat > "$1/lib/slug.sh" <<'EOF'
#!/usr/bin/env bash
# slug_make <title> — a file name for a report
slug_make() {
    printf '%s\n' "$1" | tr 'A-Z ' 'a-z-'
}
EOF
    vs__git "$1" "report rows gain a unit column; slug_make"
}

vs_mk_clean_repo() { # <dir>
    vs__base "$1"
    vs__format_head "$1"
    cat > "$1/bin/report.sh" <<'EOF'
#!/usr/bin/env bash
. "$(dirname "$0")/../lib/format.sh"
_need_args 3 $# || exit 2
name=$1
count=$2
unit=$3
# one row per call
format_row "$name" "$count" "$unit"
EOF
    cat > "$1/tests/report.bats" <<'EOF'
#!/usr/bin/env bats
@test "report.sh prints one row with the unit" {
    run bin/report.sh apples 3 kg
    [ "$output" = "apples | 3 | kg" ]
}

@test "report.sh refuses a missing unit" {
    run bin/report.sh apples 3
    [ "$status" -eq 2 ]
}
EOF
    cat > "$1/tests/format.bats" <<'EOF'
#!/usr/bin/env bats
@test "format_row prints three columns" {
    . lib/format.sh
    run format_row a b c
    [ "$output" = "a | b | c" ]
}

@test "format_row refuses two arguments" {
    . lib/format.sh
    run format_row a b
    [ "$status" -eq 2 ]
}
EOF
    cat > "$1/lib/slug.sh" <<'EOF'
#!/usr/bin/env bash
# slug_make <title> — a file name for a report
. "$(dirname "${BASH_SOURCE[0]}")/args.sh"
slug_make() {
    _need_args 1 $# || return 2
    printf '%s\n' "$1" | tr 'A-Z ' 'a-z-'
}
EOF
    cat > "$1/tests/slug.bats" <<'EOF'
#!/usr/bin/env bats
@test "slug_make lowercases and dashes a title" {
    . lib/slug.sh
    run slug_make "Monthly Report"
    [ "$output" = "monthly-report" ]
}
EOF
    vs__git "$1" "report rows gain a unit column; slug_make"
}
