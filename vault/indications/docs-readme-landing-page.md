---
type: indication
project: vault
slug: docs-readme-landing-page
scope: repo
tags: [indication, docs, readme]
---

# docs-readme-landing-page

## Rule
The `README.md` is a landing page, not a manual: what-it-is in a sentence or two, a one-line copy-paste
install, attach-to-project, a brief command table, and links out. Deep detail (install flags, uninstall,
tests, path resolution, subsystem internals) lives in a linked page (`INSTALL.md`, `vault-guide.md`,
`tool-playbook.md`), never inline in the README. Write the human-facing docs for a non-programmer:
humanize the prose, but leave reference tables and code blocks dense — they earn their length.

## Rationale
A README that carries every detail buries the one thing a new reader needs (what is this, how do I start)
under flags and edge cases, and it reads as machine-generated. Moving detail to linked pages keeps the
front door short without losing anything. Humanizing prose (cut em-dash pile-ups, stacked parentheticals,
mechanical bold, rule-of-three padding) is what makes the docs sound written by a person; sparing the
reference tables is what keeps them accurate.

## Examples
- Do: README install = one line (`git clone … && cd … && ./setup.sh --full --yes`) + a "before you start"
  prereq note; the flags table and uninstall live in `INSTALL.md`.
- Do: humanize `vault-guide.md` prose while keeping every section, table, and code block intact.
- Don't: inline the full `--sandbox` safety posture or the flags table in the README — link to it.
- Don't: "humanize" the dense reference tables or the Claude-facing command/persona specs (load-bearing).
- Guard: after a large Markdown `Write`, grep for stray tooling artifacts (e.g. `</content>`) before commit.

## Applies-to
`README.md`, `INSTALL.md`, `vault-guide.md`, `tool-playbook.md`, `_moc.md`, and other human-facing docs.
</content>
