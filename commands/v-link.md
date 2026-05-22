---
description: Declare two projects as coupled (cross-recall enabled). Updates ~/vault/_global/coupled-groups.md and both project MOCs.
argument-hint: "<project-a> <project-b> [reason]"
---

Declare a coupled-project relationship. After this, OV auto-recall will pull context from peer when a session opens in either member.

## Parse $ARGUMENTS

Expected: `<project-a> <project-b> [reason words...]`

If fewer than 2 args, stop and tell user the expected syntax. Don't guess.

Resolve each project arg:
- If it matches a directory under `~/vault/` → use that slug.
- If it matches a path under `~/workspace/` → use the dir name, verify a vault entry exists.
- If neither → stop, suggest running `/v-init` (from inside the missing project's code repo) before retrying.

## Find or create the group

Read `~/vault/_global/coupled-groups.md`. Look for an existing group containing either project. Cases:

1. **Both projects already in the same group** → no-op. Print: `Already coupled in group <name>.`
2. **One project already in a group, other isn't** → append the other to that group's bullet list.
3. **Each project in a different group** → STOP. Don't merge groups silently. Tell the user the two existing group names and ask whether to merge or skip.
4. **Neither in a group** → create a new group. Group name = lexicographically-first project slug. Add both.

## Write the change

In `~/vault/_global/coupled-groups.md`, append/edit under the appropriate `### <group>` heading:

```
- `~/workspace/<repo-path>` (<role: a-sentence>)
- Reason: <reason from args, or auto-generated from the two project descriptions>
```

Date the change inline: ` <!-- linked YYYY-MM-DD -->`.

## Update MOCs

In each project's `~/vault/<project>/_moc.md`, under the `## Coupled with` heading, add a line `- [[../<peer>/_moc]]` if not already present. Keep the list alphabetized.

## Output

```
Linked <project-a> ↔ <project-b> in group "<group-name>".
Updated:
  ~/vault/_global/coupled-groups.md
  ~/vault/<project-a>/_moc.md
  ~/vault/<project-b>/_moc.md
```

Then suggest running `/resume <project-a>` (or `<project-b>`) once to validate the cross-pull works.
