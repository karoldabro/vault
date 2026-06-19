---
type: indication
project: vault
slug: per-user-installer-no-sudo
scope: repo
tags: [indication]
---

# per-user-installer-no-sudo

## Rule
The installer runs **as the normal user** and escalates internally only for the steps that need it
(apt, ollama's systemd). Never run the whole installer under `sudo`. Accept interactive sudo (prompt
for the password at the escalation point); require passwordless sudo only for non-interactive runs.

## Rationale
Wrapping a per-user installer in `sudo` flips `$HOME` to `/root`: user-scoped artifacts
(uv/bun/pipx bins, `~/.openviking/ov.conf`, `claude` plugins) land in root's home, invisible to the
user, and the user's `claude` CLI drops off PATH so programmatic plugin install silently degrades.
Gating the auto path on *passwordless* sudo instead strands the common workstation user with
hint-only output. Distinguish a human `sudo` invocation (`$SUDO_USER` set → refuse) from genuine
container/CI root (`$SUDO_USER` unset → allow) so the e2e/root path keeps working.

## Examples
- Do: `./setup.sh --full --yes` as yourself → `_priv()` prepends `sudo` only for apt; `sudo -v`
  pre-warm asks for the password once.
- Do: `sudo_available()` returns true for root, passwordless sudo, **or** an attached TTY.
- Don't: `sudo ./setup.sh` — refused with guidance (override `VAULT_ALLOW_SUDO=1`).
- Don't: gate the whole auto path on `sudo -n true` (passwordless-only).

## Applies-to
`setup.sh`, `lib/installers.sh`, `bin/*.sh`
