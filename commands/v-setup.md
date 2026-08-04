---
description: Install or repair the vault tool stack (Serena, claude-mem, Graphify) and the machine-layer scaffold. Run once per machine after installing the plugin.
argument-hint: [--full | --minimal | --doctor | --dry-run]
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

# /v-setup — install the vault tool stack

Installing the plugin gives you the commands. It does **not** give you the tools those commands lean on,
because Claude Code never runs an installer on your behalf at install time. `/v-setup` is that step,
run explicitly, once per machine.

It wraps `$VAULT_FRAMEWORK_PATH/setup.sh`, which:

1. installs base prerequisites (git, curl, jq, ca-certificates, unzip) on Ubuntu;
2. creates the machine layer — `~/vault/_global/config.md` and `coupled-groups.md`;
3. optionally installs Serena (uv), claude-mem (bun) and Graphify (pipx);
4. runs a health check and reports what actually landed.

Every command it runs is printed before it runs, and every remote URL with it. On a Mac, or without
passwordless sudo, it prints the commands instead of running them rather than half-installing.

---

## Step 1 — check whether this is even needed

Run the health check first. It is read-only and settles the question in one call:

```bash
"$VAULT_FRAMEWORK_PATH/setup.sh" --doctor
```

If everything it needs is already present, say so in one line and stop. Do not reinstall.

## Step 2 — confirm before installing

**STOP and present the decision.** `--full` runs vendor `curl | sh` installers (uv, bun) and adds a
third-party Claude Code marketplace. That is a real change to their machine, so it needs their word,
not an inference from "they typed `/v-setup`".

Name, in plain words: which tools are missing, that installing them runs vendor scripts fetched over
the network, and that everything lands under their `$HOME` — nothing system-wide, no `sudo` beyond the
apt prerequisites. Offer `--minimal` as the alternative: the commands work without the tools, they
just cost more tokens. Then ask.

If the user passed an explicit flag (`--full`, `--minimal`, `--doctor`, `--dry-run`), that flag **is**
the decision — pass it through and skip the gate. `--doctor` and `--dry-run` change nothing, so they
never gate.

## Step 3 — run it

```bash
"$VAULT_FRAMEWORK_PATH/setup.sh" --full --yes
```

Never run it under `sudo` — that points `$HOME` at `/root` and strands the whole install there.
`setup.sh` refuses on its own, but do not get there.

Under a plugin install, `setup.sh` skips the `install.sh` symlink step: Claude Code already supplies
the commands, and symlinking them a second time would install every command twice.

## Step 4 — report

Report what changed and what did not. Under the communication contract that means: name the tools that
were installed, and **always** name anything that failed, was skipped, or only got printed instead of
run. Do not list the tools that were already fine.

Close with the two things that need the user, if they apply:

- a fresh shell (`exec $SHELL -l`) when new PATH entries landed;
- a Claude Code restart when a plugin or MCP server landed.

---

## Notes

- Re-running is safe. `setup.sh` is idempotent.
- `--dry-run` prints every command without running any of them. Offer it to a hesitant user.
- MorphLLM Fast Apply is never installed — it needs a paid API key. Its absence is expected, so do not
  report it as a problem.
- Uninstall is `$VAULT_FRAMEWORK_PATH/bin/vault-uninstall.sh --dry-run` first, then `--yes`. Removing
  the plugin removes the commands but leaves the tools and your vaults untouched.
