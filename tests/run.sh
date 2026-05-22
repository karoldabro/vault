#!/usr/bin/env bash
# Build the test image (if needed) and run the bats suite inside Docker.
# Repo is mounted read-only so tests cannot mutate the source tree.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE="vault-tests:local"

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker not found in PATH. Tests require Docker." >&2
    exit 2
fi

docker build --quiet -t "${IMAGE}" "${SCRIPT_DIR}" >/dev/null

# Subdir defaults to "tests/" inside the container; caller may pass e.g. "tests/unit".
target="${1:-tests/}"

exec docker run --rm \
    --volume "${REPO_ROOT}:/code:ro" \
    --workdir /code \
    --user "$(id -u):$(id -g)" \
    --tmpfs /tmp:exec \
    --env HOME=/tmp/home \
    "${IMAGE}" \
    --recursive "${target}"
