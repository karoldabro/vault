#!/usr/bin/env bash
# Fixture `check` point for tests/unit/vault-check.bats.
# Prints $CHECK_FIXTURE_LINES (escapes such as \t expanded), records its arguments and the changed-file
# list when asked, and exits with $CHECK_FIXTURE_EXIT.
[ -z "${CHECK_FIXTURE_ARGS:-}" ] || printf '%s\n' "$@" > "$CHECK_FIXTURE_ARGS"
[ -z "${CHECK_FIXTURE_FILES:-}" ] || tr '\0' '\n' < "$VAULT_CHECK_FILES" > "$CHECK_FIXTURE_FILES"
[ -z "${CHECK_FIXTURE_SLEEP:-}" ] || sleep "$CHECK_FIXTURE_SLEEP"
[ -z "${CHECK_FIXTURE_LINES:-}" ] || printf '%b\n' "$CHECK_FIXTURE_LINES"
exit "${CHECK_FIXTURE_EXIT:-0}"
