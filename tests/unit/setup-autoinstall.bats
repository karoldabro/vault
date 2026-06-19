#!/usr/bin/env bats
# Tests for the setup.sh auto-install execute path, exercised OFFLINE via the
# run()/dry-run seam (VAULT_SETUP_DRY_RUN=1). No network, no sudo, no real apt —
# we assert on the dry-run transcript and on lib/installers.sh functions directly.

load "../helpers/setup.bash"

setup() {
    make_test_home
    export VAULT_HOME="${TEST_HOME}/vault"
    export CLAUDE_HOME="${TEST_HOME}/.claude"
    export SETUP_SKIP_INSTALL_SH=1
    # A fake-bin dir we can stuff stubs into and prepend to PATH.
    FAKEBIN="${TEST_HOME}/fakebin"
    mkdir -p "${FAKEBIN}"
}

teardown() { cleanup_test_home; }

# Write an executable stub named $1 in FAKEBIN with body $2.
stub() {
    local name="$1" body="$2"
    printf '#!/usr/bin/env bash\n%s\n' "${body}" > "${FAKEBIN}/${name}"
    chmod +x "${FAKEBIN}/${name}"
}

# A claude stub that reports an empty install state (so install commands fire).
stub_claude_empty() {
    stub claude '
case "$1 $2" in
  "plugin --help") exit 0 ;;
esac
# plugin list / marketplace list / mcp list → empty
exit 0'
}

run_setup() { run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/setup.sh" "$@"; }

#------------------------------------------------------------------------------
# Transcript + ordering
#------------------------------------------------------------------------------
@test "dry-run --full emits every tool's canonical install command" {
    stub_claude_empty
    run_setup --full --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"curl -fsSL https://ollama.com/install.sh | sh"* ]]
    [[ "$output" == *"ollama pull nomic-embed-text"* ]]
    [[ "$output" == *"curl -LsSf https://astral.sh/uv/install.sh | sh"* ]]
    [[ "$output" == *"uv tool install -p 3.13 serena-agent"* ]]
    [[ "$output" == *"curl -fsSL https://bun.com/install | bash"* ]]
    [[ "$output" == *"pipx install graphifyy"* ]]
    [[ "$output" == *"pipx install openviking"* ]]
    [[ "$output" == *"systemctl --user enable --now openviking.service"* ]]
    [[ "$output" == *"claude plugin marketplace add Castor6/openviking-plugins"* ]]
    [[ "$output" == *"claude plugin install claude-code-memory-plugin@openviking-plugin"* ]]
    [[ "$output" == *"claude plugin marketplace add thedotmack/claude-mem"* ]]
}

@test "pipx installs pin a Python interpreter (--python)" {
    stub_claude_empty
    run_setup --full --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"pipx install openviking --python"* ]]
    [[ "$output" == *"pipx install graphifyy --python"* ]]
}

@test "pick_python picks a >=3.10 interpreter and rejects <3.10" {
    # Stub every candidate as an old 3.8 first → none qualifies.
    for c in python3.13 python3.12 python3.11 python3.10 python3 python; do
        printf '#!/usr/bin/env bash\necho 3.8.10\n' > "${FAKEBIN}/${c}"; chmod +x "${FAKEBIN}/${c}"
    done
    ( set -euo pipefail; PATH="${FAKEBIN}:${PATH}"
      . "${VAULT_ROOT}/lib/installers.sh"
      if pick_python >/dev/null; then echo "old=picked-BAD"; else echo "old=rejected"; fi
      printf '#!/usr/bin/env bash\necho 3.12\n' > "${FAKEBIN}/python3.12"; chmod +x "${FAKEBIN}/python3.12"
      echo "new=$(pick_python)" ) > "${TEST_HOME}/out" 2>&1
    grep -q 'old=rejected' "${TEST_HOME}/out"
    grep -q 'new=python3.12' "${TEST_HOME}/out"
}

