---
description: Install, list or remove a vault framework plugin. Give a repo name; this does the rest.
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here.

# /v-plugin — install a framework plugin from a repo name

`/v-plugin <repo>` · `/v-plugin list` · `/v-plugin remove <name>` · `/v-plugin doctor`

`<repo>` is `owner/repo`, a git URL, a local path, or a bare name this framework's own
`.claude-plugin/marketplace.json` lists. Everything else is one script:

```bash
$VAULT_FRAMEWORK_PATH/bin/vault-plugin.sh install <repo>
```

It resolves the name, clones when needed, refuses anything without an `extend/plugin.tsv`, prints
what it is about to trust, and asks. Contract:
`$VAULT_FRAMEWORK_PATH/vault/architecture/plugin-extension-contract.md`.

---

## What you do

**1. Run it.** Pass the operator's argument through unchanged. Never guess an owner for a bare name
the script could not resolve — that is how a typo clones somebody else's repository. Report the
refusal and ask which repo they meant.

The prompt needs a terminal. When the tool call gives the script no tty, it registers nothing and
says so. **Do not add `--yes` to get past that.** Show the operator the plugin, the path and the
points the script printed, and ask them here. Pass `--yes` only after they answer.

**2. Say what changed.** Name the plugin, the path it was registered from, and the points it
declares. Then the one consequence that is not obvious:

> Registering runs that repo's scripts during every `bin/vault-init.sh` from now on, and trusts every
> future commit of it — not only the one on disk today. `bin/vault-plugin.sh remove <name>` undoes it.

**3. Offer the second install, when it applies.** A plugin carrying `.claude-plugin/plugin.json`
also ships slash commands, which come from Claude Code and not from this framework:

```
/plugin install <name>@<marketplace>
```

Check the repo is reachable before offering it. A private repo cannot be cloned by Claude Code, and
the install fails with an error that does not say why. Say so instead of offering it.

**4. Opt a repo in, if the operator names one.** A plugin's keys bind only where a repo's `VAULT.md`
carries its name:

```
plugins: <name>
```

One line, comma-separated, never a second line. The plugin's own `init` point writes this during
`/v-init`; by hand is for opting out, or for a repo already onboarded.

## Removing

`bin/vault-plugin.sh remove <name>` drops the registry row. The clone stays on disk — deleting a
directory the operator may have work in is not this command's call. Say where it is.

## Reporting

One line per fact. Report the refusal, the path, and anything you could not verify. Never report that
a normal step was normal.

```
Registered: <name> -> <path>  [<points>]
Claude Code commands: /plugin install <name>@<marketplace>   | not offered: <why>
Opt a repo in: add `plugins: <name>` to its VAULT.md
```
