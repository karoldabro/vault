.PHONY: test test-unit test-integration test-e2e shell

# Run the full suite inside Docker (reproducible across hosts + CI).
test:
	@./tests/run.sh tests/

test-unit:
	@./tests/run.sh tests/unit

test-integration:
	@./tests/run.sh tests/integration

test-e2e:
	@./tests/run.sh tests/e2e

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
