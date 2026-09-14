---
type: reference
project: vault
slug: plugin-template
status: current
tags: [plugins, extension, template]
---

# Writing a vault framework plugin

**Registering a plugin trusts every future commit of that repository.** The framework runs its
scripts during `bin/vault-init.sh`, on every repo you onboard afterwards. Register a path you own or
have read.

Copy this directory into your plugin repo, then register it:

```
bin/vault-plugin.sh add <plugin-dir>
```

`bin/vault-plugin.sh list` shows what is registered; `doctor` re-checks every path; `remove <name>`
drops one, after which the framework calls nothing.

Full contract, including the file formats and how a point is executed:
`vault/architecture/plugin-extension-contract.md`.

## The two points

| point | file you ship | when it runs | arguments |
|---|---|---|---|
| `init` | `extend/init.sh` | during `bin/vault-init.sh`, after `VAULT.md` is written | `<code-repo> <vault-dir> <slug>` |
| `dod-keys` | `extend/dod-keys.tsv` | whenever `bin/gate.sh config` reads a repo | none — it is data |

Name the ones you implement in `extend/plugin.tsv`. Registration is refused if you name a point whose
file is absent, one that is not executable, or one this framework does not implement.

## What the framework does NOT do for you

Slash commands, agents, skills and Claude Code hooks come from **your own**
`.claude-plugin/plugin.json`, not from a point here. Claude Code already composes those across
plugins. Declare the framework you need with its `dependencies` key:

```json
{ "dependencies": ["vault@kdabro-vault@^1.6.0"] }
```

## The three rules that bite

1. **Your `init` point must write every key your `dod-keys.tsv` declares.** Adding your name to the
   repo's `plugins:` scalar is what makes those keys required. A point that adds the name without the
   keys leaves `bin/gate.sh config` refusing the repo it just onboarded.
2. **Merge into an existing `plugins:` line; never add a second.** The reader takes the first line
   only, so a second one is dropped in silence and the next plugin's keys are never enforced. More
   than one line is a refusal.
3. **Append a newline before you append anything else.** A `VAULT.md` with no trailing newline fuses
   your first line onto its last key, and the fused line parses as neither.

Running your point twice must change nothing the second time.

## Failure

Exit 0 when you did your work or had nothing to do. Exit 1 to decline. Any higher exit is reported as
"could not run" — the two are told apart so a crashed script is not recorded as one that chose to do
nothing.

Your point never stops the host. `bin/vault-init.sh` completes and exits 0 whatever you return,
because onboarding a repo is work the operator needs whether or not your plugin succeeded. That also
means nobody will notice a silent mistake, so print what you did.

## Files

```
extend/plugin.tsv      name and points — required
extend/init.sh         the init point — executable
extend/dod-keys.tsv    VAULT.md keys your plugin requires
```
