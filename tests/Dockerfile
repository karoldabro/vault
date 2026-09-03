FROM bats/bats:1.11.0

# bats image is alpine + bats. Add the bits our tests need.
RUN apk add --no-cache \
    bash \
    git \
    grep \
    findutils \
    zsh \
    coreutils \
    curl \
    jq \
    python3

WORKDIR /code

# bats image entrypoint already runs `bats`. Default CMD points at our tree.
CMD ["--recursive", "tests/"]
