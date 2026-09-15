---
type: instruction
campaign: 2026-09-15-0933-doc-corpus
tags: [campaign, brief]
---

# 2026-09-15-0933-doc-corpus — agent brief

Every agent reads this before it starts. It holds the traps this campaign has already paid for.

**A trap is added the moment it costs a run.** The agent that hit it writes the row.

## Environment

The arena is the git worktree at `scratchpad/arena` on branch `campaign/doc-corpus`. Every path is
relative to that worktree root. Writing to `/home/kdabrow/workspace/vault` is a defect: another
session works there.

The verifier is `./bin/doc-lint.sh <path>`. Exit 0 is the only pass. No agent decides a verdict by
reading the document.

## Traps

| trap | what it looks like | what to do instead |
|------|--------------------|--------------------|
| A case writes two files, not one | The `PROC1` repair moves a `## Critique trail` section out of the plan and into `<slug>.trail.md`, which does not exist yet | Treat `<slug>.md` and `<slug>.trail.md` as one unit. No other agent may hold either while you work |
| `DOC_LINT=off` turns a violation green | `doc-lint.sh` honours an env var that suppresses its own findings | Never set it. A verdict produced with it set is void |
| Deleting the flagged lines passes the check and loses the record | `PROC1` and `PROC6` flag process narrative; deleting it satisfies the linter | Move it to the sidecar. The plan keeps current truth, the sidecar keeps how it was reached |
| A result file quoting flagged text looks like it needs an exemption | You must quote the sentence the linter flagged, in `results/<id>.md` | Quote it plainly. Files under `campaigns/*/results/` carry no `type:` frontmatter, so the linter classes them by parent directory as records and exempts them from the history checks |
| `## Refs` is a prose paragraph, not a list | Recipe step 5 says to insert into the list, and some plans have no list to insert into | Convert the paragraph to list items first. A bare line appended under a paragraph reads as a continuation of it |
| A plan's acceptance check contradicts the artifact it names | One plan required 7 slides against an 8-slide deck, and neither the verifier nor the trail can see it | Open the artifact the plan names and check its numeric criteria before the section move. A mismatch goes in `## Open & deferred`, never into a silent edit |
| `process_record` is the dated filename, not the slug | `templates/plan.md:7` writes `{{slug}}.trail.md`, and a dated plan's filename is not its slug | Follow the repo precedent at `vault/plans/2026-07-10-1740-llm-collaboration-patterns.md:6` — the dated sibling filename |
| `--compare` takes exactly two files | `bin/doc-lint.sh:575` accepts two arguments, so "plan and trail together" is not two paths | Concatenate the plan and the trail into one temp file, then compare that against the HEAD copy |
| Your result file trips `LONG1` too | A record is exempt from the history checks, never from the 30-word sentence rule | Lint the result file, not only the target. A `type: record` line prints an "unknown type" note, which is not a finding |
| A dated record keeps its stale names; a contract does not | A session records what was true on its date, so correcting a step name there rewrites history and drops keys from the loss check | Correct a stale name in a plan, which is current truth. Leave it in a session or a trail, and say so in the result |
| A count in your case brief is not evidence | One brief said four process keys where the file had three, and one said a rule was a line cap when it is a sentence rule | Run the command and use what it returns. A count that arrives without its command is a claim |
| `DUP1` follows the tables into the sidecar | Three per-round findings tables moved unchanged repeat their header three times, and `bin/doc-lint.sh:469` is not exempt in a record | Merge the rounds into ONE table with a leading `round` column (`1`, `2`, `diff`). Every row keeps its text; the header exists once |
| A trail's step numbers are stale against today's repo | One trail named `/v-capture` Step 5b; the live file has Step 4d — find it with `grep -n 'Step 4d' commands/v-capture.md` rather than trusting a line number here | Check any step number against the current command file before lifting it into the plan as current truth |
| `PROC2` fires on ordinary prose, not headings | `lib/doc-lint-patterns.tsv:25` matches a seat noun — `critic`, `reviewer`, `persona`, `agent`, `panel` — within 40 characters of `spawned`, `returned`, `converged` or `ran out of rounds`, anywhere in a body line | Check your replacement wording, not just the heading. Moving a section clears one instance and leaves the rule armed |
| The plan body contradicts its own trail | A findings row marked `applied` can name a fix the body never received — one plan recorded a hallucinated flag as fixed while step 5 still used it | Check every `applied` row against the body BEFORE the section move. Moving the trail out unedited deletes the only record that the body is stale |
| Consolidating two spellings of one path breaks the loss check | The check keys on the literal string, so `_shared/premortem.md` and `personas/_shared/premortem.md` are two keys, as are `tests/unit/` and `tests/unit/capture-templates.bats` | When a path appears in two spellings, keep both across plan and trail |
| `DUP1` is in-file only | `bin/doc-lint.sh:469` compares lines within one file, so a companion document is never involved | Look for a repeated line inside your own file — usually a table header used once per round |
| Rewriting severity words to clear `PROC5` | The repo-root `.doc-lint` exempts `PROC5`, so `BLOCKER`, `MAJOR` and `NIT` are legal in a plan and no finding will ever name them | Leave them. An edit chasing a rule that cannot fire is a wasted edit |
| Clearing `PROC6` re-fires `PROC6` | Its pattern at `lib/doc-lint-patterns.tsv:29` is an alternation of four phrases: `per-round metrics`, `findings-delta`, `persona overlap`, `sycophancy flag`. Rewriting one into another clears nothing | Read the alternation before rewriting, and check the replacement wording against all four |
| A flagged phrase is a requirement, not narrative | `sycophancy flag` in an ADR is the literal name of a metric field that `tests/unit/v-team.bats:130` asserts — moving it to a sidecar deletes a requirement from a contract | Mark it as the quotation it is, in backticks. `commands/_shared/document-standard.md` sanctions the escape: the linter matches prose, not code |
| Recipe step 4 is invisible to the verifier | `bin/doc-lint.sh` scans the body only, so `personas`, `rounds` and `convergence` in frontmatter never fire a finding. A plan that keeps them still exits 0 | Do step 4 anyway. The brief and `commands/v-team/steps/03-propose-loop.md:218` require it; the verifier cannot ask for it |
| Appending the Refs line leaves a stray blank line | The file ends with a newline, so splitting on it yields a trailing empty element | Insert into the `## Refs` list, never append to the end of the file |
| `LONG1` reads like a line cap and is not | `bin/doc-lint.sh:489` emits it from `count_long_sentences "$_target" 30 1` — it flags one SENTENCE over 30 words, whatever the document's length | Split the sentence, one idea each. Splitting the file changes nothing and loses the document's shape |

