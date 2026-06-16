# Prompt — Consolidate scattered guidelines into `indications/`

Reusable, vault-agnostic migration prompt. It sweeps a project vault for **working rules** (patterns,
coding standards, testing conventions, "how we do things here") that today live scattered across
`architecture/`, `processes/`, `features/`, `serena/` memories, `design/`, `operations/`, etc., and
consolidates them into the new first-class **`indications/`** folder — without losing data and without
stripping subject-matter or decisions from where they belong.

Run it once per vault. It is **idempotent**: rules already in `indications/_index.md` are skipped.

---

## How to run

Paste the **Procedure** below into a session, with the two variables filled in. Two concrete
invocations are at the bottom (givore, digitally-core).

- `{{VAULT}}` — absolute path to the project vault.
- `{{SLUG}}` — project slug.
- `{{SOURCES}}` — the folders/locations to sweep for this vault (see invocations).

Read `~/workspace/vault/vault-guide.md` §6 and §7b first — they define what an *indication* is
(intra-project working rule) versus a `feature` (subject-matter dossier), a `decision` (ADR), or a
`guide` (cross-project contract). **Only working rules move.**

---

## Procedure

You are consolidating scattered guidelines/patterns in the **{{SLUG}}** vault (`{{VAULT}}`) into
`indications/`. Use the framework's token-saving tools (OpenViking `memory_recall`, Serena, grep
fallback). Work in phases and **stop at the approval gate — do not write or move anything before it.**

### Phase 0 — Safety (do this first)

1. Confirm `{{VAULT}}` exists and resolve it per `vault-guide.md` §1.1.
2. `git -C {{VAULT}} status` — if dirty, stop and report; the run needs a clean tree so the diff is
   reviewable and reversible.
3. Ensure the target exists: if `{{VAULT}}/indications/` or `indications/_index.md` is missing, create
   them from the framework (`templates/indication.md`, and the `_index.md` header used by
   `vault-init.sh`). 
4. State that every change will be a single reviewable `docs(vault)` commit, reversible via `git revert`.

### Phase 1 — Discover candidate rules

Sweep `{{SOURCES}}`. For each source doc, extract statements that are **working rules** — imperative
"how to work on this codebase" guidance. Signals: `always/never`, `convention:`, `pattern:`, `rule:`,
`prefer X over Y`, `standard is`, testing approach ("test … with", "mock … not"), naming/structure
conventions, lint/style rules, layering rules ("controllers stay thin"), do/don't examples.

Classify every candidate into exactly one bucket — be conservative:

- **INDICATION** → a reusable working rule. Migrates to `indications/`.
- **SUBJECT** → domain/feature knowledge (what a thing *does*). Stays in `features/`·`architecture/`.
- **DECISION** → a chosen trade-off with rationale. Stays in `decisions/` (ADR). Do not duplicate.
- **DUPLICATE** → already covered by an existing `indications/` entry or another candidate.

**Serena memories are read-only sources.** Read them for rules, but never modify `.serena/memories`
(they are owned by the code repo). Extract the rule into `indications/`; leave the memory untouched.

### Phase 2 — Dedupe & merge

- Drop candidates already present in `indications/_index.md` (idempotency).
- Merge overlapping candidates into one rule (e.g. three docs all saying "use factories in tests" → one
  indication). Note every source that contributed.

### Phase 3 — Propose plan (APPROVAL GATE — stop here)

Present a table the user approves before any write:

```
# | proposed indication slug | one-line rule | sources | source disposition
--+--------------------------+---------------+---------+-------------------
1 | thin-controllers         | …             | architecture/foo.md, serena:bar | back-link kept
2 | tests-use-factories      | …             | processes/testing.md (pure guideline) | replace body w/ pointer
…
SKIPPED (subject/decision/dup): <list with reason>
```

**Source disposition** options (pick per source, conservative default = *back-link kept*):
- **back-link kept** — source stays (it's also subject-matter); add a top line
  `Indication: [[../indications/<slug>]]` so the rule has one home but the doc still cross-links.
- **replace body w/ pointer** — source was a *pure* guideline doc fully absorbed; replace its body with a
  short stub pointing at the new indication (keeps inbound links alive). **Only with approval.**
- **leave as-is** — Serena memories and anything ambiguous.

Never propose deleting a file outright in this pass — superseding stubs only, so nothing is lost.

### Phase 4 — Execute (after approval)

1. Create each `indications/<slug>.md` from `templates/indication.md`: **Rule** (imperative), **Rationale**
   (why / cost of violating), **Examples** (do/don't, real paths from sources), **Applies-to** (paths,
   layers, globs). Leave `<!-- TODO -->` where context is thin rather than inventing.
2. Append a row to `indications/_index.md`: `| <slug> | <one-line rule> | <applies-to> |`.
3. Apply the approved source disposition (back-links / superseding stubs).
4. Update `_moc.md` if it lists folders/sections (add an Indications entry).
5. Cross-link: each indication's `Applies-to`/examples may wikilink the features it governs.

### Phase 5 — Verify & commit

- Re-grep `{{SOURCES}}` for the migrated rule phrasings — each should now resolve to an `indications/`
  entry (directly or via a pointer). Report counts: `N indications created, M sources back-linked,
  K stubbed, P skipped`.
- Check no wikilink was orphaned (every `[[…]]` you wrote resolves).
- `git -C {{VAULT}} add -A && git commit -m "docs(vault): consolidate guidelines into indications/"`.
- Optionally `/v-sync {{SLUG}}` to re-index OpenViking so the new `indications/` are recallable.

Output a final summary and the commit hash. Remind the user the change is one revertible commit.

---

## Invocation — givore

```
Run the consolidation Procedure (prompts/consolidate-into-indications.md) with:
  {{VAULT}}   = ~/vault/givore
  {{SLUG}}    = givore
  {{SOURCES}} = architecture/, processes/, features/, design/, operations/, and serena/ (read-only),
                plus any *guidelines*/*conventions*/*patterns*/*standards* docs anywhere in the vault.
Givore is the rich vault (8 architecture · 16 processes · 27 features · 180 decisions). Expect the most
working rules in processes/ and architecture/. Be careful not to pull domain knowledge out of features/.
```

## Invocation — digitally-core

```
Run the consolidation Procedure (prompts/consolidate-into-indications.md) with:
  {{VAULT}}   = ~/vault/digitally-core
  {{SLUG}}    = digitally-core
  {{SOURCES}} = serena/ (→ ~/workspace/digitally-core/.serena/memories, read-only) and features/.
Digitally-core is lean — most working rules live in the Serena memories (code conventions). Extract
them into indications/ and leave the Serena memories untouched (they're owned by the code repo).
```
