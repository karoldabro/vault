---
type: indication
project: vault
slug: tools-suggestions-not-rules
scope: repo
tags: [indication, tooling]
---

# tools-suggestions-not-rules

## Rule
Tool guidance in the framework is **suggestion, not gate** — Claude auto-selects the tool that fits; the
cost hierarchy is a sensible default, not a hard rule. The exception is genuine **safety** notes (e.g.
Morph's `// ... existing code ...` markers), which stay firm.

## Rationale
Hard "always/never" tool-selection rules misfire on the cases they didn't anticipate and add friction;
the model picks well when given defaults + context. Soft framing works better in practice (user
feedback, 2026-06-22). Safety rules are different — they prevent data loss, so they remain mandatory.

## Examples
- Do: "if the repo declares a tracker, that MCP is usually the best first source; otherwise fall back
  naturally." / "Prefer the graph over grepping source for structural questions."
- Don't: "NEVER grep source to answer a structural question." (selection rule stated as a mandate)
- Keep firm: "always include `// ... existing code ...` markers" (safety, not selection).

## Applies-to
`tool-playbook.md`, `commands/**` (tool-selection guidance), `VAULT.md` `tools` section.
