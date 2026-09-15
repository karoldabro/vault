---
type: instruction
campaign: 2026-09-15-0933-doc-corpus
feature: vault document corpus conformance
arena: git worktree on branch campaign/doc-corpus
rounds_used: 3
tags: [campaign, state]
---

# 2026-09-15-0933-doc-corpus — resume point

The first file a resuming session reads. The ledger holds the cases; this holds what it cannot answer.

## Arena

| field | value |
|-------|-------|
| arena | the `vault/` tree of the git worktree at `scratchpad/arena`, branch `campaign/doc-corpus` |
| restore command | `git checkout -- vault/ && git clean -fd vault/` |
| verifier | `./bin/doc-lint.sh <path>` — exit 0 is the only pass |
| control check | `git hash-object <path>` against the value in the `CTL-*` ledger rows |

The main checkout at `/home/kdabrow/workspace/vault` is **not** the arena. Another session works
there. A campaign command that writes outside this worktree is a defect.

`git checkout -- vault/` alone restores tracked files only; untracked files survive it. The
`git clean -fd vault/` half is what makes the restore real, and removing it makes the arena
unrestorable.

## Rounds

| field | value |
|-------|-------|
| rounds used | 3 |
| round cap | 3 |
| per-case fix attempts | 3 |

## Retest queue

| case id | fix commit | waiting since |
|---------|------------|---------------|
|         |            |               |

## Never run

Every `DOC-*` and `CTL-*` row in `ledger.jsonl` has an empty `run_at`. The campaign is done when this
is empty, the retest queue is empty, and no row reads `fail`.

## Deferred decisions

| decision | option taken | option not taken |
|----------|--------------|------------------|
| where `personas`, `rounds` and `convergence` live in a plan | moved to the sidecar, per `commands/v-team/steps/03-propose-loop.md:218` | left in the plan frontmatter, where the linter never reads them |
| whether to move two sections that pass the verifier and are arguably process state | left them; recorded here | moved them, which would have expanded the case on a judgement with no written ruling behind it |
| whether a plan restating a rule that `commands/_shared/communication.md` now owns is cut to a pointer | kept the restatement and named that file as the authority on wording | cut it to a pointer, which would have rewritten what an executed plan recorded as its build spec |
