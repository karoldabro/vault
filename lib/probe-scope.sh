#!/usr/bin/env bash
# probe-scope.sh — which files a probe may read, which files changed, and how big the repo is.
# Sourced by bin/probe.sh and the native probes. The repo under review is not trusted, so every git call
# drops the global and system configuration, switches off the repo's fsmonitor, hooks, attributes file,
# lazy fetch and network protocols, and replaces every filter command the repo's config defines.
# Contract: commands/_shared/probe-kit.md.

[ -n "${PROBE_SCOPE_LOADED:-}" ] && return 0
PROBE_SCOPE_LOADED=1
PROBE_GIT_FOR="" PROBE_GIT_ENV=()

# probe_git_prepare <repo> — lists the filter drivers of the repo's config (a read, nothing runs) and keeps
# an override for each, so that no `filter.<name>.clean` command of the repo can run during a comparison.
# The overrides travel in GIT_CONFIG_COUNT, GIT_CONFIG_KEY_n and GIT_CONFIG_VALUE_n, because a `-c key=value`
# argument is split at the first `=` and a filter name may contain one.
probe_git_prepare() {
    local repo=$1 key val n=0
    local -a env=()
    [ "$PROBE_GIT_FOR" = "$repo" ] && return 0
    PROBE_GIT_FOR=$repo
    while IFS= read -r key; do
        case $key in
            filter.*.clean|filter.*.smudge) val=cat ;;
            filter.*.process) val="" ;;
            filter.*.required) val=false ;;
            *) continue ;;
        esac
        env+=("GIT_CONFIG_KEY_$n=$key" "GIT_CONFIG_VALUE_$n=$val"); n=$((n + 1))
    done < <(GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 "${PROBE_GIT_BIN:-git}" -C "$repo" \
                 config --includes --name-only --get-regexp '^filter\.' 2>/dev/null)
    PROBE_GIT_ENV=("GIT_CONFIG_COUNT=$n" "${env[@]}")
}

# probe_git <repo> <git args…>
probe_git() {
    local repo=$1; shift
    probe_git_prepare "$repo"
    env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_OPTIONAL_LOCKS=0 GIT_NO_LAZY_FETCH=1 \
        GIT_ALLOW_PROTOCOL=none GIT_TERMINAL_PROMPT=0 "${PROBE_GIT_ENV[@]}" \
        "${PROBE_GIT_BIN:-git}" -C "$repo" -c core.fsmonitor=false -c core.hooksPath=/dev/null \
        -c core.attributesFile=/dev/null -c protocol.allow=never -c core.pager=cat "$@"
}

