---
type: index
project: vault
tags: [index, indications]
---

# vault — Indications (working rules, patterns, standards)

| Slug | Rule | Applies-to |
|------|------|------------|
| [[shared-vs-stack-persona-factoring]] | Generic critics live once in `_shared/`; stack packs compose via `use_shared` + overlays | `personas/**` |
| [[critique-loop-stop-conditions]] | Loops stop on round cap or no-new-confirmed-blockers, never on approval alone | `commands/v-team/steps/**` |
| [[confirmed-vs-advisory-findings]] | A finding blocks only when tool-confirmed; unbacked = advisory | `personas/**`, `commands/v-team/steps/**` |
| [[packs-detect-not-assume]] | Packs detect the project's stack/state approach; never hardcode a library | `personas/<stack>.md` |
| [[installer-dry-run-seam]] | Installer side-effects go through a dry-run-able `run()` seam; offline tests assert the transcript, e2e proves the real install | `setup.sh`, `lib/installers.sh`, `tests/**` |
| [[per-user-installer-no-sudo]] | Installer runs as the user, escalates internally for apt only; refuse `sudo` invocation (`$SUDO_USER` set), accept interactive sudo | `setup.sh`, `lib/installers.sh`, `bin/*.sh` |