## The plan repair, step by step

Thirteen cases share one shape: a `## Critique trail` section sits inside a plan and belongs in a
sidecar. Follow this rather than deriving it again.

1. Run `./bin/doc-lint.sh <plan>`. The `PROC1` hits mark the section heading, not the whole span.
   Read the file and take the section from its `##` down to the last line before `## Refs`.
2. Write `<slug>.trail.md` to the `templates/trail.md` shape. `bin/doc-lint.sh:596` types any
   `*.trail.md` as a record, which skips the history, process and reference checks and the line cap.
   Only `DUP1` and the 30-word `LONG1` can fire there, and `lib/sentence-count.sh` skips table rows,
   so findings and metrics kept as tables cannot fail.
3. Rewrite any `_Metrics: …_` prose paragraph as a table. As prose it risks `LONG1`; as rows it is
   exempt. Some plans carry no such paragraph and hold their metrics inside the round prose instead;
   those become the sidecar's `## Metrics` table the same way.
4. Move `personas`, `rounds` and `convergence` out of the plan's frontmatter and into the sidecar.
   `commands/v-team/steps/03-propose-loop.md:218` rules that they are process state and live in the
   sidecar. Add `process_record: <slug>.trail.md` to the plan, spelled as `templates/plan.md:7`
   spells it.
5. Add one `- Process record: \`<path>\`` line inside the `## Refs` list. Some plans have no `## Refs`
   section; create one rather than appending the line elsewhere.
6. Remove what the linter misses and `commands/_shared/document-standard.md` rule 7 bars: a heading
   like `## Converged plan (v1 — after panel)`, and summary clauses naming the review. `HIST8`
   matches only when the parenthesis closes right after `v1`, so the longer form slips past it.
7. Prove nothing was lost: `./bin/doc-lint.sh --compare <the HEAD copy> <plan and trail together>`.
   Run it after EVERY rewrite, not only after the section move. It checks the prohibition set
   `bin/doc-lint.sh:510` builds, so rephrasing a row that never moved can drop a key from it — one
   case lost `infinite` by rewording a backlog row that stayed exactly where it was.
8. A requirement that would vanish into the sidecar belongs in a new section of the plan instead. A
   path guard, a contract or a failure mode is current truth, not a record of how the plan was
   reached.

## Verified facts

Facts no agent re-derives. Each carries the command that produced it and the date.

| fact | command | date |
|------|---------|------|
| 17 documents fail the verifier, carrying 100 violations between them | the enumeration loop in `ledger.jsonl` | 2026-09-15 |
| The violations are 56 `PROC1`, 19 `PROC6`, 10 `LONG1`, 6 `PROC4`, 3 `HIST8`, 2 `DUP1`, and one each of `REF1`, `PROC2`, `HIST7`, `HIST5` | `doc-lint.sh` over every `vault/**/*.md`, codes counted | 2026-09-15 |
| No `*.trail.md` sidecar exists for any of the 13 failing plan documents | `[ -f "${f%.md}.trail.md" ]` over the plan rows | 2026-09-15 |
| The two `CTL-*` documents pass the verifier today | `./bin/doc-lint.sh` on each, exit 0 | 2026-09-15 |
