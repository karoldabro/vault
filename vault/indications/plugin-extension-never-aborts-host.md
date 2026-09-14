---
type: indication
project: vault
slug: plugin-extension-never-aborts-host
status: current
tags: [plugins, extension, hooks]
applies-to: ["lib/plugin-registry.sh", "bin/vault-plugin.sh", "bin/vault-init.sh", "bin/gate.sh", "templates/plugin/**"]
---

# A plugin extension point runs in a child process and never aborts its host

`hooks-never-fail-their-host` owns the same rule for Claude Code hooks. This one owns it for the two
framework extension points, whose host is a shell script the operator ran on purpose.

## Execute it; never source it, never force `sh`

Run the point as `"<script>" <args> </dev/null`.

**Sourcing** puts the point in the host's own shell. It can then redefine the host's functions, read
every host variable, and end `bin/vault-init.sh` outright by calling `exit`. The host reports success
because it never reached its own failure path.

**Forcing `sh`** runs the script under `/bin/sh`, which is `dash` here while all 29 scripts in this
framework are bash. A bash point then dies on its first array or `[[`, and the syntax error is
recorded as the plugin declining rather than crashing.

**Closing stdin** stops a point that reads from it from swallowing the host's input.

## Tell "declined" apart from "could not run"

Exit 1 means the point declined. Any higher exit means it could not run. One warning each, with
different wording. Collapsing them reports a crashed script as one that chose to do nothing, which is
the failure `unreadable-is-not-no` exists to prevent, on a different surface.

The host exits 0 either way. Onboarding a repo is work the operator needs whether or not an extension
succeeded.

## Guard every call, because the host runs under `set -e`

`bin/vault-init.sh` is `set -euo pipefail`, and `bin/gate.sh config` exits 1 on a repo that refuses.
An unguarded call aborts onboarding after the vault directory exists and before the CLAUDE.md
snippet — and the re-run is then refused because that directory is already there. Write
`if ! …; then warn; fi`, never a bare call.

## Check the file again at run time

`bin/vault-plugin.sh add` validates a path once; the point runs later, sometimes much later. Re-check
that the file still exists, is a regular file, and is executable, before running it. A path that
stopped resolving is a warning and the registry row stays: removing it would erase a decision the
operator made.

## Blame the right file

Run `bin/gate.sh config` once before the points and once after. Warn only when the first passed and
the second refused. A repo that already refused is not the plugin's doing, and saying it is sends the
operator to the wrong file.
