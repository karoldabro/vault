#!/usr/bin/env bash
# vault-init — bootstrap a project vault for the code repo at $PWD.
#
# The framework is a single global install (read from $VAULT_FRAMEWORK_PATH). It is NOT vendored
# into the vault as a submodule. The vault lives either globally ($VAULT_HOME/$slug) or inside the
# code repo (--in-repo → <code-repo>/vault); a VAULT.md at the repo root records the choice so every
# vault command resolves the same location.
#
# What it does:
#   1. Resolve slug (arg or PWD basename) + vault path (global or --in-repo).
#   2. Refuse if the vault dir already exists.
#   3. Create vault repo, git init.
#   4. Scaffold folders + index files + .gitignore + _moc.md (incl. indications/).
#   5. Write <code-repo>/VAULT.md (vault_path + slug) if absent.
#   6. Append entry to $VAULT_HOME/_global/coupled-groups.md.
#   7. Append memory-stack snippet to <code-repo>/CLAUDE.md (idempotent).
#   8. Install graphify post-commit hook + build initial graph in the code repo (if graphify present).
#   9. Initial commit.
#
# Environment overrides:
#   VAULT_HOME              default: $HOME/vault
#   VAULT_FRAMEWORK_PATH    default: this framework install (parent of bin/)
#   VAULT_INIT_GIT_FLAGS    extra git flags (tests use: -c protocol.file.allow=always)
#
# Flags:
#   --slug NAME             override derived slug
#   --in-repo               keep the vault inside the code repo at <code-repo>/vault
#   --framework-path PATH   override VAULT_FRAMEWORK_PATH
#   --no-vault-md           do not write <code-repo>/VAULT.md
#   --no-claude-md          do not touch <code-repo>/CLAUDE.md
#   --no-graphify           skip graphify hook install + initial graph build
#   --yes                   non-interactive (currently informational)
#   -h, --help              show usage

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_HOME="${VAULT_HOME:-${HOME}/vault}"
VAULT_FRAMEWORK_PATH="${VAULT_FRAMEWORK_PATH:-${VAULT_ROOT}}"
VAULT_INIT_GIT_FLAGS="${VAULT_INIT_GIT_FLAGS:-}"

slug=""
in_repo=0
no_vault_md=0
no_claude_md=0
no_graphify=0

usage() {
    sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --slug)            slug="$2"; shift 2 ;;
        --in-repo)         in_repo=1; shift ;;
        --framework-path)  VAULT_FRAMEWORK_PATH="$2"; shift 2 ;;
        --no-vault-md)     no_vault_md=1; shift ;;
        --no-claude-md)    no_claude_md=1; shift ;;
        --no-graphify)     no_graphify=1; shift ;;
        --yes|-y)          shift ;;
        -h|--help)         usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
    esac
done

#------------------------------------------------------------------------------
# Resolve code repo + slug
#------------------------------------------------------------------------------
code_repo="$(pwd)"
if ! git -C "${code_repo}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: $(pwd) is not a git repo. vault-init operates on a code repo." >&2
    echo "       (Mode B — empty-vault bootstrap — is not yet implemented.)" >&2
    exit 1
fi
code_repo="$(git -C "${code_repo}" rev-parse --show-toplevel)"

if [ -z "${slug}" ]; then
    slug="$(basename "${code_repo}")"
fi

# Resolve vault dir + the vault_path value recorded in VAULT.md.
if [ "${in_repo}" -eq 1 ]; then
    vault_dir="${code_repo}/vault"
    vault_path_value="./vault"
else
    vault_dir="${VAULT_HOME}/${slug}"
    # Record with a leading ~ when under $HOME so VAULT.md stays portable.
    vault_path_value="${vault_dir/#${HOME}/\~}"
fi

if [ -e "${vault_dir}" ]; then
    echo "ERROR: ${vault_dir} already exists. Refusing to overwrite." >&2
    echo "       Pick a different --slug or remove the existing vault." >&2
    exit 1
fi

echo "Initializing vault for: ${code_repo}"
echo "  slug:           ${slug}"
echo "  vault dir:      ${vault_dir}"
echo "  framework path: ${VAULT_FRAMEWORK_PATH}"

#------------------------------------------------------------------------------
# Create vault repo
#------------------------------------------------------------------------------
# Global vaults are their own git repo. In-repo vaults are tracked by the code
# repo itself — no nested git repo (which git would treat as an embedded repo).
mkdir -p "${vault_dir}"
if [ "${in_repo}" -eq 0 ]; then
    # shellcheck disable=SC2086
    git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" init --quiet --initial-branch=main 2>/dev/null \
        || git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" init --quiet
fi

#------------------------------------------------------------------------------
# Scaffold folders + placeholders
#------------------------------------------------------------------------------
for sub in sessions decisions features indications processes architecture; do
    mkdir -p "${vault_dir}/${sub}"
    # .gitkeep so empty dirs survive initial commit
    : > "${vault_dir}/${sub}/.gitkeep"
done

# .gitignore from template
cp "${VAULT_ROOT}/templates/vault.gitignore" "${vault_dir}/.gitignore"

# _moc.md from template (substitute project name)
sed "s/{{project}}/${slug}/g" "${VAULT_ROOT}/templates/project-moc.md" \
    > "${vault_dir}/_moc.md"

# Add a Start Here pointer to the framework guide (global install, not vendored here).
# Use the literal $VAULT_FRAMEWORK_PATH reference (not the resolved path) so a committed
# vault stays portable — each user resolves it from their env / ~/vault/_global/config.md.
cat >> "${vault_dir}/_moc.md" <<EOF

