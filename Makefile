.PHONY: test test-unit test-integration test-e2e shell validate-plugin

# Offline suite (alpine, no network/sudo) — the default, PR-blocking path.
# e2e is excluded here on purpose: it needs real network + root (see test-e2e).
test:
	@./tests/run.sh tests/unit
	@./tests/run.sh tests/integration

test-unit:
	@./tests/run.sh tests/unit

test-integration:
	@./tests/run.sh tests/integration

# Claude Code's own manifest validator. Not part of `make test`: it needs the
# claude CLI on the host, which the offline Docker suite deliberately doesn't have.
# --strict turns unrecognized-field warnings into errors, which is what catches a
# typo'd manifest key before it ships silently ignored.
validate-plugin:
	@command -v claude >/dev/null 2>&1 \
		|| { echo "claude CLI not found — skipping plugin validation"; exit 0; }
	@claude plugin validate . --strict

# Real auto-install on a throwaway Ubuntu container. Opt-in + slow:
#   VAULT_E2E=1 make test-e2e
test-e2e:
	@./tests/e2e/run.sh

# Drop into an interactive shell in the test image for debugging.
shell:
	@docker build --quiet -t vault-tests:local tests/ >/dev/null
	@docker run --rm -it \
		--volume "$(PWD):/code:ro" \
		--workdir /code \
		--tmpfs /tmp:exec \
		--env HOME=/tmp/home \
		--entrypoint /bin/bash \
		vault-tests:local
