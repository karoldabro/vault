#!/usr/bin/env bash
# vault-init — bootstrap a project vault for the code repo at $PWD.
#
# What it does:
#   1. Resolve slug (arg or PWD basename).
#   2. Refuse if $VAULT_HOME/$slug already exists.
#   3. Create vault repo at $VAULT_HOME/$slug, git init.
#   4. Attach framework as `_process/` submodule (URL configurable).
#   5. Scaffold folders + index files + .gitignore + _moc.md.
#   6. Append entry to $VAULT_HOME/_global/coupled-groups.md.
#   7. Append memory-stack snippet to <code-repo>/CLAUDE.md (idempotent).
#   8. Install graphify post-commit hook + build initial graph in the code repo (if graphify present).
#   9. Initial commit.
#
# Environment overrides:
#   VAULT_HOME              default: $HOME/vault
#   VAULT_FRAMEWORK_URL     default: git@github.com:karoldabro/vault.git
#                           For local testing: file:///path/to/framework or /path
#   VAULT_INIT_GIT_FLAGS    extra git flags (tests use: -c protocol.file.allow=always)
#
# Flags:
#   --slug NAME             override derived slug
#   --framework-url URL     override VAULT_FRAMEWORK_URL
#   --no-submodule          skip submodule add (useful for fully-offline init)
#   --no-claude-md          do not touch <code-repo>/CLAUDE.md
#   --no-graphify           skip graphify hook install + initial graph build
#   --yes                   non-interactive (currently informational)
#   -h, --help              show usage

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_HOME="${VAULT_HOME:-${HOME}/vault}"
VAULT_FRAMEWORK_URL="${VAULT_FRAMEWORK_URL:-git@github.com:karoldabro/vault.git}"
VAULT_INIT_GIT_FLAGS="${VAULT_INIT_GIT_FLAGS:-}"

slug=""
no_submodule=0
no_claude_md=0
no_graphify=0

usage() {
    sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --slug)            slug="$2"; shift 2 ;;
        --framework-url)   VAULT_FRAMEWORK_URL="$2"; shift 2 ;;
        --no-submodule)    no_submodule=1; shift ;;
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

vault_dir="${VAULT_HOME}/${slug}"

if [ -e "${vault_dir}" ]; then
    echo "ERROR: ${vault_dir} already exists. Refusing to overwrite." >&2
    echo "       Pick a different --slug or remove the existing vault." >&2
    exit 1
fi

echo "Initializing vault for: ${code_repo}"
echo "  slug:          ${slug}"
echo "  vault dir:     ${vault_dir}"
echo "  framework URL: ${VAULT_FRAMEWORK_URL}"

#------------------------------------------------------------------------------
# Create vault repo
#------------------------------------------------------------------------------
mkdir -p "${vault_dir}"
# shellcheck disable=SC2086
git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" init --quiet --initial-branch=main 2>/dev/null \
    || git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" init --quiet

#------------------------------------------------------------------------------
# Submodule
#------------------------------------------------------------------------------
if [ "${no_submodule}" -eq 0 ]; then
    # shellcheck disable=SC2086
    git ${VAULT_INIT_GIT_FLAGS} -C "${vault_dir}" submodule add --quiet \
        "${VAULT_FRAMEWORK_URL}" _process
fi

#------------------------------------------------------------------------------
# Scaffold folders + placeholders
#------------------------------------------------------------------------------
for sub in sessions decisions features processes architecture; do
    mkdir -p "${vault_dir}/${sub}"
    # .gitkeep so empty dirs survive initial commit
    : > "${vault_dir}/${sub}/.gitkeep"
done

# .gitignore from template
cp "${VAULT_ROOT}/templates/vault.gitignore" "${vault_dir}/.gitignore"

# _moc.md from template (substitute project name)
sed "s/{{project}}/${slug}/g" "${VAULT_ROOT}/templates/project-moc.md" \
    > "${vault_dir}/_moc.md"

# Add a Start Here pointer to the framework guide.
cat >> "${vault_dir}/_moc.md" <<EOF

## Start Here
- [[_process/vault-guide]] — process documentation (framework submodule)
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
# CLAUDE.md snippet in code repo
#------------------------------------------------------------------------------
if [ "${no_claude_md}" -eq 0 ]; then
    claude_md="${code_repo}/CLAUDE.md"
    marker="Vault memory stack"
    if [ -f "${claude_md}" ] && grep -q "${marker}" "${claude_md}"; then
        :
    else
        cat >> "${claude_md}" <<EOF

## ${marker}

This project is wired into the vault knowledge framework.

- Per-project vault: \`${vault_dir}\`
- Process docs: \`${vault_dir}/_process/vault-guide.md\`
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
# Initial commit
#------------------------------------------------------------------------------
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

echo ""
echo "Vault initialized at ${vault_dir}"
echo "Next:"
echo "  - Push the vault repo to a remote of your choice (gh repo create / git remote add)."
echo "  - Run /v-work in this code repo to start a vault-aware session."