probe_in_git() { probe_git "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# probe_safe_file <repo> <relative path> — 0 when the path is a regular file that is not a link and whose
# directory really lies inside the repo.
probe_safe_file() {
    local repo=$1 rel=$2 root dir real
    [ -f "$repo/$rel" ] && [ ! -L "$repo/$rel" ] || return 1
    root=$(cd "$repo" && pwd -P) || return 1
    dir=${rel%/*}; [ "$dir" = "$rel" ] && dir=.
    real=$(cd "$repo/$dir" 2>/dev/null && pwd -P) || return 1
    case $real in "$root"|"$root"/*) return 0 ;; esac
    return 1
}

# Reads a NUL list on stdin and writes the names a probe may read: regular files, no symlink in the path,
# no control byte in the name, no path that leaves the repo. It writes the number of names with a control
# byte to $2.
probe_filter_list() {
    local repo=$1 countf=$2 f dir real root skipped=0
    local -A okdir=()
    root=$(cd "$repo" && pwd -P)
    while IFS= read -r -d '' f; do
        f=${f#./}
        case $f in *[[:cntrl:]]*) skipped=$((skipped + 1)); continue ;; esac
        case $f in ''|/*|..|../*|*/../*|*/..) continue ;; esac
        [ -f "$repo/$f" ] && [ ! -L "$repo/$f" ] || continue
        dir=${f%/*}; [ "$dir" = "$f" ] && dir=.
        if [ -z "${okdir["$dir"]+x}" ]; then
            real=$(cd "$repo/$dir" 2>/dev/null && pwd -P) || real=""
            case $real in "$root"|"$root"/*) okdir["$dir"]=1 ;; *) okdir["$dir"]=0 ;; esac
        fi
        [ "${okdir["$dir"]}" = 1 ] || continue
        printf '%s\0' "$f"
    done
    printf '%s' "$skipped" > "$countf"
}

# probe_files <repo> <outfile> — every file a probe may read, sorted, as a NUL list. The number of names
# skipped for a control byte is left in <outfile>.skipped. Returns 2 when the repo has a .git that git cannot read.
probe_files() {
    local repo=$1 out=$2 mode=find
    if probe_in_git "$repo"; then mode=git
    elif [ -e "$repo/.git" ]; then echo "probe: git cannot read the repository in $repo" >&2; return 2; fi
    if [ "$mode" = git ]; then
        probe_git "$repo" ls-files -z --cached --others --exclude-standard 2>/dev/null
    else
        (cd "$repo" && find . \( -name .git -o -name node_modules -o -name vendor \) -prune -o -type f -print0 2>/dev/null)
    fi | probe_filter_list "$repo" "$out.skipped" | LC_ALL=C sort -z > "$out"
}

# probe_changed <repo> <base> <outfile> — files under <repo> changed since <base>, plus untracked files, as
# a sorted NUL list. Returns 2 with a message when the repo is not a git repo, the base is not a commit,
# or git fails.
probe_changed() {
    local repo=$1 base=$2 out=$3
    probe_in_git "$repo" || { echo "probe: diff needs a git repository: $repo" >&2; return 2; }
    case $base in -*) echo "probe: --base must not start with a dash" >&2; return 2 ;; esac
    probe_git "$repo" rev-parse --verify --quiet --end-of-options "$base^{commit}" >/dev/null 2>&1 \
        || { echo "probe: --base is not a commit in this git repository: $base" >&2; return 2; }
    (
        probe_git "$repo" diff --name-only -z --relative --no-ext-diff --no-textconv --diff-filter=d "$base" -- || exit 1
        probe_git "$repo" ls-files -z --others --exclude-standard || exit 1
    ) > "$out.raw" 2> "$out.err" || {
        echo "probe: git could not list the changed files: $(head -c 200 "$out.err" | LC_ALL=C tr '\000-\037\177' ' ')" >&2
        return 2
    }
    probe_filter_list "$repo" "$out.skipped" < "$out.raw" | LC_ALL=C sort -z > "$out"
}

# probe_normalize <relative path> — prints the path with . and .. resolved; returns 1 when it leaves the root.
probe_normalize() {
    local -a parts out=()
    local part
    IFS=/ read -ra parts <<< "$1"
    for part in "${parts[@]}"; do
        case $part in
            ''|.) ;;
            ..) [ "${#out[@]}" -gt 0 ] || return 1; unset "out[${#out[@]}-1]" ;;
            *) out+=("$part") ;;
        esac
    done
    (IFS=/; printf '%s' "${out[*]}")
}

# probe_scale <repo> <listfile> — prints files, lines and max-cost as tab separated lines.
probe_scale() {
    local list=$2 files lines maxc
    files=$(tr -cd '\0' < "$list" | wc -c | tr -d ' ')
    lines=$(cd "$1" && xargs -0 -r cat < "$list" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$files" -le "${PROBE_SCALE_L:-2000}" ]; then maxc=L
    elif [ "$files" -le "${PROBE_SCALE_M:-10000}" ]; then maxc=M
    else maxc=S; fi
    printf 'files\t%s\nlines\t%s\nmax-cost\t%s\n' "$files" "$lines" "$maxc"
}
