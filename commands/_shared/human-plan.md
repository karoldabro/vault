# Shared module — the human plan page

Binding on `bin/render-human.sh`, `bin/gate.sh human` and the PROPOSE step that publishes the page. A
plan that names an architecture spec has a page beside it, `<plan name>.human.html`, that a person
reads before approving. A script writes the page from the plan and the spec. A model does not.

## Call and output

`bin/render-human.sh <plan> [--repo <root>] [--stdout]` writes the page beside the plan. With
`--stdout` it prints the same bytes and writes nothing. `--repo` is accepted so `bin/gate.sh human` can
pass it on; the page does not depend on it. Exit 2 means the plan is unreadable, has no text under
`## Task`, a file the renderer needs is missing, or the section list names an unknown mode.

`bin/gate.sh human <plan> [--repo <root>]`. `all --phase approve` runs it after `arch`, with the same
`--repo`.

## Page structure

The page carries only what the operator supplies or judges. Everything a gate checks stays in the plan
and the spec.

1. `<h1>`: the plan's title line.
2. One block per row of `templates/human-plan-sections.tsv`, in file order. A row is five tab-separated
   fields: `source` (`plan` or `spec`), `section`, `mode`, `cols` and `heading`. `cols` is `*` or the
   column names to keep, space-separated, with an underscore for a space inside a name. A block whose
   section is absent, or whose mode keeps nothing, is left out with its heading. The `plan` rows come
   first, then the `spec` rows.
3. After each file's rows, every section of that file the list does not name, in file order, shown as
   its heading and its mermaid blocks only. A section with no mermaid block is left out. This rule is
   what keeps a diagram from ever missing the page.
4. The last line names the plan's file name and the plan's `arch_spec` value as written.

Frontmatter is never shown. The listed columns keep status flips, dates, verdicts and evidence off the
page, so writing them never makes the page stale.

## Modes

- `all`: the section as written.
- `task`: the section as written, less the text from `Keywords:` to the end of its paragraph.
- `match:<columns>:<words>`: keeps an item that contains one of the `|`-separated words, ignoring case,
  `*` and backticks. An item is a table row, a bullet with its indented continuation lines, or a
  paragraph. A table row is judged on the first of the `|`-separated columns it has, or on its whole
  text when it has none. A bullet or paragraph is judged on its text before the first `:`. `###`
  headings are dropped.
- `er`: draws the section's table as one mermaid `erDiagram` and drops everything else in the section,
  hand-written diagrams included. A section with no table shows its hand-written diagrams instead. A token keeps `[A-Za-z0-9_]` and turns every other character into
  `_`. `key` `UQ` becomes `UK`, and a key other than `PK`, `FK` or `UK` is dropped. A `references`
  value of the form `table.column` draws `table ||--o{ <row table> : <column>`; any other value draws
  nothing. The generated lines skip the mermaid line filter below, since every token is plain.
- `signatures`: lists each table row as `interface.method(params): returns`, with `, throws <x>` when
  `throws` is neither empty nor `-`. `params` of `-` prints as `()`.
- `labels`: the section as written, except that inside a double-quoted string of a mermaid block a
  parenthesis group that follows a letter, digit or `_` becomes `()`. `"Svc.run(id: int)"` becomes
  `"Svc.run()"`, and `"step (a)"` stays.

Every mode but `er` shows the section's mermaid blocks, under the first row that names the section only.
`match` and `diagrams` drop every other fenced block.

## Rendering

Each block is `<h2>` with the escaped heading, then its body. A table is `<table>` with `<th>` cells
from the header and `<td>` cells for every kept row, and a cell beyond the header is shown too. A mermaid
fence is the opening tag `<pre class="mermaid">` alone on its line, the body, and `</pre>` alone on its
line, and the body may be empty. Another fence is `<pre><code>`. A `~~~` fence and an indented code
block are not recognised and render as paragraphs.

Constructs that render: table, bullet list, numbered list, paragraph, bold, code span, and a
`###` heading. An indented line that is not a bullet joins the item before it with a space, and an
indented bullet is an item of the same flat list. Any other line renders as an escaped paragraph.
`\|` in a cell is one pipe. A kept Sessions table with a `depends` column is followed by its graph.

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
