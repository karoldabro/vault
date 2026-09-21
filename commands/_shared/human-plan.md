# Shared module — the human plan page

Binding on `bin/render-human.sh`, `bin/gate.sh human` and the PROPOSE step that publishes the page. A
plan that names an architecture spec has a page beside it, `<plan name>.human.html`, that a person
reads before approving. A script writes the page from the plan and the spec. A model does not.

## Call and output

`bin/render-human.sh <plan> [--repo <root>] [--stdout]` writes the page beside the plan. With
`--stdout` it prints the same bytes and writes nothing. `--repo` defaults to the working directory and
locates the profile the spec names, the repo's `arch-profiles/` first and then the framework's. Exit 2
means the plan is unreadable, has no text under `## Task`, or a file the renderer needs is missing.

`bin/gate.sh human <plan> [--repo <root>]`. `all --phase approve` runs it after `arch`, with the same
`--repo`.

## Page structure

1. `<h1>`: the plan's title line.
2. `<h2>Check these yourself</h2>` and one `<li>` per `@review` line of the spec's profile. The
   heading is left out when the profile has none.
3. The plan sections listed in `templates/human-plan-sections.tsv`, in that order. Each line of that
   file is `section`, a tab, then the columns shown (`*` is all, an underscore stands for a space).
   A section that is absent or has no body is left out. Columns not listed are left out, so a status
   flip, a date, a verdict or evidence never changes the page. Frontmatter is never shown.
4. A Sessions table with a `depends` column is followed by its graph.
5. The spec sections in file order, every column shown. The spec's title and the text before its
   first `## ` heading are left out.

Each section is `<h2>` with the escaped heading, then its body. A table is `<table>` with `<th>` cells
from the header and `<td>` cells for every row, and a cell beyond the header is shown too. A mermaid
fence is the opening tag `<pre class="mermaid">` alone on its line, the body, and `</pre>` alone on its
line, and the body may be empty. Another fence is `<pre><code>`. A `~~~` fence and an indented code
block are not recognised and render as paragraphs.

Constructs that render: table, bullet list, numbered list, paragraph, bold, code span, and a
`###` heading. An indented line that is not a bullet joins the item before it with a space, and an
indented bullet is an item of the same flat list. Any other line renders as an escaped paragraph.
`\|` in a cell is one pipe.

## Escaping

- Cells and prose escape `&`, `<` and `>`. A code span becomes `<code>` and `**x**` becomes
  `<strong>` after that.
- A mermaid body escapes `&` and `<` only, so `-->` stays readable. A mermaid line that holds `click`,
  `%%`, `href`, `javascript` or `vbscript`, in any letter case and anywhere in the line, is left out.
  A label that merely contains one of those words is left out with it.
- The page holds no `<script` tag and no external file but the fonts stylesheet.

## The session graph

`flowchart TD`, then one node line per session, `ID["ID label"]`, then one edge line per dependency,
`A --> B`, in table order and deduplicated, with no self edge. An id must match `^[A-Za-z0-9_-]+$`
or its row is skipped, and the first row of a repeated id wins. An id that is a mermaid keyword (`end`,
`graph`, `subgraph`, `style`, `class`, `click`, `default`, `flowchart`, `linkStyle`) is drawn as
`n_<id>`. A label keeps only `[A-Za-z0-9 .,:/_-]` from the scope, with single spaces, and stops
within 48 characters at a word boundary.

## Determinism

The renderer runs under `LC_ALL=C`, reads bodies from files rather than `awk -v`, never iterates
with `for (k in a)`, writes no time, path or working directory, and ends the page with exactly one
newline. The same plan and spec give the same bytes on every `awk`.

## Profile checklist lines

`@review`, a tab, then one plain sentence without `&`, `<`, `>`, a quote or a backtick, in a profile's
`.tsv`. `bin/gate.sh arch` skips a line whose first field starts with `@`.

## Gate order

1. The plan is unreadable: exit 2.
2. The plan names no `arch_spec`: exit 0, no output. `arch` already refuses that plan in a profiled repo.
3. `human_plan` is empty: refuse.
4. `human_plan` is neither `https://claude.ai/artifact/<id>` with an id of letters and digits, nor
   `file:` followed by the page's file name: refuse.
5. The page is missing: refuse.
6. A fresh render, compared with `cmp` against the page, differs: refuse. The renderer failing is exit 2.

Success prints `human: ok <page path>` to stdout. A refusal prints `REFUSED human <plan>: <problem>`
to stderr.

| defect | `<problem>` text |
|--------|------------------|
| step 3 | plan names no human_plan |
| step 4 | human_plan must be an https://claude.ai/artifact/`<id>` URL or file:`<page name>` |
| step 5 | human page is missing: `<path>` |
| step 6 | human page is stale: first difference at line `<N>` |

## What the gate does not prove

It does not compare the published Artifact with the local page, and a URL proves only its shape. A
page opened as a local file shows diagrams as source text, because the page holds no script.
