<h1 align="center">vault</h1>

<p align="center"><b>Your project's memory, in plain Markdown — and the commands that use it.</b></p>

<p align="center">
<img alt="version" src="https://img.shields.io/badge/version-1.8.0-6b4fbb?style=flat-square">
<img alt="Claude Code plugin" src="https://img.shields.io/badge/Claude%20Code-plugin-d97757?style=flat-square">
<img alt="built with" src="https://img.shields.io/badge/built%20with-markdown%20%2B%20bash-2b7489?style=flat-square">
<img alt="tests" src="https://img.shields.io/badge/tests-bats%20in%20docker-0db7ed?style=flat-square">
</p>

---

A vault holds what you learn about a project: the decisions, the features, the session notes, the
rules for working on the code. Git tracks it. Obsidian reads it. Claude searches it before it
touches your code.

- **Plain Markdown.** Nothing to host. Nothing to lock you in.
- **Install once per machine.** Every repo points at the same copy.
- **A vault per project.** Next to your code, or inside the repo.
- **17 commands.** They plan, build, review and remember, so you don't repeat yourself.

## Install

```
/plugin marketplace add karoldabro/vault
/plugin install vault@kdabro-vault
```

Restart Claude Code, then run `/v-setup` once. It installs the helper tools and writes the machine
config. It prints every command before it runs it, and asks first.

[INSTALL.md](INSTALL.md) has the rest: the other install mode, every flag, the uninstall, the tests.

## Give a repo a vault

```
cd ~/workspace/<your-repo>
/v-init
```

`/v-init` creates the vault, writes a `VAULT.md` at the repo root, and points the repo's `CLAUDE.md`
at it. After that, `/v-work` does the work and `/v-capture` saves what happened.

## Commands

Type them in Claude Code. Each one also answers to `/vault:v-work`, which you need only when another
plugin uses the same name.

### Build something

| Command | What it does | Use it when |
|---|---|---|
| `/v-work` | Proposes a plan, waits for your yes, then builds it | Most work. Start here |
| `/v-do` | Makes one small change, with no approval step | The change is small and obvious |
| `/v-team` | Puts reviewers on the plan and on the diff | A wrong decision is expensive to undo |
| `/v-loop` | Works alone for hours, until every case has a verdict | You want to hand a long job over and leave |
| `/v-pm` | Plans one feature across several repos at once | The feature crosses repo boundaries |
| `/v-method` | Writes the stages, the tools, and what should stop them | The task is big and you don't know how to start |

### Look at it

| Command | What it does | Use it when |
|---|---|---|
| `/v-ask` | Answers a question about the project, changing nothing | You want to know, not change |
| `/v-cr` | Reviews a pull request and posts the comments back | A PR is waiting for you |

### Keep what you learned

| Command | What it does | Use it when |
|---|---|---|
| `/v-capture` | Saves this session into the vault | The work is finished |
| `/v-handoff` | Writes what is left, what to avoid, what is unproven | You are stopping in the middle |
| `/v-report` | Files a problem so a later session fixes it | You found something broken, off today's topic |
| `/v-reconcile` | Rewrites an old document to the writing rules | A document has grown long and vague |

### Set it up

| Command | What it does | Use it when |
|---|---|---|
| `/v-setup` | Installs or repairs the helper tools | Once per machine |
| `/v-init` | Gives the current repo a vault | Once per repo |
| `/v-link` | Links two repos, so loading one loads both | Two repos always change together |
| `/v-guide` | Turns a finished feature into an integration guide | Another team has to build against it |
| `/v-plugin` | Adds, lists or removes a framework plugin | You want what a plugin adds |

## Plugins

| Plugin | What it adds | Install |
|---|---|---|
| [`vault`](https://github.com/karoldabro/vault) | Every command above | `/plugin install vault@kdabro-vault` |
| [`vault-quality-gates`](https://github.com/karoldabro/vault-quality-gates) | Blocks a push to a release branch when a measured number got worse | `/v-plugin vault-quality-gates` |

Write your own from [templates/plugin/](templates/plugin/). The rules a plugin must follow are in
[vault/architecture/plugin-extension-contract.md](vault/architecture/plugin-extension-contract.md).

## Read more

- [vault-guide.md](vault-guide.md) — what a vault holds and how the lifecycle runs.
- [INSTALL.md](INSTALL.md) — install modes, flags, uninstall, tests.
- [docs/commands.md](docs/commands.md) — how the command files are put together.
- [docs/reviewer-packs.md](docs/reviewer-packs.md) — which reviewers `/v-team` seats, and how to choose.
- [tool-playbook.md](tool-playbook.md) — the helper tools and when each one pays off.
