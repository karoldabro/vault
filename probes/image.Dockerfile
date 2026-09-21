# The probe image of `/v-cr --sandbox`. The operator builds it; the framework never builds or pulls one.
#   docker build -f probes/image.Dockerfile -t vault-probes:local probes
#   VCR_SANDBOX_MAP="probe-image=vault-probes:local"
# Contract: commands/v-cr/sandbox.md section S8. Add `claude` here only if you want the claude-validate row to run.
FROM python:3.12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends bash gawk grep sed coreutils findutils jq \
 && pip install --no-cache-dir lizard typos \
 && rm -rf /var/lib/apt/lists/*
