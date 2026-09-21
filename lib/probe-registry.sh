#!/usr/bin/env bash
# probe-registry.sh — reads, validates and merges probe registries, and finds each row's tool.
# Sourced by bin/probe.sh. A registry row is nine tab separated fields; the reader prints ten, with the
# origin (`framework` or `repo`) first. Contract: commands/_shared/probe-kit.md.

[ -n "${PROBE_REGISTRY_LOADED:-}" ] && return 0
PROBE_REGISTRY_LOADED=1

# Prints the rows of one registry file with <origin> in front, or a message and exit 1 on the first bad line.
probe_read_registry() {
    local file=$1 origin=$2
    LC_ALL=C awk -F'\t' -v origin="$origin" -v file="$file" '
        function bad(msg) { printf "probe: %s:%d: %s\n", file, NR, msg > "/dev/stderr"; failed = 1; exit 1 }
        /^[ \t]*(#|$)/ { next }
        NF != 9 { bad("expected 9 tab separated fields, found " NF) }
        $1 !~ /^[a-z0-9-]+$/ { bad("id must match [a-z0-9-]+") }
        $2 !~ /^[a-z0-9-]+$/ { bad("stack must match [a-z0-9-]+") }
        $3 !~ /^(plan|diff|review)$/ { bad("stage must be plan, diff or review") }
        $4 == "" || $5 == "" || $6 == "" || $9 == "" { bad("detect, run, parser and install must not be empty") }
        $7 !~ /^[SML]$/ { bad("cost must be S, M or L") }
        $8 !~ /^(yes|no)$/ { bad("executes-repo-code must be yes or no") }
        { print origin "\t" $0 }
        END { exit failed }
    ' "$file"
}

# probe_registry <repo> <allow_repo:0|1> — every row, framework rows first. Exit 2 on a bad line or a
# repeated id+stage. The repo's registry is read only when asked and only when it is a plain file, and a repo
# registry that is the same file as the framework's is read once, as framework origin.
probe_registry() {
    local repo=$1 allow=$2 fw="$PROBE_FRAMEWORK/probes/registry.tsv" rows
    [ -r "$fw" ] || probe_die "the framework registry is missing: $fw"
    rows=$(probe_read_registry "$fw" framework) || exit 2
    if [ "$allow" = 1 ] && probe_safe_file "$repo" probes/registry.tsv && ! [ "$repo/probes/registry.tsv" -ef "$fw" ]; then
        rows="$rows"$'\n'$(probe_read_registry "$repo/probes/registry.tsv" repo) || exit 2
    fi
    [ -n "$rows" ] || return 0
    printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '
        { key = $2 "\t" $4 }
        key in seen { printf "probe: the id %s is registered twice for stage %s\n", $2, $4 > "/dev/stderr"; bad = 1; exit 1 }
        { seen[key] = 1; print }
        END { exit bad }
    ' || exit 2
}

# probe_path <trust> <repo> — the PATH a cell runs with. Repo tool directories are appended, never
# prepended, and only for a row that runs repo code.
probe_path() {
    if [ "$1" = yes ]; then
        printf '%s' "$PATH:$2/node_modules/.bin:$2/vendor/bin:$2/.venv/bin:$2/.venv-probes/bin"
    else
        printf '%s' "$PATH"
    fi
}

# probe_tool_present <run cell> <trust> <repo> — 0 when the row's tool can run. The tool is the first word
# of the run cell. A cell that starts with "$PROBE_FRAMEWORK/ names a framework file. Nothing is evaluated.
probe_tool_present() {
    local run=$1 trust=$2 repo=$3 rest word
    if [[ $run == '"$PROBE_FRAMEWORK/'* ]]; then
        rest=${run#'"$PROBE_FRAMEWORK/'}
        [ -x "$PROBE_FRAMEWORK/${rest%%\"*}" ]
        return
    fi
    word=${run%% *}
    PATH=$(probe_path "$trust" "$repo") command -v -- "$word" >/dev/null 2>&1
}