## Start Here
- Process docs: \`\$VAULT_FRAMEWORK_PATH/vault-guide.md\` (global framework install)
EOF

# Feature index stub
cat > "${vault_dir}/_feature-index.md" <<EOF
---
type: index
project: ${slug}
tags: [index]
---

# ${slug} — Feature index

| Feature | Status | Last touched | Notes |
|---------|--------|--------------|-------|
EOF

# Decisions inventory stub
cat > "${vault_dir}/decisions/_inventory.md" <<EOF
---
type: index
project: ${slug}
tags: [index, decisions]
---

# ${slug} — Decisions inventory

| ID | Title | Date | Status |
|----|-------|------|--------|
EOF

# Indications index stub
cat > "${vault_dir}/indications/_index.md" <<EOF
---
type: index
project: ${slug}
tags: [index, indications]
---

# ${slug} — Indications (working rules, patterns, standards)

| Slug | Rule | Applies-to |
|------|------|------------|
EOF

#------------------------------------------------------------------------------
# coupled-groups.md entry
#------------------------------------------------------------------------------
mkdir -p "${VAULT_HOME}/_global"
coupled="${VAULT_HOME}/_global/coupled-groups.md"
if [ ! -f "${coupled}" ]; then
    cat > "${coupled}" <<'EOF'
# Coupled project groups

Projects listed in the same group share memory recall.

EOF
fi
if ! grep -qE "^- ${slug}$" "${coupled}" 2>/dev/null; then
    {
        echo ""
        echo "## ${slug}"
        echo "- ${slug}"
    } >> "${coupled}"
fi

#------------------------------------------------------------------------------
# VAULT.md in code repo (records where the vault lives + per-repo config)
#------------------------------------------------------------------------------
if [ "${no_vault_md}" -eq 0 ]; then
    vault_md="${code_repo}/VAULT.md"
    if [ -f "${vault_md}" ]; then
        echo "  VAULT.md already present — leaving it untouched."
    else
        sed -e "s|{{slug}}|${slug}|g" \
            -e "s|^vault_path: ./vault|vault_path: ${vault_path_value}|" \
            "${VAULT_ROOT}/templates/VAULT.md" > "${vault_md}"
    fi
fi

#------------------------------------------------------------------------------
# CLAUDE.md snippet in code repo
#------------------------------------------------------------------------------
if [ "${no_claude_md}" -eq 0 ]; then
    claude_md="${code_repo}/CLAUDE.md"
    marker="Vault memory stack"
    if [ -f "${claude_md}" ] && grep -q "${marker}" "${claude_md}"; then
        :
    else
        # $VAULT_FRAMEWORK_PATH is written literally (resolved per-user from the env /
        # ~/vault/_global/config.md), so this committed file is portable across machines.
        cat >> "${claude_md}" <<EOF

## ${marker}

This project is wired into the vault knowledge framework.

- Per-project vault: \`${vault_dir}\` (also recorded in \`VAULT.md\`)
- Process docs: \`\$VAULT_FRAMEWORK_PATH/vault-guide.md\` (global framework install)
- Map of contents: \`${vault_dir}/_moc.md\`

Use \`/v-work\` for development, \`/v-capture\` to save the session.
EOF
    fi
fi

#------------------------------------------------------------------------------
# Graphify — install post-commit hook + build initial graph in the CODE repo
#------------------------------------------------------------------------------
# The graph lives in the code repo (graphify-out/), kept fresh by the hook so
# /v-work can query it instead of grepping. The hook is AST-based (no LLM, no
# token cost) and rebuilds the graph on every commit. The one-time full build
# (`graphify .`) is left to the user — it can run a deeper extraction, so we do
# not trigger it automatically (especially under --yes). Non-fatal throughout.
if [ "${no_graphify}" -eq 0 ]; then
    if command -v graphify >/dev/null 2>&1; then
        echo "Installing graphify post-commit hook in ${code_repo}..."
        ( cd "${code_repo}" && graphify hook install ) || \
            echo "  (graphify hook install failed — run it manually later)"
        echo "  Build the initial graph once with: (cd ${code_repo} && graphify .)"
        echo "  After that the hook keeps graph.json fresh on every commit (free, AST-based)."
    else
        echo "graphify not found — skipping graph hook."
        echo "  Install it, then run 'graphify hook install' + 'graphify .' in ${code_repo}"
        echo "  so /v-work can answer structural questions from graph.json instead of grep."
    fi
fi

#------------------------------------------------------------------------------
# Initial commit (global vaults only — in-repo vaults commit via the code repo)
#------------------------------------------------------------------------------
if [ "${in_repo}" -eq 0 ]; then
    # shellcheck disable=SC2086
    git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" add -A
    # Configure committer identity if absent (tests run with no global config).
    if ! git -C "${vault_dir}" config user.email >/dev/null 2>&1; then
        git -C "${vault_dir}" config user.email "vault-init@localhost"
        git -C "${vault_dir}" config user.name  "vault-init"
    fi
    # shellcheck disable=SC2086
    git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" commit --quiet \
        -m "chore(vault): initialize project vault for ${slug}"
fi

echo ""
echo "Vault initialized at ${vault_dir}"
echo "Next:"
if [ "${in_repo}" -eq 1 ]; then
    echo "  - The vault lives inside this repo (vault/) — commit it with your code."
else
    echo "  - Push the vault repo to a remote of your choice (gh repo create / git remote add)."
fi
echo "  - Run /v-work in this code repo to start a vault-aware session."