@test "dry-run prints each install via the [dry-run] marker (nothing really executed)" {
    stub_claude_empty
    run_setup --full --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "dry-run uses corrected commands, not the old wrong ones" {
    stub_claude_empty
    run_setup --full --dry-run
    [ "$status" -eq 0 ]
    # Morph was dropped entirely.
    [[ "$output" != *"morph"* ]]
    [[ "$output" != *"razorback16"* ]]
    # Old wrong serena flag / plugin name must be gone.
    [[ "$output" != *"serena-agent@latest"* ]]
    [[ "$output" != *"plugin install openviking"* ]]
}

#------------------------------------------------------------------------------
# Security: secret redaction + sudo scoping
#------------------------------------------------------------------------------
@test "run() redacts KEY/TOKEN/SECRET values in the dry-run transcript" {
    # shellcheck disable=SC1090
    ( set -euo pipefail
      VAULT_SETUP_DRY_RUN=1
      . "${VAULT_ROOT}/lib/installers.sh"
      run some-cmd FOO_API_KEY=supersecret BAR_TOKEN=abc plain=keepme ) > "${TEST_HOME}/out"
    grep -q 'FOO_API_KEY=\*\*\*' "${TEST_HOME}/out"
    grep -q 'BAR_TOKEN=\*\*\*' "${TEST_HOME}/out"
    grep -q 'plain=keepme' "${TEST_HOME}/out"
    ! grep -q 'supersecret' "${TEST_HOME}/out"
}

@test "sudo is scoped to apt only — never prefixes curl/uv/bun/ollama/claude/pipx" {
    stub_claude_empty
    run_setup --full --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"sudo curl"* ]]
    [[ "$output" != *"sudo uv"* ]]
    [[ "$output" != *"sudo bun"* ]]
    [[ "$output" != *"sudo ollama"* ]]
    [[ "$output" != *"sudo claude"* ]]
    [[ "$output" != *"sudo pipx"* ]]
}

@test "remote installer source URLs are printed for an audit trail" {
    stub_claude_empty
    run_setup --with-ov --with-serena --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"source: https://ollama.com/install.sh"* ]]
    [[ "$output" == *"source: https://astral.sh/uv/install.sh"* ]]
}

#------------------------------------------------------------------------------
# Idempotency: already-present tools are skipped
#------------------------------------------------------------------------------
@test "tools already on PATH are reported present and not reinstalled" {
    stub ollama 'echo "nomic-embed-text"; exit 0'   # `ollama list` shows the model
    stub uv 'exit 0'
    stub bun 'exit 0'
    stub graphify 'exit 0'
    stub_claude_empty
    run_setup --with-ov --with-serena --with-graphify --with-claude-mem --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"ollama present"* ]]
    [[ "$output" == *"uv present"* ]]
    [[ "$output" == *"graphify present"* ]]
    # No install command should have been emitted for the present tools.
    [[ "$output" != *"https://ollama.com/install.sh"* ]]
    [[ "$output" != *"pipx install graphifyy"* ]]
}

@test "already-installed plugins are detected via claude plugin list (no re-add)" {
    stub claude '
case "$1 $2" in
  "plugin --help") exit 0 ;;
  "plugin list") echo "claude-code-memory-plugin@openviking-plugin"; echo "claude-mem@claude-mem"; exit 0 ;;
  "plugin marketplace") echo "openviking-plugin"; echo "claude-mem"; exit 0 ;;
esac
exit 0'
    run_setup --with-ov --with-claude-mem --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"already installed"* ]]
    [[ "$output" != *"plugin install claude-code-memory-plugin"* ]]
}

#------------------------------------------------------------------------------
# Graceful degradation
#------------------------------------------------------------------------------
@test "claude CLI absent → plugin steps degrade to manual hints, exit 0" {
    # No claude stub: the bare test image has no claude on PATH.
    run_setup --with-ov --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude CLI missing"* ]]
    [[ "$output" == *"claude plugin install claude-code-memory-plugin@openviking-plugin"* ]]
    # ollama is still attempted (not gated on claude).
    [[ "$output" == *"ollama.com/install.sh"* ]]
}

@test "non-apt host without dry-run degrades to install hints, exit 0" {
    # Real (non dry-run) run on the alpine image: no apt-get → hint path.
    run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/setup.sh" --full --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"install hints"* ]]
    [[ "$output" == *"curl -fsSL https://ollama.com/install.sh | sh"* ]]
}

@test "ov.conf is written even when the tool install degrades (and is 0600)" {
    run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/setup.sh" --with-ov --yes
    [ "$status" -eq 0 ]
    [ -f "${HOME}/.openviking/ov.conf" ]
    perms="$(stat -c '%a' "${HOME}/.openviking/ov.conf")"
    [ "${perms}" = "600" ]
}

