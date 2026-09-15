# document-corpus — rewrite a body of documents until each one passes

Repairs every document in a corpus that fails the project's own document check. Proven by the
2026-09-15-0933-doc-corpus campaign in this repo: 21 cases, 17 documents, 100 violations, 0 failures.

## Unit of work

One document, **plus every file its repair creates**. In this repo a plan's process narrative moves
to a `<slug>.trail.md` sidecar that does not exist yet, so the unit is two paths and the fence must
name both.

**Clauses the verifier cannot detect**, each citing a written rule:

| clause | the rule it cites | how the case checks it |
|--------|-------------------|------------------------|
| no process state in a plan's frontmatter | `commands/v-team/steps/03-propose-loop.md:218` | `grep -c '^personas:\|^rounds:\|^convergence:' <path>` returns 0 |

A clause with no rule to cite is recorded as a finding and left alone.

## Backlog

```bash
for f in $(find <corpus> -name '*.md'); do ./bin/doc-lint.sh "$f" >/dev/null 2>&1 || echo "$f"; done
```

Then run each clause above across the whole corpus, because a document failing only an undetectable
clause never appears in that list. The count is every document from both passes.

Each row's `reason` carries `doc-lint.sh`'s own message text. A rule code expanded from memory is how
a campaign prescribes the wrong repair: `LONG1` reads as a length cap and fires at
`bin/doc-lint.sh:489` for one sentence over 30 words.

## Actor

One agent per unit, reading `commands/_shared/document-standard.md` and `templates/trail.md` before
it changes a line. It moves process narrative to the sidecar rather than deleting it, and lifts any
requirement that would vanish — a failure mode, a rollback path, an exact path — into a new section
of the document instead.

## Verifier

`./bin/doc-lint.sh <path>` — an exit code. Exit 0 is the only pass, and no agent decides a verdict by
reading the document. Because it is a command, the working agent may run it and the orchestrator
re-runs it; the two must agree.

**Discriminator: control rows.** Two documents that already pass enter the ledger as `CTL-*` cases
whose `git hash-object` must match the value recorded at enumeration. A campaign whose controls drift
has an actor rewriting what nobody asked it to.

**Loss check:** `./bin/doc-lint.sh --compare <before> <after>` takes exactly two files
(`bin/doc-lint.sh:575`), so concatenate a unit's files into one temp file first. Run it after every
rewrite, not only after a section move — it keys on literal strings, so rephrasing a line that never
moved can drop a key.

## Caps

3 rounds. 3 repair attempts per document.

## Stop rule

Every ledger row terminal, none reading `fail`, and every control row byte-identical.

## Arena

A git worktree on its own branch. Restore: `git checkout -- <corpus> && git clean -fd <corpus>`.

The `git clean` half is not optional. `git checkout` restores tracked files and leaves every
untracked file in place, so a restore without it returns an arena still carrying the last run's
output.
