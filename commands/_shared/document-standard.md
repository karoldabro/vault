# Shared module — how to write a document

Binding on **every file a command writes**: plans, specs, briefs, feature dossiers, ADRs,
indications, guides, requirements, runbooks. `communication.md` governs what the user reads in the
terminal and owns the rules the two share — the scope caveat, jargon, references, reporting
exceptions. This file governs what lands on disk and is read again later, by a person or an agent.
**Not** binding on: source code, commit messages, machine-read schemas, or your reasoning.

Enforced by `bin/doc-lint.sh`; every check it makes maps to a numbered rule below. It matches prose,
not code — put a phrase you are *quoting* in backticks and it reads as a quotation.

## What the fix looks like

| written | should have been |
|---|---|
| The contract read "every narrated sentence has its sourced entry", and the row schema demanded a `src:` key per line. 164 of 186 rows joined a numbered research row… | Unsourced lines are rejected. The fact-check is a hard gate. |
| v1 `was rejected` for lacking storytelling and a craft-first brief was issued for v2. The writer resolved all thirteen craft files… The prose moved backwards on every rhythm axis. | The second run improved no metric. |
| Blocking a claim costs you a real handover. Someone who says "next week" might still be the only person who ever comes. So the warning appears before they commit… | **Why it warns instead of blocking:** both sides keep the flexibility and neither takes a risk. The giver learns when the receiver can come, then accepts or rejects. |
| 600 seconds, not 540. The channel's own binding sets a ten-minute floor, so the operator's brief and that floor meet at exactly one value. `Named as a decision, not taken quietly.` | The operator agreed to a shorter video. |

Every left-hand cell obeys the content rules below and is still unusable. Read the table first; it
carries what a rule cannot state.

## Three classes — pick one per file

| class | examples | rule |
|---|---|---|
| **contract** | plan, spec, brief, runbook, ADR, indication, feature dossier | current truth only — someone acts on it |
| **record** | session capture, critique trail, research log | chronology is the payload; it references contracts, never restates them |
| **message** | terminal output | `communication.md` owns it |

**Mixing two classes in one file is the defect this module exists to prevent.** When a contract
document starts carrying how it got here, write the record to its own file and link it in one line.

## The rules

1. **One file answers one question.** Content that answers a different question moves to another
   file. Prefer a new file over a new section. `bin/doc-lint.sh --list-caps` gives the line cap per
   type; if you cross one, apply this rule — the document is answering two questions.

2. **Conclusion before evidence; rule before reason.** The first sentence of a block is what you
   want the reader to do or believe. Counts, quotations and findings come after it, and only when
   they change what someone does. A paragraph that lands its point last is written backwards, and a
   reason longer than the rule it explains is cut.

3. **Say it; do not allude to it.** If the reader has to finish your sentence, you have not written
   it. No verbless fragments, no idiom, no metaphor, no `X, not Y` inversion for rhythm. Sentence
   ceiling 25 words in prose, 30 in a specification — and **never bury a definition inside a rule**.
   Nesting one clause inside another damages recall more than any other feature measured, expert
   readers included. Hoist it into its own sentence.

4. **Name the actor, use a verb.** The subject is the person or system that acts; the action is the
   main verb. `Blocking a claim costs you a real handover` → `If you block the claim, the one person
   who would have come never does.`

5. **Write the current truth.** Delete superseded state; never mark it. No revision logs, no `rev N`
   headings, no strikethrough, no `WITHDRAWN`, no `the first implementation omitted…`. Git holds
   history. Where a contract or regulator demands a revision notice, it goes in **frontmatter as
   metadata** — never interleaved with the body, which is the only part checked.

6. **One rule, one place.** Define each constraint once, at its most specific owner; reference it
   everywhere else. Never re-quote the guideline you are following.
   **Exception — a rule whose omission is catastrophic** may be restated at each point of use, the
   way an aviation checklist repeats a critical item across procedures. Three conditions, all
   required: it is short, forgetting it causes real damage, and the copy reads as a copy of a named
   rule. Exempt `DUP1` in `.doc-lint` with that reason rather than arguing with the linter.

7. **No process inside a contract document.** Not which agent found it, how many reviewers ran, how
   many rounds it took, what got rejected on the way, or any remark about this document's own act of
   writing (`named as a decision`, `stated explicitly rather than implied`, `for the record`). Keep
   the requirement; drop the story that produced it.
   **Exception — a decision record.** An ADR's rejected options and consequences *are* its current
   truth. This bars the panel that produced the decision, never the alternatives it rules out.

8. **Every item is executable — action, constraint, verification.** Name the exact file path; never
   collapse several into a phrase like "the resources". Status is a field beside the item (`DONE`,
   `PENDING`, `BLOCKED`), never a sentence in prose, and open work lives in one section near the
   top. The next reader may be an agent paying for every token: a table row survives a hand-off, a
   paragraph does not.

9. **A heading — and every unheaded block — states its own kind.** `Why it warns instead of
   blocking:` · `Constraint:` · `Failure mode:`. Every word must be one the reader already has;
   idiom and in-house nouns are defects even in an imperative heading. `never generate text` works,
   `never baked into a plate` does not.

10. **References resolve without you.** `communication.md` owns this rule. One addition here: the
    path must be repo-relative.

## The edit pass

Run before writing. Four deletions, in order. Delete each one; do not rewrite it.

1. Every sentence about **how the current state came to be**.
2. Every sentence about **who did it, how many, or how many rounds**.
3. Every rule stated more than once, collapsed to its most specific home.
4. Every reason longer than the rule it explains.

Then, on each surviving line: **would deleting it cause a wrong action?** If not, cut it.

**Never cut a failure mode, a rollback path, an open blocker, an exact file path, or an assumption
you could not verify.** These survive every deletion, and they survive the cap. Shortening removes
narrative, never constraints; `bin/doc-lint.sh --compare <before> <after>` proves which you did.

Evidence for the rules and the caps: `vault/research/document-writing.md`.