#------------------------------------------------------------------------------
# Continue-on-error + doctor exit code (lib unit)
#------------------------------------------------------------------------------
@test "tool_try records a failed tool and keeps going; doctor flags it" {
    # shellcheck disable=SC1090
    ( set -euo pipefail
      VAULT_SETUP_DRY_RUN=1
      . "${VAULT_ROOT}/lib/installers.sh"
      install_boom() { return 1; }
      install_fine() { return 0; }
      tool_try boom install_boom
      tool_try fine install_fine
      printf 'OK=%s FAILED=%s\n' "${TOOLS_OK[*]}" "${TOOLS_FAILED[*]}"
      drc=0; doctor >/dev/null || drc=$?; echo "doctor_exit=${drc}" ) > "${TEST_HOME}/out" 2>&1
    grep -q 'OK=fine' "${TEST_HOME}/out"
    grep -q 'FAILED=boom' "${TEST_HOME}/out"
    grep -q 'doctor_exit=1' "${TEST_HOME}/out"
}

@test "doctor marks an absent tool ✗ and a present tool ✓" {
    stub uv 'exit 0'   # present
    # shellcheck disable=SC1090
    ( set -euo pipefail
      PATH="${FAKEBIN}:${PATH}"
      . "${VAULT_ROOT}/lib/installers.sh"
      drc=0; doctor || drc=$?; echo "exit=${drc}" ) > "${TEST_HOME}/out" 2>&1
    [[ "$(cat "${TEST_HOME}/out")" == *"Doctor — tool health"* ]]
    grep -q '✓] uv' "${TEST_HOME}/out"        # present tool → check
    grep -q '✗] ollama' "${TEST_HOME}/out"    # absent tool → cross
    grep -q 'exit=0' "${TEST_HOME}/out"       # no recorded install failures
}

#------------------------------------------------------------------------------
# Sudo footgun guard + sudo_available privilege model
#------------------------------------------------------------------------------
@test "running under sudo (SUDO_USER set) is refused with guidance, non-zero exit" {
    run env SUDO_USER=alice PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/setup.sh" --full --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"Do not run setup.sh with sudo"* ]]
    # It must bail before scaffolding anything.
    [[ "$output" != *"Machine layer"* ]]
}

@test "VAULT_ALLOW_SUDO=1 overrides the sudo guard and proceeds" {
    stub_claude_empty
    run env SUDO_USER=alice VAULT_ALLOW_SUDO=1 PATH="${FAKEBIN}:${PATH}" \
        "${VAULT_ROOT}/setup.sh" --full --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Machine layer"* ]]
    [[ "$output" != *"Do not run setup.sh with sudo"* ]]
}

@test "sudo_available is true as root and with passwordless sudo, false otherwise" {
    # Root branch: id -u == 0 short-circuits true regardless of sudo.
    stub id 'echo 0'
    ( set -euo pipefail; PATH="${FAKEBIN}:${PATH}"
      . "${VAULT_ROOT}/lib/installers.sh"
      sudo_available && echo "root=yes" ) > "${TEST_HOME}/out"
    grep -q 'root=yes' "${TEST_HOME}/out"

    # Non-root with a passwordless sudo stub (`sudo -n true` exits 0) → true.
    stub id 'echo 1000'
    stub sudo 'exit 0'
    ( set -euo pipefail; PATH="${FAKEBIN}:${PATH}"
      . "${VAULT_ROOT}/lib/installers.sh"
      sudo_available && echo "passwordless=yes" ) > "${TEST_HOME}/out"
    grep -q 'passwordless=yes' "${TEST_HOME}/out"

    # Non-root, sudo that always fails (`-n` denied), no TTY (bats stdin/stdout
    # are pipes) → false: cannot escalate, caller must degrade to hints.
    stub sudo 'exit 1'
    ( set -euo pipefail; PATH="${FAKEBIN}:${PATH}"
      . "${VAULT_ROOT}/lib/installers.sh"
      if sudo_available; then echo "noprompt=yes"; else echo "noprompt=no"; fi ) </dev/null >"${TEST_HOME}/out" 2>&1
    grep -q 'noprompt=no' "${TEST_HOME}/out"
}

#------------------------------------------------------------------------------
# Flag surface
#------------------------------------------------------------------------------
@test "--doctor runs only the health check and exits 0 on a clean tree" {
    run_setup --doctor
    [ "$status" -eq 0 ]
    [[ "$output" == *"Doctor — tool health"* ]]
    # It must not scaffold or run install steps.
    [[ "$output" != *"Machine layer"* ]]
}

@test "--with-morph is now an unknown flag (Morph dropped cleanly)" {
    run_setup --with-morph
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown flag"* ]]
}

@test "--dry-run implies non-interactive (never blocks on a consent prompt)" {
    stub_claude_empty
    # No /dev/tty interaction should be needed; redirect stdin from /dev/null.
    run env PATH="${FAKEBIN}:${PATH}" "${VAULT_ROOT}/setup.sh" --full --dry-run </dev/null
    [ "$status" -eq 0 ]
}
