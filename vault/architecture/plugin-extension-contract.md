---
type: architecture
project: vault
slug: plugin-extension-contract
status: current
tags: [plugins, extension, contract]
---

# Plugin extension contract — what a vault framework plugin ships, and how the framework calls it

A plugin is a directory holding `extend/plugin.tsv` and the entry points it declares. The framework
never scans for plugins. `~/vault/_global/plugins.tsv` lists the ones the operator registered with:

```
bin/vault-plugin.sh add <plugin-dir>
```

| point | file the plugin ships | called by | arguments |
|---|---|---|---|
| init | `extend/init.sh` | `bin/vault-init.sh`, after `VAULT.md` is written | `<code-repo> <vault-dir> <slug>` |
| dod-keys | `extend/dod-keys.tsv` | `bin/gate.sh config` | read as data, never executed |

**Parsing rules, binding on all three files below.** Line 1 is the literal uncommented header, and a
file whose line 1 differs is refused. A row whose field count differs from the header is refused. A
line starting `#` is a comment; a blank line is skipped. An empty cell is written `-`, never left
blank, because a blank trailing cell is invisible and collapses the field count silently.

**How a point runs.** The framework executes it in a child process through its own shebang, as
`"<script>" <args> </dev/null`. It never sources it: a sourced script can redefine the host's
functions, read every host variable, and abort the host through the shared shell's `set -e`. It is
never run as `sh <script>` either, which would execute a bash or python point under `dash` and turn a
working script into a syntax error. `bin/vault-plugin.sh add` refuses a point file that is not
executable. Stdin is closed so a point cannot consume the host's input.

**A point never aborts its host, and its two failures are told apart.** Exit 1 means the point
declined and prints `plugin <name>: <point> declined`. Any exit above 1 means the point could not
run and prints `plugin <name>: <point> could not run (exit N)`. Collapsing the two would report a
script that crashed as a script that chose to do nothing. `bin/vault-init.sh` exits 0 either way,
and calls every point in a status-guarded form so `set -e` cannot abort it mid-onboarding.

**`extend/plugin.tsv`** — header plus one data line:

```
name	points
```

`points` is a comma-separated subset of `init,dod-keys`. `bin/vault-plugin.sh` refuses a plugin
naming a point this framework does not implement, one naming a point whose file is absent, and one
whose point file is not executable.

**This file carries no version.** Claude Code already owns install-time compatibility: a plugin
declares `"dependencies": ["vault@kdabro-vault@^1.6.0"]` in its own `.claude-plugin/plugin.json`,
which the manifest schema defines as "Plugins that must be enabled for this plugin to function" and
whose name pattern accepts an `@^` version constraint. The `points` probe answers the different
question this framework owns — whether a named extension point exists in the installed copy — and it
answers it from what `lib/plugin-registry.sh` implements rather than from a version string that is
stale on `main` right now and moved in 7 of 173 commits.

**`extend/dod-keys.tsv`** — header plus one row per key:

```
key	why
```

`cmd_config` prints `why` in the refusal, so the operator reads why the key exists. Those keys are
required **only** in a repo whose `VAULT.md` carries the plugin's name in its flat `plugins:` scalar.
Without that restriction, registering a plugin would refuse every repo on the machine.

**`~/vault/_global/plugins.tsv`** — header plus one row per registered plugin, mode 0600:

```
name	path	points
```

`path` is the `realpath` taken at registration. `bin/vault-plugin.sh add` refuses a path that is or
traverses a symlink, and replaces the row when the name is already registered, printing the old path.
`vault_plugin_list` refuses a registry holding two rows with the same name. `vault_plugin_run_point`
re-checks that the declared point file still exists, is a regular file, and is executable, before
running it.

**Merging the `plugins:` scalar.** An init point that adds its name must handle four cases, and
running twice must change nothing the second time:

| the repo's `VAULT.md` | required outcome |
|---|---|
| no `plugins:` line | append `plugins: <name>` |
| `plugins:` with an empty value | set the value to `<name>` |
| `plugins:` naming others, not this one | append `, <name>` to that line |
| `plugins:` already naming this one | change nothing |
| more than one `plugins:` line | write nothing and warn |

A point that adds its name **must also write every key its own `extend/dod-keys.tsv` declares**, in
the same pass. Adding the name is what makes those keys required, so a point that adds one without
the other leaves `gate.sh config` refusing the repo it just onboarded.

