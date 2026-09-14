---
type: indication
project: vault
slug: plans-are-build-orders
status: current
tags: [plans, specification, load-context]
applies-to: ["commands/v-work/steps/02-load-context.md", "commands/v-team/steps/**", "commands/v-do.md"]
---

# A `plans/*.md` in a repo you are about to change is a build order, not background

Read it before writing anything. A plan carries the work items, the file formats, the decisions and
the success criteria. A session that skips it re-derives all four, badly, and its output is deleted.

## The failure this prevents

One session installed a plugin whose repo held a complete plan and a complete file-format contract.
It read the plugin's README line "Designed, not built", concluded the architecture was unavailable,
and wrote a parallel implementation in the target repo: its own hooks, its own runner, its own
status emitter. All of it was deleted at the operator's turn 8 and rebuilt from the plan's rows.

The plan had been in the repository the whole time. Nobody opened it.

## How to apply

- **`status: proposed` or `approved` means unbuilt, not unavailable.** It is the thing to build.
  `status: executed` means read it to learn what the code already assumes.
- **An `architecture/*.md` naming columns, exit codes or a calling convention is a contract to
  satisfy**, not reference material to consult when stuck. Read it before the first edit, not after
  the first failure.
- **Before writing a script in a target repo, check whether the thing you are about to write already
  ships.** A plan's `## Work items` table names every file by exact path. Grep it for what you are
  about to create.
- **A repo whose plan specifies data files wants data**, not code. Filling a declared config format
  is the work; a bash reimplementation of its reader is not.

## Where it binds

`02-load-context.md` §2.3b loads `requirements/` first-class for the same reason. Plans are the
other half: requirements say what the product must do, plans say what this change must build.
