# Uninstall the tools the framework no longer uses

The vault framework no longer installs or uses claude-mem, MorphLLM Fast Apply, Graphify, or `bun`.
Older versions of `../setup.sh` installed some of them, and older docs told you to add the rest. This
page removes each one from your machine. Serena is still supported as an optional developer tool,
installed by `../setup.sh --full`; keep it or remove it with `../bin/vault-uninstall.sh --tools`.

Every step is safe to skip when its check already shows the tool gone. Restart Claude Code once at
the end so removed plugins and MCP servers unload.

## 1. claude-mem

Remove the plugin, then its marketplace. The plugin's qualified id is `claude-mem@thedotmack`;
`claude-mem@claude-mem` silently does nothing.

```bash
claude plugin uninstall claude-mem@thedotmack
claude plugin marketplace remove thedotmack
```

Delete its local database and logs. This removes every stored observation and cannot be undone.

```bash
rm -rf ~/.claude-mem
```

Check: `claude plugin list | grep -i claude-mem` and `claude plugin marketplace list | grep -i
thedotmack` both print nothing, and `ls -d ~/.claude-mem` reports no such file.

## 2. MorphLLM Fast Apply

Find the server's name, then remove it from every scope it was added to.

```bash
claude mcp list | grep -i morph
claude mcp remove <name> --scope user      # repeat with --scope project or local if listed there
```

Check: `claude mcp list | grep -i morph` prints nothing.

## 3. Graphify

Remove the hook and the graph from every repo that has one, while the `graphify` command still exists.
This finds them under `~/workspace`; change the path to where your repos live.

```bash
find ~/workspace -maxdepth 4 -type d -name graphify-out -prune | while read -r out; do
    repo=$(dirname "$out")
    (cd "$repo" && graphify hook uninstall)
    rm -rf "$out"
done
```

`graphify hook uninstall` removes only the block between the `graphify-hook-start` and
`graphify-hook-end` markers in `.git/hooks/post-commit` and `.git/hooks/post-checkout`. Other hooks in
those files stay. If `graphify` is already gone, delete that block by hand.

Then remove the program and its Claude skill.

```bash
pipx uninstall graphifyy
rm -rf ~/.claude/skills/graphify
```

Check: `command -v graphify` prints nothing, `grep -l graphify ~/workspace/*/.git/hooks/post-*`
prints nothing, and `find ~/workspace -maxdepth 4 -name graphify-out` prints nothing.

A repo's `.gitignore` may still list `graphify-out/`. The line is harmless; delete it when you next
edit that file.

## 4. bun

Only claude-mem needed `bun`. Keep it if anything else you use runs on it.

```bash
rm -rf ~/.bun
```

Then delete the `BUN_INSTALL` and `PATH` lines the bun installer added to `~/.bashrc` or `~/.zshrc`.

Check: open a new shell; `command -v bun` prints nothing.

## 5. Your own Claude instructions

Older framework docs suggested adding claude-mem and Graphify lines to your personal
`~/.claude/CLAUDE.md`, and project `CLAUDE.md` files may carry the same text. Delete any instruction
that tells Claude to run claude-mem `search`, `morph_edit`, `graphify query` or read
`graphify-out/graph.json`, and any `# graphify` section.

Check: `grep -niE 'claude-mem|morph|graphify' ~/.claude/CLAUDE.md` prints nothing.
