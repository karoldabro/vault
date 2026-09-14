---
type: decision
project: vault
id: ADR-030
slug: framework-extension-points
status: accepted
scope: repo
date: 2026-09-14
tags: [adr, plugins, extension, install]
---

# ADR-030 — two extension points, and a registry the operator writes by hand

## Context

A capability outgrew this repo. The code-quality gate is a different scope with its own release
cadence, so it moved to `vault-quality-gates`. To be useful it must reach two things this framework
owns: per-repo onboarding, where it scaffolds its own files, and `bin/gate.sh config`, where it
declares the `VAULT.md` keys it needs.

Four points were designed first — `setup`, `init`, `install`, `dod-keys`. Evidence cut that in half.

`setup.sh:423-427` skips `install.sh` whenever the framework is plugin-installed, which is how this
machine runs. Anything called from `install.sh` could never fire here. `install.sh:169-175` only
symlinks a hook script; registration happens separately at `:207-232` and needs the event, matcher
and flag, so a point handed the hooks directory could ship a hook Claude Code never calls. And 23
Claude Code plugins already compose on this machine, each carrying its own commands and
`hooks/hooks.json`. A `commands` or `install` point would have duplicated a working mechanism with a
broken one.

The one consumer also had nothing machine-level to install: none of its work items name `setup.sh`.

## Decision

**Two points.** `init` runs a plugin's `extend/init.sh` during `bin/vault-init.sh`, after `VAULT.md`
exists, with `<code-repo> <vault-dir> <slug>`. `dod-keys` reads a plugin's `extend/dod-keys.tsv` in
`bin/gate.sh config`. Contract: `vault/architecture/plugin-extension-contract.md`.

**Commands, agents and Claude Code hooks come from the plugin's own manifest**, with
`dependencies: ["vault@kdabro-vault@^1.6.0"]` declaring the framework it needs.

**A plugin's keys bind only where the repo opted in**, through a flat `plugins:` scalar in its
`VAULT.md`. Otherwise registering one plugin would refuse every repo on the machine.

**The operator names every path.** `bin/vault-plugin.sh add` is the only writer of
`~/vault/_global/plugins.tsv`, stores the `realpath`, and refuses a path that traverses a symlink.
Nothing is scanned for.

**Compatibility is a capability probe, not a version compare.** Registration refuses a plugin naming
a point `lib/plugin-registry.sh` does not implement. The framework's own version string cannot answer
that question: it moved in 7 of 173 commits and was stale on `main` when this was written.

## Consequences

**Registering a plugin trusts every future commit of that repository**, not the one reviewed at
registration. `commands/v-cr/sandbox.md` treats a repo-supplied script as hostile and runs with
`core.hooksPath=/dev/null`; registration is the single point where this framework decides otherwise,
for one named path, once. `bin/vault-plugin.sh doctor` reports drift; it never repairs it.

A point runs in a child process through its own shebang with stdin closed, and its two failure kinds
are told apart — rule and reasons in `vault/indications/plugin-extension-never-aborts-host.md`.

**One consumer justifies this API.** Each point is the narrowest seam that consumer declares, and a
second consumer will change the shape. If `vault-quality-gates` never ships, this is dead code.

The framework gains a file it executes from outside its own tree, which it never did before.
