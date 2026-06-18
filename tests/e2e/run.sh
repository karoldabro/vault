#!/usr/bin/env bash
# e2e runner: builds an Ubuntu image and runs setup.sh's REAL auto-install path
# against the network inside a throwaway container. Opt-in only.
#
# Unlike tests/run.sh (offline alpine, :ro, non-root), this runs as root with
# outbound network so apt / curl|sh / pipx actually execute. The repo is still
# mounted read-only — setup.sh writes only under $HOME, which is the writable
# container-local /root.
#
# COVERAGE NOTE: this suite exercises the lightweight real installers (uv via
# curl|sh, graphify via pipx). The ollama daemon path (ensure_ollama_running +
# model pull) and the `claude` plugin/marketplace paths are deliberately NOT
# e2e-covered here — they are heavy/network-bound and the image ships no `claude`
# CLI. Those paths are covered at the command-construction level by the offline
# dry-run suite (tests/unit/setup-autoinstall.bats), not proven end-to-end.
set -euo pipefail

if [ "${VAULT_E2E:-0}" != "1" ]; then
    cat >&2 <<'EOF'
e2e is disabled. It runs REAL network installs (apt, curl|sh, pipx) on a
throwaway Ubuntu container and is slow. To run it:

    VAULT_E2E=1 make test-e2e
EOF
    exit 3
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker not found in PATH. e2e requires Docker." >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IMAGE="vault-e2e:ubuntu"

docker build --quiet -t "${IMAGE}" -f "${SCRIPT_DIR}/Dockerfile.ubuntu" "${SCRIPT_DIR}" >/dev/null

target="${1:-tests/e2e}"

exec docker run --rm \
    --volume "${REPO_ROOT}:/code:ro" \
    --workdir /code \
    --env HOME=/root \
    "${IMAGE}" \
    --recursive "${target}"
